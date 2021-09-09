#!/bin/bash

set -e

DAEMON=carbond
DENOM=swth

echo "Creating keys"
$DAEMON keys add oracle --keyring-backend file -i

echo "Setting up your oracle"

echo "---------Creating system file---------"

echo Enter keyring passphrase:
read -s WALLET_PASSWORD

echo "[Unit]
Description=Carbond oracle daemon
After=network-online.target
[Service]
User=${USER}
Environment=WALLET_PASSWORD=$WALLET_PASSWORD
ExecStart=/usr/local/bin/$DAEMON oracle
StandardOutput=append:/var/log/carbon/oracle.log
StandardError=append:/var/log/carbon/oracle.err
Restart=always
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
" >carbond-oracle.service

sudo mv carbond-oracle.service /etc/systemd/system/carbond-oracle.service
sudo systemctl daemon-reload
sudo systemctl start carbond-oracle

echo
echo "Your oracle address is :"
$DAEMON keys show oracle -a --keyring-backend file
echo "Your oracle setup is done. You would need some tokens to start your oracle. You can get some tokens from the faucet: https://test-faucet.carbon.network"
echo
echo
echo "After receiving tokens, you can create your oracle by running"
echo "$DAEMON tx subaccount create-sub-account $($DAEMON keys show oracle -a --keyring-backend file) --from val --fees 100000000$DENOM --keyring-backend file -y"
echo "$DAEMON tx subaccount activate-sub-account $($DAEMON keys show val -a --keyring-backend file) --from oracle --fees 100000000$DENOM --keyring-backend file -y"
