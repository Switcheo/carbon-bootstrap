# Manual Installation

This guide will explain how to do a manual install the `carbond` node onto your system. With this installed on a server, you can participate in the mainnet as either a Full Node, Sentry Node, or Validator.

## Install build requirements

This includes the compression libraries for rocksdb.
On Ubuntu this can be done with the following:

```bash
sudo apt-get update

sudo apt-get install build-essential jq cmake perl -y
```

## Install cleveldb

Download and install leveldb v1.23:

```bash
wget https://github.com/google/leveldb/archive/1.23.tar.gz && \
  tar -zxvf 1.23.tar.gz && \
  wget https://github.com/google/googletest/archive/release-1.11.0.tar.gz && \
  tar -zxvf release-1.11.0.tar.gz && \
  mv googletest-release-1.11.0/* leveldb-1.23/third_party/googletest && \

  wget https://github.com/google/benchmark/archive/v1.5.5.tar.gz && \
  tar -zxvf v1.5.5.tar.gz && \
  mv benchmark-1.5.5/* leveldb-1.23/third_party/benchmark && \

  cd leveldb-1.23 && \
  mkdir -p build && \

  cd build && \
  cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .. && \
  cmake --build . && \
  sudo cp -P libleveldb.so* /usr/local/lib/ && \
  sudo ldconfig && \
  cd .. && \

  sudo cp -r include/leveldb /usr/local/include/ && \
  cd .. && \

  rm -rf benchmark-1.5.5/ && \
  rm -f v1.5.5.tar.gz && \

  rm -rf googletest-release-1.11.0/ && \
  rm -f release-1.11.0.tar.gz && \

  rm -rf leveldb-1.23/ && \
  rm -f 1.23.tar.gz
```

## Install Carbon

Download and unzip binaries:

```bash
VERSION=$(curl -s https://api.github.com/repos/Switcheo/carbon-bootstrap/releases/latest | jq -r .tag_name)
NETWORK=mainnet
ARCH=$(dpkg --print-architecture)
wget https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/carbond${VERSION}-${NETWORK}.linux-${ARCH}.tar.gz
tar -xvf carbond${VERSION}-${NETWORK}.linux-${ARCH}.tar.gz
sudo mv carbond /usr/local/bin
rm carbon${VERSION}.linux-${ARCH}.tar.gz
```

That will install the `carbond` binary.

Verify that everything is OK:

```bash
carbond version --long
# name: carbon
# server_name: <appd>
# version: 2.0.2 # check this
# commit: 53968d1a2faf2c42acc775baf77a90ce24c22efe # check this
# build_tags: ""
# go: go version go1.17.3 linux/arm64
# build_deps:
# - ...
# ...
# cosmos_sdk_version: v0.44.4
```

## Configure Carbon

First, initialize the node with your node's moniker. Note Monikers can contain only ASCII characters. Using Unicode characters will render your node unreachable.

```bash
# Init with your node moniker
carbond init <moniker>
```

You can edit this moniker later, in the ~/.carbon/config/config.toml file:

```toml
# A custom human readable name for this node
moniker = "<your_custom_moniker>"
```

Next, set up your node configuration:

```bash
# Configure node
sed -i 's#timeout_commit = "5s"#timeout_commit = "1s"#g' ~/.carbon/config/config.toml
sed -i 's#cors_allowed_origins = \[\]#cors_allowed_origins = \["*"\]#g' ~/.carbon/config/config.toml
sed -i 's#laddr = "tcp:\/\/127.0.0.1:26657"#laddr = "tcp:\/\/0.0.0.0:26657"#g' ~/.carbon/config/config.toml
sed -i 's#addr_book_strict = true#addr_book_strict = false#g' ~/.carbon/config/config.toml
sed -i 's#db_backend = ".*"#db_backend = "goleveldb"#g' ~/.carbon/config/config.toml
sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml
sed -i 's#log_level = "info"#log_level = "warn"#g' ~/.carbon/config/config.toml
# prune every 10 blocks, keeping 100 blocks and every 10,000th block
sed -i 's#pruning = "default"#pruning = "custom"#g' ~/.carbon/config/app.toml
sed -i 's#pruning-keep-recent = "0"#pruning-keep-recent = "100"#g' ~/.carbon/config/app.toml
sed -i 's#pruning-keep-every = "0"#pruning-keep-every = "10000"#g' ~/.carbon/config/app.toml
sed -i 's#pruning-interval = "0"#pruning-interval = "10"#g' ~/.carbon/config/app.toml
sed -i 's#snapshot-interval = 0#snapshot-interval = 10000#g' ~/.carbon/config/app.toml
```

### Add seed nodes

Your node needs to know how to find peers. You'll need to add healthy seed nodes to `$HOME/.carbon/config/config.toml`.

```bash
PEERS="d93ed6a1f43dd0904dc5e2ab8680d4049b057b17@13.215.17.91:26656,70581c625fc1933bc273ca7a8d5e9ded3d1bcc97@13.213.113.113:26656,e3f02a9f3ca22724b3a67bba9183113645c9c7d9@54.179.11.177:26656" # example carbon-1 mainnet initial peers

sed -i '/seeds =/c\seeds = "'"$PEERS"'"' ~/.carbon/config/config.toml
```

### Configure Oracle SSL cert

If you are running a validator, you will need to generate SSL certificates that will be used for authentication by the oracle GRPC service:

```bash
VALIDATOR_NODE_IP_ADDRESS="127.0.0.1"
ORACLE_SERVICE_NODE_IP_ADDRESS="127.0.0.1"
CARBON_HOME_PATH="~/.carbon"
URL=https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/cert.sh
bash <(wget -O - $URL) $VALIDATOR_NODE_IP_ADDRESS $ORACLE_SERVICE_NODE_IP_ADDRESS $CARBON_HOME_PATH
```

### Configure Cosmovisor

To be best prepared for eventual upgrades, it is recommended to setup Cosmovisor, a small process manager, which can swap the upgraded node binaries automatically whenever a software upgrade governance proposal is enacted.

Create the required folder and move the `carbond` binary into it:

```bash
ARCH=$(dpkg --print-architecture)
MINOR=$(perl -pe 's/(?<=\d\.\d{1,2}\.)\d{1,2}/0/g' <<< $VERSION)
wget https://github.com/Switcheo/carbon-bootstrap/releases/download/cosmovisor%2Fv1.0.0/cosmovisor1.0.0.linux-${ARCH}.tar.gz
tar -xvf cosmovisor1.0.0.linux-${ARCH}.tar.gz
sudo mv cosmovisor /usr/local/bin

mkdir -p ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin
mv carbond ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin/carbond
rm -f ~/.carbon/cosmovisor/current
ln -s ~/.carbon/cosmovisor/upgrades/v${MINOR} ~/.carbon/cosmovisor/current
```

## Install Redis

Redis is used by the oracle, liquidator and ws-api subservice.

```bash
sudo apt-get install redis-server -y
```

## Install Postgres

Postgresql is used by all subservices to store and fetch indexed off-chain data.

```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
sudo apt-get update
sudo apt-get install postgresql-17 -y
sudo sed -i.orig '/local\(\s*\)all\(\s*\)postgres/ s|\(\s*\)peer|         127.0.0.1\/32         trust|; /local\(\s*\)all\(\s*\)postgres/ s|local|host|' \
  /etc/postgresql/17/main/pg_hba.conf
sudo service postgresql restart
```

### Initialize genesis data

Download the genesis file for the chain you are setting up:

```bash
wget -O ~/.carbon/config/genesis.json https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/<chain-id>/genesis.json
```

Alternatively, if migrating from a pre-stargate chain (e.g. from `switcheo-tradehub-1` to `carbon-1`), export from your pre-stargate node and run the Stargate migrate command:

```bash
switcheoctl stop
switcheod node export > genesis.json
carbond migrate genesis.json --chain-id <chain-id> > carbon-genesis.json
mv carbon-genesis.json ~/.carbon/config/genesis.json
# check hash:
openssl sha256 ~/.carbon/config/genesis.json
# <hash> => TODO
```

If running an off-chain data node, setup the database with initial tables and genesis data:

```bash
mkdir ~/.carbon/migrations
createdb -U postgres carbon
# run table migrations
POSTGRES_DB=carbon POSTGRES_USER=postgres carbond migrations
# import genesis data
POSTGRES_DB=carbon POSTGRES_USER=postgres carbond persist-genesis
```

## Background supervision with `systemd`

You can setup systemd to supervise the Carbon node and subservices.

### Recommended config for Carbon node

```bash
sudo mkdir -p /var/log/carbon
sudo chown -R $USER /var/log/carbon
sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=carbond"
ExecStart=/usr/local/bin/cosmovisor start --persistence
StandardOutput=append:/var/log/carbon/carbond.out.log
StandardError=append:/var/log/carbon/carbond.err.log
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```

> Remove `--persistence` from `ExecStart=` if this node is will not write offchain-data to postgres (e.g. validator with subservices on another node, non-public sentry node, etc).

### Recommended config for subservices

This dynamically creates a systemd configuration for each type of subservice.

```bash
sudo tee /etc/systemd/system/carbond@.service > /dev/null <<EOF
[Unit]
Description=Carbon %i Daemon
BindsTo=carbond.service
After=carbond.service
After=network-online.target

[Service]
User=$USER
Environment="WALLET_PASSWORD=$WALLET_PASSWORD"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond %i
StandardOutput=append:/var/log/carbon/carbond@%i.out.log
StandardError=append:/var/log/carbon/carbond@%i.err.log
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```

### Remote database node configuration

If you're using a remote Postgres node you'll need to add the following environment variables to both systemd configurations:

```toml
Environment="POSTGRES_URL=postgresql://username:password@hostname:5432/carbon"
```

If you're using a remote Redis node you'll need to add the following environment variables to both systemd configurations:

```toml
Environment="REDIS_URL=redis://hostname:6379"
```

### Create logrotate

Log files are stored in `/var/log/carbon/*`. Add a logrotate configuration to ensure we don't run out of space.

```bash
sudo tee /etc/logrotate.d/carbon > /dev/null <<EOF
/var/log/carbon/carbond*.log {
  daily
  rotate 14
  compress
  delaycompress
  copytruncate
  notifempty
  missingok
}
EOF
```

### Running using `systemd`

Reload systemd configuration:

```bash
sudo systemctl daemon-reload
sudo systemctl enable carbond
```

Node and sub-services can be ran as such:

```bash
# Node: required to be ran by all nodes
sudo systemctl start carbond # --persistence (to write offchain-data to postgres)
# Oracle: required to be ran by validators
sudo systemctl start carbond@oracle
# Liquidator: required to be ran by validators in future
sudo systemctl start carbond@liquidator.service
# Websocket API: required to be ran by full nodes
sudo systemctl start carbond@ws-api.service
```
