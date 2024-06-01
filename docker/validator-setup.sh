export GOBIN=~/go/bin
export PATH=$PATH:$GOBIN

#Initializes a pollya chain
pollyad init pollya --chain-id pollya-1

# Creates a validator key
pollyad keys add validator

# Initialize genesis accounts
pollyad genesis add-genesis-account poll1w27qr6wl5vngujzu8t3y079qt4f5ffqyaw3zvn 100000000000000points

# Adding staking token for validator
pollyad genesis add-genesis-account $(pollyad keys show validator -a) 100000000000stake

# Creating gentx
pollyad genesis gentx validator 1000000stake --chain-id pollya-1 --moniker validator --commission-rate 0.05   --commission-max-rate 0.1   --commission-max-change-rate 0.01

# Collect all gentx
pollyad genesis collect-gentxs

# Starting the blockchain with validator
pollyad start




