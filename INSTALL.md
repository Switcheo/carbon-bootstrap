# Manual Installation

This guide will explain how to do a manual install the `carbond` node onto your system. With theis installed on a server, you can participate in the mainnet as either a Full Node, Sentry Node, or Validator.

## Install build requirements

Install `cmake`.

On Ubuntu this can be done with the following:

```bash
sudo apt-get update

sudo apt-get install -y build-essential cmake -y
```

## Install Go

```bash
wget https://dl.google.com/go/go1.17.linux-amd64.tar.gz
tar -xvf go1.17.linux-amd64.tar.gz
sudo mv go /usr/local

echo "" >>~/.bashrc
echo 'export GOPATH=$HOME/go' >>~/.bashrc
echo 'export GOROOT=/usr/local/go' >>~/.bashrc
echo 'export GOBIN=$GOPATH/bin' >>~/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin:$GOBIN' >>~/.bashrc

source ~/.bashrc

rm go1.17.linux-amd64.tar.gz
```

## Install cleveldb

```bash
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
```

## Install Carbon

Download and unzip binaries:

```bash
wget https://github.com/Switcheo/carbon-testnets/releases/download/v0.0.1/carbon0.0.1.tar.gz
tar -zxvf carbon0.0.1.tar.gz
sudo mv carbond cosmovisor /usr/local/bin
rm carbon0.0.1.tar.gz
```

That will install the `carbond` binary.

Verify that everything is OK:

```bash
carbond version --long
# name: carbon
# server_name: <appd>
# version: 0.0.1-521-g758a7b2
# commit: 758a7b27f3e9ec156209eb50f60e6a087c210a02
# build_tags: ""
# go: go version go1.17 linux/amd64
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

Next, download the genesis file and set up your node configuration.

```bash
# Download genesis file
wget -O ~/.carbon/config/genesis.json https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/<chain-id>/genesis.json

## Or alternatively, export from your pre-stargate (e.g. switcheo chain) node:
switcheoctl stop
switcheod node export > genesis.json

# Configure node
sed -i 's#timeout_commit = "5s"#timeout_commit = "1s"#g' ~/.carbon/config/config.toml
sed -i 's#cors_allowed_origins = \[\]#cors_allowed_origins = \["*"\]#g' ~/.carbon/config/config.toml
sed -i 's#laddr = "tcp:\/\/127.0.0.1:26657"#laddr = "tcp:\/\/0.0.0.0:26657"#g' ~/.carbon/config/config.toml
sed -i 's#addr_book_strict = true#addr_book_strict = false#g' ~/.carbon/config/config.toml
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml
```

If migrating from a pre-stargate chain (e.g. from `switcheo-chain` to `carbon-0`), you'll need to run the Stargate migrate command:

```bash
carbond migrate genesis.json --chain-id <chain-id> > carbon-genesis.json
mv carbon-genesis.json ~/.carbon/config/genesis.json
# check hash:
openssl sha256 ~/.carbon/config/genesis.json
# <hash> => TODO
```

### Add seed nodes

Your node needs to know how to find peers. You'll need to add healthy seed nodes to `$HOME/.carbon/config/config.toml`.

```bash
PERSISTENT_PEERS="d5c57895d85e59593cc992c09cdc9a1555457c22@54.254.184.152:26656" # example carbon-0 testnet initial peer

sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml
```

### Configure Cosmovisor

To be best prepared for eventual upgrades, it is recommended to setup Cosmovisor, a small process manager, which can swap the upgraded node binaries automatically whenever a software upgrade governance proposal is enacted.

Create the initial folder move the `carbond` binary into it:

```bash
mkdir -p ~/.carbon/cosmovisor/genesis/bin
mv /usr/local/bin/carbond ~/cosmovisor/genesis/bin
sudo ln -s ~/.carbon/cosmovisor/current/bin/carbond /usr/local/bin/carbond
```

## Install Redis

Redis is used for the Websocket API subservice.

```bash
sudo apt-get install redis-server -y
```

## Install Postgres

Postgresql is used by all subservices to store and fetch indexed off-chain data.

```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get install postgresql-13 -y
sudo sed -i -e '/^local   all             postgres                                peer$/d' \
    -e 's/ peer/ trust/g' \
    -e 's/ md5/ trust/g' \
    /etc/postgresql/13/main/pg_hba.conf
sudo service postgresql restart
```

### Initialize genesis data

```bash
mkdir ~/.carbon/migrations
createdb -U postgres carbon
# run table migrations
POSTGRES_DB=carbon POSTGRES_USER=postgres ./carbond migrations
# import genesis data
POSTGRES_DB=carbon POSTGRES_USER=postgres ./carbond persist-genesis
```

## Background supervision with `systemd`

You can setup systemd to supervise the Carbon node and subservices.

### Recommended config for Carbon node

```bash
sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=carbond"
Environment="PATH=$HOME/.carbon/cosmovisor/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/usr/local/bin/cosmovisor start --persistence
Storage=persistent
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```

> Remove `--persistence` from `ExecStart=` if this node is will not run subservices (e.g. validator with subservices running on subaccount in another node, non-public sentry node, etc).

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
Environment="ORACLE_WALLET_LABEL=oraclewallet"
Environment="WALLET_PASSWORD=$WALLET_PASSWORD"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond %i
Storage=persistent
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
Environment="POSTGRES_HOST=<your_remote_host_and_port>"
Environment="POSTGRES_USER=<your_postgres_user>"
Environment="POSTGRES_PASSWORD=<your_postgres_password>"
```

If you're using a remote Redis node you'll need to add the following environment variables to both systemd configurations:

```toml
Environment="REDIS_HOST=<your_remote_host_and_port>"
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
sudo systemctl start carbond
# Oracle: required to be ran by validators
sudo systemctl start carbond@oracle
# External Chain Events Monitor: required to be on the validator's oracle node / full nodes
sudo systemctl start carbond@ext-events.service
# Websocket API: required to be ran by full nodes
sudo systemctl start carbond@ws-api.service
# Liquidator: required to be ran by validators in future
sudo systemctl start carbond@liquidator.service
# Fee: only required for relayer (admin) nodes
sudo systemctl start carbond@fee.service
```
