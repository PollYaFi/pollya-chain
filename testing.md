# Testing

Once you setup the chain using instructions in [README.md](./README.md), following the instructions in [cw-poll testing document](https://gitlab.com/pollya-blockchain/cw-poll/-/blob/main/testing.md) to do the test. Copying the commands here for reference.

## Download and compile cosmwasm contract

### Download cw-poll

```
  git clone git@gitlab.com:pollya-blockchain/cw-poll.git
  cd cw-poll
```

### Compile to wasm and Deploy

```
    docker run --rm -v "$(pwd)":/code  --mount type=volume,source="devcontract_cache_cw-poll",target=/code/contracts/cw-poll/target   --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry   cosmwasm/rust-optimizer:0.12.13 ./
```

```
   export CHAIN_ID=<put your chain id>        # you can find this by querying http://localhost:26657/status
   export CHAIN_HOME="./.testnets/node0/pollyad"
   export ACCOUNT=node0
```

**store wasm:**

```
   ./build/pollyad  tx  wasm store ../cw-poll/target/wasm32-unknown-unknown/release/cw_poll.wasm  --from $ACCOUNT --chain-id $CHAIN_ID --home $CHAIN_HOME  --gas "4000000"
```

 You can browse the transaction details from `http://localhost:26657/tx?hash=0x<your-transaction-hash>`

```
   export STORE_CODE=<store_code_from_the_output> 
```

### Test Setup Poll, Voting and Decryption

**instantiate**

```
  ./build/pollyad tx wasm instantiate $STORE_CODE '{"poll_public_key": "<generate-poll-public-key-from-poll-crypto-service>"}' --from $ACCOUNT --chain-id $CHAIN_ID --home $CHAIN_HOME  --gas "4000000"  --label "test" --no-admin
```

 You can browse the transaction hash from `http://localhost:26657/tx?hash=0x<your-transaction-hash>` and find the contract address

```
   export CONTRACT_ADDRESS=<contract_address_from_the_output_of_above_command>
```

**setup_poll**

A poll with 5 choices, and ability to choose just one choice out of 5

```
 ./build/pollyad tx wasm execute $CONTRACT_ADDRESS '{"setup_poll": {"poll_details": {"topic": "Yes - No - May be", "choices": ["0", "1", "2", "3", "4"], "poll_type": "single_choice", "start_time": 1, "end_time": 2}}}' --from $ACCOUNT --chain-id $CHAIN_ID --home $CHAIN_HOME --gas "4000000"
```

**add_vote**

```
  ./build/pollyad tx wasm execute $CONTRACT_ADDRESS '{"add_vote":{"vote":{"ciphertexts":[["uOlsaptzwigFT52F15Kfct09uO2IHqPlGUy8vSxj0mg","Xv3UHUfouyVRVQbcmJT-wyXYosRjZStDEB2dqgEuRFY"],["JplqqoR7Uyf9mE5ukLXhVYV49ERnn9bPw6hoWopZk1A","fuUT5buugaIg3ivpkNmuB7vIR1gVArvVfJ1g1FwrJXI"],["xk-BRdPU4gHI-EcUtpo66mcWRen9pJ7dLZcYRi_FCRo","0AaWAn-w52TOyhYrLH1XeFvLZPfuKgjC_Wdn_LU1C1E"],["0uBVWCAsqk6F8MWFVAxY45litAOWnCWAG2wTdAFMGik","loOs2tOzwfl_trNXr4C_8y9Cbexdar-z4KtE-ylOezo"],["APYKOKxydm1V0h2eSRiT-1jCSkfgN_lDtfQa7XYCbDs","_BnpRODtkEQTJayX6hu_BYfzGr7lt78m8Sk1vVd_kUY"]],"range_proof":"dfyTb0PjmGDE_LEVAluN-hLvo18scHBAPg9xA78ZkAlnOIbBGfi5vf0V6kV_zh-XLEtGRQ5O4UGRDyzFNXNFCMx4imYBiYGnInq4fyS10MNA9rgNGvNGC_NJLS9MaoAK76g_7vHvJadBnUwIkEDbtg4C40ovWJo6h9VZaEC6IA3Zilj3pQu7dMEWPBfqPrBUYQmqP2UzjSS-mWsUkYGfCPj2Z7tzkRGCd0KgTDYQIvFRZSevcekyDt9eV3OVMVwF_jc7fsh3kM_ehkR_4AGM3Hsc8JxzbhQpXnEhOVh0hAswjWE3GxtubXhsxPRse_T16TF7TmgowOj2N6nbdhxHAM3fOSIDY5ciWPDS6gbsULHPEBHo-C7Xh87Q9VkPiIgBxJG7BlKza3d3T2LcnjZBrDK43SvISDMKXoiP4KaaWQ4P_KvoYHqd08SqeZrnW_rKF6WQTHySzd7rOY-jE9P-CA","sum_proof":"zQC0vE2LbwXnq0CqPCM23N4oBQJCU2cAaFcKsW-Z8Qa8KZabJUbpY32g82QHTk4aGxVyWfBNUtcOMI2VdrwwBg"}}}'  --from $ACCOUNT --chain-id $CHAIN_ID --home $CHAIN_HOME --gas "4000000"
```

**decryption**

```
  ./build/pollyad tx wasm execute $CONTRACT_ADDRESS '{"decrypt_tally": { "decryption": {"verifiable_decryptions":["Xv3UHUfouyVRVQbcmJT-wyXYosRjZStDEB2dqgEuRFY","nDgKcETZyB5BxhsdAX3ehhmSMGe0OTHVPgBHL-VNIGs","0AaWAn-w52TOyhYrLH1XeFvLZPfuKgjC_Wdn_LU1C1E","loOs2tOzwfl_trNXr4C_8y9Cbexdar-z4KtE-ylOezo","_BnpRODtkEQTJayX6hu_BYfzGr7lt78m8Sk1vVd_kUY"],"proofs":["pDRqWukm41CNrSR4NYPYtSMQp6C6k-RDBNdDAzXxDQgjMZxTC_TyF6pvZxhPIIr-9OINU7ilIiaCNlb-BaFNAg","kmHuuxfRj75HQr5tRhKHbjgLb1bG8j9oaZRLVMpA-AOmiOngN-n5-Be01yCN0VjZTn8Lzrg0k-h-xnOLZ2zSBg","cmfR8FfRjHH3QPRyRyR8v8QFlCwcEHjeNtcQpz9-bQjWeWO0BEfuDNWFtweAUCHzbKjnzmea_dYv6UqvP0SEDg","_MFWZ8324yTeqWlhXWTx7-kjbdpUIeGyhNbbH4EfCw3b6e_edQkLtVR4cZb8x-1_S2PmpMy0qfJ47ak3o_YeBg","cK-BfEdjmRn_4GRrhDqB05LK64GjGHy-bsKtWqpLrQTPEw2-zUfvS3cuXvYnFH55ag11Kbpe8b9P4sEngGT0DQ"]}}}' --from $ACCOUNT --chain-id $CHAIN_ID --home $CHAIN_HOME --gas "4000000"
```

**query**

```
  ./build/pollyad query wasm contract-state smart $CONTRACT_ADDRESS '{"get_poll": {}}'
```

## Creating key, generating vote, decryption etc.

**creating an encrypted vote**
The following will create an encrypted single choice vote based on 5 choices, with 1 choice selection - the choice being '0'




```
    cargo run --package poll-lib --example vote 5 1 0 MC6xp3UbtRrh9Chf_9JsjbmzUqjyvPz3EIoq82YMVTo
```

The following will create an encrypted multi choice vote based on 5 choices, with 2 choice selections - the choice being '0' '2'.
```
    cargo run --package poll-lib --example vote 5 1 0 2 MC6xp3UbtRrh9Chf_9JsjbmzUqjyvPz3EIoq82YMVTo
```

In both the cases, the last input is the public key of the poll. For the timebeing same value can be used as the secret key has been hardcoded in the code. We should not do this in production, but just for test this is good.

**decryption**

You need to update the example/decrypt.rs with the ciphertexts in `poll-lib` repo

``` on line 9: 
   let ciphertexts = [["uOlsaptzwigFT52F15Kfct09uO2IHqPlGUy8vSxj0mg","Xv3UHUfouyVRVQbcmJT-wyXYosRjZStDEB2dqgEuRFY"],["JplqqoR7Uyf9mE5ukLXhVYV49ERnn9bPw6hoWopZk1A","fuUT5buugaIg3ivpkNmuB7vIR1gVArvVfJ1g1FwrJXI"],["xk-BRdPU4gHI-EcUtpo66mcWRen9pJ7dLZcYRi_FCRo","0AaWAn-w52TOyhYrLH1XeFvLZPfuKgjC_Wdn_LU1C1E"],["0uBVWCAsqk6F8MWFVAxY45litAOWnCWAG2wTdAFMGik","loOs2tOzwfl_trNXr4C_8y9Cbexdar-z4KtE-ylOezo"],["APYKOKxydm1V0h2eSRiT-1jCSkfgN_lDtfQa7XYCbDs", "_BnpRODtkEQTJayX6hu_BYfzGr7lt78m8Sk1vVd_kUY"]];
```
You should get the cipher text from the blockchain for a given poll using the get_poll query.

And run

```
   cargo run --package poll-lib --example decrypt
```

The output can then be used in the decrypt transaction
