# Manual Installation

This guide will explain how to do a manual install the `carbond` node onto your system. With theis installed on a server, you can participate in the mainnet as either a Full Node, Sentry Node, or Validator.

## Install build requirements

On Ubuntu this can be done with the following:

```bash
sudo apt-get update

sudo apt-get install build-essential jq cmake -y
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
sudo apt-get install libleveldb1d -y
```

## Install Carbon

Download and unzip binaries:

```bash
wget https://github.com/Switcheo/carbon-testnets/releases/download/v0.0.3/carbon0.0.3.linux-amd64.tar.gz
tar -zxvf carbon0.0.3.linux-amd64.tar.gz
sudo mv carbond /usr/local/bin
rm carbon0.0.3.linux-amd64.tar.gz
```

That will install the `carbond` binary.

Verify that everything is OK:

```bash
carbond version --long
# name: carbon
# server_name: <appd>
# version: 0.0.1-614-g224c4e5
# commit: 224c4e529065968e541bc262681e57c89e4442fa
# build_tags: ""
# go: go version go1.17.2 linux/arm64
# build_deps:
# - ...
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
https://github.com/Switcheo/carbon-testnets/releases/download/cosmovisor%2Fv1.0.0/cosmovisor1.0.0.linux-$(dpkg --print-architecture).tar.gz
mkdir -p ~/.carbon/cosmovisor/genesis/bin
mv /usr/local/bin/carbond ~/.carbon/cosmovisor/genesis/bin
sudo mv cosmovisor /usr/local/bin
sudo ln -s ~/.carbon/cosmovisor/genesis ~/.carbon/cosmovisor/current
sudo ln -s ~/.carbon/cosmovisor/current/bin/carbond /usr/local/bin/carbond
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
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-13 -y
sudo sed -i.orig '/local\(\s*\)all\(\s*\)postgres/ s|\(\s*\)peer|         127.0.0.1\/32         trust|; /local\(\s*\)all\(\s*\)postgres/ s|local|host|' \
  /etc/postgresql/13/main/pg_hba.conf
sudo service postgresql restart
```

### Initialize genesis data

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
sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=carbond"
ExecStart=/usr/local/bin/cosmovisor start --persistence --ws-api
StandardOutput=append:/var/log/carbon/carbond.out.log
StandardError=append:/var/log/carbon/carbond.err.log
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```

> Remove `--ws-api` from `ExecStart=` if this node is not public.
> Remove `--persistence` from `ExecStart=` if this node is will not run subservices (e.g. validator with subservices running on subaccount in another node, non-public sentry node, etc).

### Recommended config for subservices

This dynamically creates a systemd configuration for each type of subservice.

```bash
sudo mkdir -p /var/log/carbon
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
Environment="POSTGRES_HOST=<your_remote_host_and_port>"
Environment="POSTGRES_USER=<your_postgres_user>"
Environment="POSTGRES_PASSWORD=<your_postgres_password>"
```

If you're using a remote Redis node you'll need to add the following environment variables to both systemd configurations:

```toml
Environment="REDIS_HOST=<your_remote_host_and_port>"
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
