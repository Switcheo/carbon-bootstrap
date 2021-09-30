#!/bin/bash

set -e

command_exists() {
  type "$1" &>/dev/null
}

if command_exists go; then
  echo "Golang is already installed"
else
  echo "Install dependencies"
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

  sudo apt update
  sudo apt install build-essential jq cmake redis-server postgresql-12 -y

  wget https://dl.google.com/go/go1.17.linux-amd64.tar.gz
  tar -xvf go1.17.linux-amd64.tar.gz
  sudo mv go /usr/local

  echo "" >>~/.bashrc
  echo 'export GOPATH=$HOME/go' >>~/.bashrc
  echo 'export GOROOT=/usr/local/go' >>~/.bashrc
  echo 'export GOBIN=$GOPATH/bin' >>~/.bashrc
  echo 'export PATH=$PATH:/usr/local/go/bin:$GOBIN' >>~/.bashrc

  rm go1.17.linux-amd64.tar.gz

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
  sudo cp -r lib* /usr/local/lib/
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

  sudo sed -i -e '/^local   all             postgres                                peer$/d' \
    -e 's/ peer/ trust/g' \
    -e 's/ md5/ trust/g' \
    /etc/postgresql/12/main/pg_hba.conf
  sudo service postgresql restart

  /usr/local/go/bin/go install github.com/Switcheo/cosmos-sdk/cosmovisor/cmd/cosmovisor@73f5c224725d922f1e4b9fa334be8be6db16fc12
fi

echo "-- Stopping any previous system service of carbond"

sudo systemctl stop carbond || true
sudo systemctl stop carbond-oracle || true
sudo systemctl stop carbond-liquidator || true

echo "-- Clear old carbon data and install carbond and setup the node --"

dropdb -U postgres carbon || true
rm -rf ~/.carbon

YOUR_KEY_NAME=val
YOUR_NAME=$1
DAEMON=carbond
PERSISTENT_PEERS="bd0a0ed977eabef81c60da2aac2dabb64a149173@3.0.180.87:26656"

echo "Installing carbond"
wget https://github.com/Switcheo/carbon-testnets/releases/download/v0.0.1/carbond
chmod a+x $DAEMON

echo "Setting up your validator"
./$DAEMON init $YOUR_NAME
curl http://54.254.184.152:26657/genesis | jq .result.genesis > ~/.carbon/config/genesis.json

echo "----------Setting config for seed node---------"
sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml

mkdir ~/.carbon/migrations
createdb -U postgres carbon
POSTGRES_USER=postgres ./$DAEMON migrations
POSTGRES_USER=postgres ./$DAEMON persist-genesis

mkdir -p ~/.carbon/cosmovisor/genesis/bin
mv $DAEMON ~/.carbon/cosmovisor/genesis/bin

echo "---------Creating system file---------"

echo "[Unit]
Description=Carbon Daemon
After=network-online.target

[Service]
User=$USER
Environment=\"DAEMON_HOME=$HOME/.carbon\"
Environment=\"DAEMON_NAME=$DAEMON\"
Environment=\"PATH=$HOME/.carbon/cosmovisor/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"
Environment=\"POSTGRES_USER=postgres\"
ExecStartPre=-killall -q -w -s 9 carbond
ExecStart=$HOME/go/bin/cosmovisor start --persistence
StandardOutput=append:/var/log/carbon/start.log
StandardError=append:/var/log/carbon/start.err
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
" > carbond.service

sudo mkdir /var/log/carbon
sudo mv carbond.service /etc/systemd/system/carbond.service
sudo systemctl daemon-reload
sudo systemctl start carbond

echo "Setting up your oracle"

echo "---------Creating system file---------"

echo Enter keyring passphrase:
read -s WALLET_PASSWORD

echo "[Unit]
Description=Carbon Oracle Daemon
After=network-online.target

[Service]
User=$USER
Environment=\"ORACLE_WALLET_LABEL=oraclewallet\"
Environment=\"WALLET_PASSWORD=$WALLET_PASSWORD\"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond oracle
StandardOutput=append:/var/log/carbon/oracle.log
StandardError=append:/var/log/carbon/oracle.err
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
" > carbond-oracle.service

sudo mv carbond-oracle.service /etc/systemd/system/carbond-oracle.service
sudo systemctl daemon-reload
sudo systemctl start carbond-oracle

echo "Setting up your liquidator"

echo "---------Creating system file---------"

echo Enter keyring passphrase:
read -s WALLET_PASSWORD

echo "[Unit]
Description=Carbon Liquidator Daemon
After=network-online.target

[Service]
User=$USER
Environment=\"WALLET_PASSWORD=$WALLET_PASSWORD\"
Environment=\"POSTGRES_USER=postgres\"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond liquidator
StandardOutput=append:/var/log/carbon/liquidator.log
StandardError=append:/var/log/carbon/liquidator.err
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
" > carbond-liquidator.service

sudo mv carbond-liquidator.service /etc/systemd/system/carbond-liquidator.service
sudo systemctl daemon-reload
sudo systemctl start carbond-liquidator
