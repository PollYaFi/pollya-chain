# Setting up the chain

## Testnet

### Build the chain
```
   git clone git@gitlab.com:pollya-blockchain/pollya-chain.git
   cd pollya-chain
   make build
```

### Run the chain

#### Initialize testnet files
```
   ./build/pollyad testnet init-files --v 1 --output-dir ./.testnets  --node-daemon-home pollyad
```

```
   docker build . -t pollya-chain:latest
```

```
   docker run -it -e CHAIN_HOME=/opt/chain/pollyad -v <path-to-local-testnet-config>:/opt/chain -p 3000:3000 -p 1317:1317 -p 26656:26656 -p 26657:26657 --detach pollya-chain:latest
```

## Production

Same mechanism as above


