#!/bin/sh
#set -o errexit -o nounset -o pipefail

PASSWORD=${PASSWORD:-1234567890}
STAKE=${STAKE_TOKEN:-ustake}
FEE=${FEE_TOKEN:-ucosm}
CHAIN_ID=${CHAIN_ID:-testing}
MONIKER=${MONIKER:-node001}

pollyad init --chain-id "$CHAIN_ID" "$MONIKER"
# staking/governance token is hardcoded in config, change this
sed -i "s/\"stake\"/\"$STAKE\"/" "$HOME"/.pollyad/config/genesis.json
sed -i "s/\"stake\"/\"$STAKE\"/" "$HOME"/.pollyad/config/app.toml
# this is essential for sub-1s block times (or header times go crazy)
sed -i 's/"time_iota_ms": "1000"/"time_iota_ms": "10"/' "$HOME"/.pollyad/config/genesis.json

if ! pollyad keys show validator; then
  (echo "$PASSWORD"; echo "$PASSWORD") | pollyad keys add validator
fi
# hardcode the validator account for this instance
echo "$PASSWORD" | pollyad genesis add-genesis-account $(pollyad keys show validator  --address) "1000000000$STAKE,1000000000$FEE"

# (optionally) add a few more genesis accounts
for addr in "$@"; do
  echo $addr
  pollyad genesis add-genesis-account "$addr" "1000000000$STAKE,1000000000$FEE"
done

# submit a genesis validator tx
## Workraround for https://github.com/cosmos/cosmos-sdk/issues/8251
(echo "$PASSWORD"; echo "$PASSWORD"; echo "$PASSWORD") | pollyad genesis gentx validator "250000000$STAKE" --chain-id="$CHAIN_ID" --amount="250000000$STAKE"
## should be:
# (echo "$PASSWORD"; echo "$PASSWORD"; echo "$PASSWORD") | wasmd gentx validator "250000000$STAKE" --chain-id="$CHAIN_ID"
pollyad genesis collect-gentxs

./toml set ~/.pollyad/config/app.toml api.enable true bool > /tmp/app1.tmp.toml
./toml set /tmp/app1.tmp.toml api.swagger true bool > /tmp/app2.tmp.toml
./toml set /tmp/app2.tmp.toml api.address tcp://0.0.0.0:1317 string > /tmp/app3.tmp.toml
cp /tmp/app3.tmp.toml ~/.pollyad/config/app.toml
./toml set ~/.pollyad/config/config.toml rpc.max_body_bytes 10000000 number > /tmp/config1.tmp.toml
./toml set /tmp/config1.tmp.toml mempool.max_tx_bytes 5000000 number > /tmp/config2.tmp.toml
cp /tmp/config2.tmp.toml ~/.pollyad/config/config.toml

cat ~/.pollyad/config/config.toml

if [ -n "$OUTPUT_DIR" ]; then
   cp -R "$HOME"/.pollyad "$OUTPUT_DIR"/.pollyad
   cat "$OUTPUT_DIR"/.pollyad/config/genesis.json
fi
