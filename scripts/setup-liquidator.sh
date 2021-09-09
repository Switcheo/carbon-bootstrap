#!/bin/bash

set -e

DAEMON=carbond
DENOM=swth

echo "Creating keys"
$DAEMON keys add liquidator --keyring-backend file -i

echo "Setting up your liquidator"

echo "---------Creating system file---------"

echo Enter keyring passphrase:
read -s WALLET_PASSWORD

echo "[Unit]
Description=Carbond liquidator daemon
After=network-online.target
[Service]
User=${USER}
Environment=WALLET_PASSWORD=$WALLET_PASSWORD
ExecStart=/usr/local/bin/$DAEMON liquidator
StandardOutput=append:/var/log/carbon/liquidator.log
StandardError=append:/var/log/carbon/liquidator.err
Restart=always
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
" >carbond-liquidator.service

sudo mv carbond-liquidator.service /etc/systemd/system/carbond-liquidator.service
sudo systemctl daemon-reload
sudo systemctl start carbond-liquidator

echo
echo "Your liquidator address is :"
$DAEMON keys show liquidator -a --keyring-backend file
echo "Your liquidator setup is done. You would need some tokens to start your liquidator. You can get some tokens from the faucet: https://test-faucet.carbon.network"
echo
echo
echo "After receiving tokens, you can create your oracle by running"
echo "$DAEMON tx subaccount create-sub-account $($DAEMON keys show liquidator -a --keyring-backend file) --from val --fees 100000000$DENOM --keyring-backend file -y"
echo "$DAEMON tx subaccount activate-sub-account $($DAEMON keys show val -a --keyring-backend file) --from liquidator --fees 100000000$DENOM --keyring-backend file -y"
