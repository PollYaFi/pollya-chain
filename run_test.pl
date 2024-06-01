#!/usr/bin/perl
use JSON;

# This is the admin account which will store contracts / mint nft etc.
my $admin_account = "node0";
# The following attribute is not needed, but just storing here for reference
my $admin_account_secret = "aFE3YNZzRwBjHbio4vTU6cWnKmTRtzaRhCK7nUnOx3k";

# This value should be a base64 url encoded value, not standard base64 value
my $admin_pub_key = "AlAmu61FF8pV1qweR78rc8UdWG8f9zNUqaWuYQ5mbbpi";

# Address of the admin account 
my $admin_account_address = "poll1a4mp7kedzuquntnqtfd2yjulk9t53c66mqgyx6";
my $chain_id = "chain-3Q1pP7";

my $rest_api = "http://localhost:1317";

# Home directory of the chain
my $chain_home = ".testnets/node0/pollyad";

# poll-crypto-service URL, the service should have been setup properly
my $crypto_service = "http://localhost:8080";

# .wasm binary for various contracts we use
my $poll_contract_wasm  = "../cw-poll/target/wasm32-unknown-unknown/release/cw_poll.wasm";
my $nft_contract_wasm = "../cw-nfts/artifacts/cw721_non_transferable-aarch64.wasm";

# The following is not needed anymore
#my $discrete_log_contract_wasm = "../cw-discrete-log-lookup/target/wasm32-unknown-unknown/release/cw_discrete_log_lookup.wasm";

# Binary of the blockchain
my $wasmd_binary = "./build/pollyad";

# The poll lib code, which will be used to generate votes
my $poll_lib = "../poll-lib";

# List of voters, the values are the names of the accounts. These accounts should be added beforehand using `pollyad keys add <name>`
my $voters = ['node0', 'validator', 'testuser'];

# Leave the value below to 2 if you want to test key rotation
my $test_key_rotation = 0; # Set it to 2 if you want to test key rotation
my $new_admin_account_secret = "dwE8qWyXiPBwg85u8GmTR76vt_wPsV6XswT3wC-QkBk",
my $new_admin_public_key = "AygpQAAy32x-kYIzVZ-lKwJkouL31UuqkN-VW5aV811q";
my $new_admin_account_address = "poll13j098q6wnly4judpvdcza2ue6udxyxktqz5y3s";
my $new_admin_account = "validator";

# This can be left empty
my $voter_details = [];

# Max choices in the poll
my $max_choices = 5;


sub init_accounts {
    my $nft_contract = shift;
    my $token_id = 1;
    my $admin_acc = undef;
    for my $voter(@$voters) {
        print("\nInitializing $voter account\n");
        my $address = `$wasmd_binary keys show $voter --address`;
        chomp $address;
        my $voter_detail = {
            address => $address,
            name => $voter,
            vote => int(rand($max_choices)),
            token_id => "tkn-".$token_id
        };
        push @$voter_details, $voter_detail;
        `curl -X POST -H 'Content-Type: application/json' -d '{"wallet": "$address"}' http://localhost:8080/chain/account/new -s`;
        print ("Minting NFT for $voter - $address\n");
        `curl -X POST -H 'Content-Type: application/json' -d '{"wallet": "$address", "extra_data": "{\\\"did\\\": \\\"d-i-d\\\"}", "token_id": "$voter_detail->{token_id}", "nft_contract": "$nft_contract"}' http://localhost:8080/nft/mint -s`;
        $token_id = $token_id + 1;
        if ($voter eq $admin_account) {
            $admin_acc = $voter_detail;
        }
    }
    return $admin_acc;
}

sub parse_result {
    my $result = shift;
    chomp $result;
    my $tx = decode_json($result);
    my $tx_hash = $tx->{txhash};
    sleep(10);
    my $tx_result = `curl http://localhost:1317/cosmos/tx/v1beta1/txs/$tx_hash -s`;
    chomp $tx_result;
    my $tx_json = decode_json($tx_result);
    return ($tx_hash, $tx_json->{tx_response}{events});
}

sub get_store_code {
    my $events = shift;
    for my $event(@$events) {
        if ($event->{type} eq 'store_code') {
            for my $attr (@{$event->{attributes}}) {
                if ($attr->{key} eq 'code_id') {
                    return $attr->{value};
                }
            }
        }
    }
}

sub get_contract_address {
    my $events = shift;
    for my $event(@$events) {
        if ($event->{type} eq 'instantiate') {
            for my $attr (@{$event->{attributes}}) {
                if ($attr->{key} eq '_contract_address') {
                    return $attr->{value};
                }
            }
        }
    }
}

sub wait_for_key() {
    print "\nPress any key to continue...";
    chomp($key = <STDIN>);
}

sub submit_votes {
    my ($poll_pub_key, $poll_contract, $poll_id, $nft_contract_address, $aggregated_votes) = @_;
    for my $voter_detail(@$voter_details) {
        print("Adding vote for $voter_detail->{address} $voter_detail->{name}, choice: $voter_detail->{vote}\n");
            # Add vote
        my $result = `cd $poll_lib && cargo run -q --package poll-lib --example vote 5 1 $voter_detail->{vote} $poll_pub_key`;
        chomp $result;
        my @lines = split (/\n/, $result);
        my $ciphertexts = $lines[-1];

        $result = `curl -X POST -H "Content-Type: application/json" -d '{"poll_id": "$poll_id", "nft_contract": "$nft_contract_address", "voter": "$voter_detail->{address}", "poll_contract": "$poll_contract", "token_id": "$voter_detail->{token_id}", "points": 10}' http://localhost:8080/poll/vote/auth -s`;
        chomp $result;
        my $vote_auth_response = decode_json($result);

        print("Voting..\n");
        if ($test_key_rotation >= 1) {
            # During this time, run external commands to change 1) Keys in poll-crypto-service, 2) Call the contract function to change public key in nft contract
            if ($test_key_rotation == 2) {
                print("KEY ROTATION IS ON.\nRun external commands to change keys in poll-crypto-service, once done press any key to continue..\n");
                wait_for_key();
                my $extension = encode_json({
                    extension => {
                        msg => {
                            message_type => "change_admin",
                            value => encode_json({
                                new_admin_public_key => $new_admin_public_key,
                                action => {
                                    transfer_ownership => {
                                        new_owner => $new_admin_account_address
                                    }
                                }
                            })
                        }
                    }
                });
                print($extension."\n");
                # Call the nft contract to change the key
                $result = `$wasmd_binary tx wasm execute $nft_contract_address '$extension' --from $admin_account --home $chain_home  --gas "4000000" --chain-id $chain_id -y --output json`;
                print($result);
                ($hash, $events) = parse_result($result);
                print("Temporarily until the next iteration, both old admin and new admin accounts should work - $hash\n");
                $test_key_rotation = $test_key_rotation - 1;
            } else {
                # Call the NFT contract to finalize key rotation
                print("Finalizing key rotation\n");
                my $extension = encode_json({
                    extension => {
                        msg => {
                            message_type => "finalize_change_admin",
                            value => encode_json({
                                action => "accept_ownership"
                            })
                        }
                    }
                });
                print($extension."\n");
                $result = `$wasmd_binary tx wasm execute $nft_contract_address '$extension' --from $new_admin_account --home $chain_home  --gas "4000000" --chain-id $chain_id -y --output json`;
                ($hash, $events) = parse_result($result);
                print("Changed key in NFT contract - $hash");
                ($admin_account, $admin_account_address, $admin_pub_key) = ($new_admin_account, $new_admin_account_address, $new_admin_public_key);
                $test_key_rotation = 0;
            }
        }
        $result = `$wasmd_binary tx wasm execute $poll_contract '{"add_vote": {"vote": $ciphertexts, "add_points_msg": {"nft_contract": "$nft_contract_address", "token_id": "$voter_detail->{token_id}", "points": "10",  "signed_by": "$vote_auth_response->{signature}{public_key}", "signature": "$vote_auth_response->{signature}{signature}"}}}' --from $voter_detail->{name}  --home $chain_home  --gas "4000000" --chain-id $chain_id -y --output json`;
        ($hash, $events) = parse_result($result);
        print ("Voted - $hash\n");
        my $data = decode_json($ciphertexts);
        #print Dumper($data);
        push @$aggregated_votes, $data->{ciphertexts};
    }
}

# Upload contracts
print("Uploading contracts..\n");

print("Storing poll contract..\n");
## cw-poll
my $result = `echo "y" | $wasmd_binary tx wasm store $poll_contract_wasm  --from $admin_account --chain-id $chain_id --home $chain_home --gas "100000000" -y --log_format json --output json`;
my ($hash, $events) = parse_result($result);
my $poll_contract_code = get_store_code($events);

#print("Storing and initializing discrete log contract..\n");
## discrete log contract
#$result = `echo "y" | $wasmd_binary tx wasm store $discrete_log_contract_wasm  --from $admin_account --chain-id $chain_id --home $chain_home --gas "100000000" -y --log_format json --output json`;
#($hash, $events) = parse_result($result);
#my $discretelog_contract_code = get_store_code($events);

## Instantiate discrete log contract
#$result =  `$wasmd_binary tx wasm instantiate $discretelog_contract_code '{}' --from $admin_account --chain-id $chain_id --home $chain_home --gas "100000000" --label test --no-admin -y --output json`;
#($hash, $events) = parse_result($result);
#my $discretelog_contract_address = get_contract_address($events);

## nft contract
print("Storing & initializing nft contract..\n");
$result = `echo "y" | $wasmd_binary tx wasm store $nft_contract_wasm  --from $admin_account --chain-id $chain_id --home $chain_home --gas "100000000" -y --log_format json --output json`;
($hash, $events) = parse_result($result);
my $nft_contract_code = get_store_code($events);

$result = `$wasmd_binary tx wasm instantiate $nft_contract_code '{"name": "PollyaNFT", "symbol": "PNFT", "minter": "$admin_account_address", "admin": "$admin_account_address", "admin_pub_key": "$admin_pub_key"}' --from $admin_account  --home $chain_home  --gas "4000000"  --label "test" --no-admin --chain-id $chain_id -y --output json`;
($hash, $events) = parse_result($result);
my $nft_contract_address = get_contract_address($events);

print("NFT contract: $nft_contract_code - $nft_contract_address\n");

my $admin_acc = init_accounts($nft_contract_address);

# Instantiate Poll

print("Initializing Poll\n");
$poll_id = time;
my $instantiate_poll_response = `curl -X POST -H "Content-Type: application/json" -d '{"poll_id": "$poll_id", "store_code": $poll_contract_code, "nft_contract": "$nft_contract_address", "token_id": "$admin_acc->{token_id}", "points": 25, "setup_user_wallet": "$admin_acc->{address}"}' http://localhost:8080/poll/instantiate -s`;
chomp $instantiate_poll_response;
print($instantiate_poll_response."\n");
$instantiate_poll_response = decode_json($instantiate_poll_response);
my ($poll_contract, $instantiate_signature) = ($instantiate_poll_response->{poll_contract}, $instantiate_poll_response->{signature}{signature});
my $signed_by = $instantiate_poll_response->{signature}{public_key};

print("Setting up poll\n");
my $start_time = time - 10000000;
my $end_time = time + 120; # + 2 minutes
# Setup Poll
$result = `$wasmd_binary tx wasm execute $poll_contract '{"setup_poll": {"poll_details": {"topic": "Yes - No - May be", "choices": ["0", "1", "2", "3", "4"], "poll_type": "single_choice", "start_time": $start_time, "end_time": $end_time}, "add_points_msg": {"nft_contract": "$nft_contract_address", "token_id": "$admin_acc->{token_id}", "points": "25", "signed_by": "$signed_by", "signature": "$instantiate_signature"}}}'  --from $admin_account  --home $chain_home  --gas "4000000" --chain-id $chain_id -y --output json`;
($hash, $events) = parse_result($result);
print ("Setup Poll - $hash - $poll_contract - $instantiate_poll_response->{poll_public_key}");

my $aggregated_votes = [];
submit_votes($instantiate_poll_response->{poll_public_key}, $poll_contract, $poll_id, $nft_contract_address, $aggregated_votes);
#print Dumper($aggregated_votes);

$result = `$wasmd_binary query wasm contract-state smart $poll_contract '{"get_poll": {}}'`;
print("Poll Details after vote: \n$result\n");

for my $voter_detail (@$voter_details) {
    $result = `$wasmd_binary query wasm contract-state smart $nft_contract_address '{"pollya_nft_info": {"token_id": "$voter_detail->{token_id}"}}'`;
    print("NFT Details for $voter_detail->{name} after vote: \n$result\n");
}

my $wait_period = $end_time - time;
if ($wait_period <= 0) {
    # Do nothing
} else {
    print ("Waiting for $wait_period seconds..\n");
    # Waiting until it can be decrypted
    sleep ($wait_period);
}

# Decrypt vote
my $result = `curl -X POST -H 'Content-Type: application/json' -d '{"poll_contract": "$poll_contract", "poll_id": "$poll_id", "submit": true}' http://localhost:8080/poll/decrypt -s`;
print ("Decrypted result: \n$result\n");

$result = `$wasmd_binary query wasm contract-state smart $poll_contract '{"get_poll": {}}'`;
print("Poll Details after decryption: \n$result\n");

$result = `$wasmd_binary query wasm contract-state smart $poll_contract '{"get_poll": {}}' --output json`;
chomp $result;
print("Poll Details (json): $result\n");

my $aggregated_votes_json = encode_json($aggregated_votes);
print ("Aggregated ciphertexts: $aggregated_votes_json, poll_contract: $poll_contract, poll_id: $poll_id\n");

# If you want to aggregate and post aggregated votes
my $result = `curl -X POST -H 'Content-Type: application/json' -d '{"poll_contract": "$poll_contract", "submit": true, "poll_id": "$poll_id", "ciphertexts": $aggregated_votes_json}' http://localhost:8080/poll/create-batch -s`;
print ("Post aggregated vote: \n$result");

my $result = `curl -X POST -H 'Content-Type: application/json' -d '{"poll_contract": "$poll_contract", "poll_id": "$poll_id", "submit": true}' http://localhost:8080/poll/decrypt -s`;
print ("Decrypted result after posting batch: \n$result\n");