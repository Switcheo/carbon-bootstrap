#!/bin/bash

set -e

if [ ! -f "/usr/lib/libleveldb.so.1" ]; then
  echo "Install dependencies"
  sudo apt update
  sudo apt install build-essential jq cmake redis-server -y

  wget https://github.com/google/leveldb/archive/1.23.tar.gz
  tar -zxvf 1.23.tar.gz

  wget https://github.com/google/googletest/archive/release-1.11.0.tar.gz
  tar -zxvf release-1.11.0.tar.gz
  mv googletest-release-1.11.0/* leveldb-1.23/third_party/googletest

  wget https://github.com/google/benchmark/archive/v1.5.5.tar.gz
  tar -zxvf v1.5.5.tar.gz
  mv benchmark-1.5.5/* leveldb-1.23/third_party/benchmark

  cd leveldb-1.23
  mkdir -p build

  cd build
  cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ..
  cmake --build .
  sudo cp libleveldb.so.1 /usr/local/lib/
  sudo ldconfig
  cd ..

  sudo cp -r include/leveldb /usr/local/include/
  cd ..

  rm -rf benchmark-1.5.5/
  rm -f v1.5.5.tar.gz

  rm -rf googletest-release-1.11.0/
  rm -f release-1.11.0.tar.gz

  rm -rf leveldb-1.23/
  rm -f 1.23.tar.gz
fi

echo "-- Stopping any previous system service of carbond"

sudo systemctl stop carbond

carbond unsafe-reset-all

echo "-- Clear old carbon data and install carbond and setup the node --"

rm -rf /usr/local/bin/carbond
rm -rf ~/.carbon

YOUR_KEY_NAME=val
YOUR_NAME=$1
DAEMON=carbond
DENOM=swth
PERSISTENT_PEERS="155412c02ca5bc152ac63e56b9004924bfd5e8e0@13.229.61.80:26656"

echo "Installing carbond"
# TODO

echo "Creating keys"
$DAEMON keys add $YOUR_KEY_NAME --keyring-backend file -i

echo "Setting up your validator"
$DAEMON init $YOUR_NAME
curl http://13.229.61.80:26657/genesis | jq .result.genesis >~/.carbon/config/genesis.json

echo "----------Setting config for seed node---------"
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml

echo "---------Creating system file---------"

echo "[Unit]
Description=Carbond daemon
After=network-online.target
[Service]
User=${USER}
ExecStart=/usr/local/bin/$DAEMON start
StandardOutput=append:/var/log/carbon/start.log
StandardError=append:/var/log/carbon/start.err
Restart=always
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
" >carbond.service

sudo mkdir /var/log/carbon
sudo mv carbond.service /etc/systemd/system/carbond.service
sudo systemctl daemon-reload
sudo systemctl start carbond

echo
echo "Your account address is :"
$DAEMON keys show $YOUR_KEY_NAME -a --keyring-backend file
echo "Your node setup is done. You would need some tokens to start your validator. You can get some tokens from the faucet: https://test-faucet.carbon.network"
echo
echo
echo "After receiving tokens, you can create your validator by running"
echo "$DAEMON tx staking create-validator --amount 100000000000$DENOM --commission-max-change-rate \"0.1\" --commission-max-rate \"0.20\" --commission-rate \"0.1\" --details \"Some details about your validator\" --from $YOUR_KEY_NAME --pubkey=\"$($DAEMON tendermint show-validator)\" --moniker $YOUR_NAME --min-self-delegation \"1\" --fees 100000000$DENOM --keyring-backend file"
