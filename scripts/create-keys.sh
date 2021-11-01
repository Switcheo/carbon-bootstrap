#!/bin/bash

set -e

DAEMON=carbond
DENOM=swth

echo "Creating keys"

$DAEMON keys add val --keyring-backend file -i

echo
echo "Your account address is:"
$DAEMON keys show val -a --keyring-backend file
echo "Your node setup is done. You would need some tokens to start your validator. You can get some tokens from the faucet: https://test-faucet.carbon.network"
echo
echo
echo "After receiving tokens, you can create your validator by running"
echo "$DAEMON tx staking create-validator --amount 100000000000$DENOM --commission-max-change-rate \"0.1\" --commission-max-rate \"0.20\" --commission-rate \"0.1\" --details \"Some details about your validator\" --from $YOUR_KEY_NAME --pubkey=\"$($DAEMON tendermint show-validator)\" --moniker $YOUR_NAME --min-self-delegation \"1\" --fees 100000000$DENOM --keyring-backend file"

$DAEMON keys add oracle --keyring-backend file -i

echo
echo "Your oracle address is:"
$DAEMON keys show oracle -a --keyring-backend file
echo "Your oracle setup is done. You would need some tokens to start your oracle. You can get some tokens from the faucet: https://test-faucet.carbon.network"
echo
echo
echo "After receiving tokens, you can link your oracle account to your validator by running"
echo "$DAEMON tx subaccount create-sub-account $($DAEMON keys show oracle -a --keyring-backend file) --from val --fees 100000000$DENOM --keyring-backend file -y"
echo "$DAEMON tx subaccount activate-sub-account $($DAEMON keys show val -a --keyring-backend file) --from oracle --fees 100000000$DENOM --keyring-backend file -y"

$DAEMON keys add liquidator --keyring-backend file -i

echo
echo "Your liquidator address is:"
$DAEMON keys show liquidator -a --keyring-backend file
echo "Your liquidator setup is done. You would need some tokens to start your liquidator. You can get some tokens from the faucet: https://test-faucet.carbon.network"
echo
echo
echo "After receiving tokens, you can link your liquidator account to your validator by running"
echo "$DAEMON tx subaccount create-sub-account $($DAEMON keys show liquidator -a --keyring-backend file) --from val --fees 100000000$DENOM --keyring-backend file -y"
echo "$DAEMON tx subaccount activate-sub-account $($DAEMON keys show val -a --keyring-backend file) --from liquidator --fees 100000000$DENOM --keyring-backend file -y"
