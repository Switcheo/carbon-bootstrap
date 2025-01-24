#!/bin/bash

set -e

DAEMON=carbond
DENOM=swth

echo "-- Creating keys"

echo "Enter your keyring passphrase or choose a new one:"
read -s WALLET_PASSWORD

printf "$WALLET_PASSWORD\n$WALLET_PASSWORD\n" | $DAEMON keys add val --keyring-backend file

echo "========================================================"
echo "Your validator key is created. You would need some tokens to start your validator. For testnet, you can get them from the faucet at https://test-faucet.carbon.network"
echo "Your account address is: $(printf "$WALLET_PASSWORD\n" | $DAEMON keys show val -a --keyring-backend file)"
echo
echo "After receiving tokens, you can create your validator by running:"
echo "$DAEMON tx staking create-validator --amount 100000000000$DENOM --commission-max-change-rate \"0.1\" --commission-max-rate \"0.20\" --commission-rate \"0.1\" --details \"Some details about your validator\" --from $YOUR_KEY_NAME --pubkey=\"$($DAEMON tendermint show-validator)\" --moniker $YOUR_NAME --min-self-delegation \"1\" --fees 10000000$DENOM --gas 300000 --keyring-backend file"
echo "========================================================"
echo
echo

printf "$WALLET_PASSWORD\n$WALLET_PASSWORD\n" | $DAEMON keys add oracle --keyring-backend file

echo "========================================================"
echo "Your oracle key is created."
echo "Your oracle address is: $(printf "$WALLET_PASSWORD\n" | $DAEMON keys show oracle -a --keyring-backend file)"
echo
echo "You can link your oracle account to your validator by running:"
echo "$DAEMON tx subaccount create-sub-account $(printf "$WALLET_PASSWORD\n" | $DAEMON keys show oracle -a --keyring-backend file) --from val --fees 10000000$DENOM --gas 300000 --keyring-backend file -y"
echo "$DAEMON tx subaccount activate-sub-account $(printf "$WALLET_PASSWORD\n" | $DAEMON keys show val -a --keyring-backend file) --from oracle --fees 10000000$DENOM --gas 300000 --keyring-backend file -y"
echo "========================================================"
echo
echo

printf "$WALLET_PASSWORD\n$WALLET_PASSWORD\n" | $DAEMON keys add liquidator --keyring-backend file

echo "========================================================"
echo "Your liquidator key is created."
echo "Your liquidator address is: $(printf "$WALLET_PASSWORD\n" | $DAEMON keys show liquidator -a --keyring-backend file)"
echo "========================================================"
echo
echo