#!/bin/sh

CHAIN_HOME=${CHAIN_HOME:-/root/.pollyad}
if test -n "$1"; then
    # need -R not -r to copy hidden files
    cp -R "$1/.pollyad" /root
fi

mkdir -p /root/log
pollyad start --rpc.laddr tcp://0.0.0.0:26657 --home $CHAIN_HOME --trace
