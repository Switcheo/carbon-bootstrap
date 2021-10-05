# Upgrading from Switcheo Chain
It is recommended to use a new machine to host Carbon, although the same machine that hosted Switcheo Chain can be used to host Carbon as well.
Once migrated to Carbon, the data from Switcheo Chain is no longer needed.

This guide is tested on Ubuntu20 and Ubuntu18. It is better to use Ubuntu20 as the systemd from Ubuntu18 does not support append mode and would need a work around.

## Quickstart

### Instant Gratification Snippet
```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/scripts/upgrade.sh) <your_moniker>
```
Copy previous keys from Switcheo Chain. If Carbon resides on a different machine, use `scp` and update the command accordingly.
```bash
cp ~/.switcheod/config/node_key.json ~/.carbon/config/
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config/
cp -r ~/.switcheocli/keyring-switcheo-tradehub ~/.carbon/keyring-file
```
Now start Carbon. This command will start the carbon node itself, together with the oracle and liquidator services.
```bash
sudo systemctl start carbond
```
And to stop:
```bash
sudo systemctl stop carbond
```
Stopping Carbon will stop the other services as well. To stop any of the individual services:
```shell
sudo systemctl stop carbond-oracle
sudo systemctl stop carbond-liquidator
```
Now inspect the logs and make sure everything is working fine.
```shell
tail -f /var/log/carbon/start.*
tail -f /var/log/carbon/oracle.*
tail -f /var/log/carbon/liquidator.*
```

## Prerequisites
You will need
- Carbon
- Cleveldb
- Cosmovisor
- Redis
- Postgres

For help on installation, please see INSTALL.md

## Setting up a new Carbon Node
These instructions are for setting up a brand new full node from scratch.

First, initialize the node and create the necessary config files:
```bash
carbond init <your_custom_moniker>
```
Note Monikers can contain only ASCII characters. Using Unicode characters will render your node unreachable.

You can edit this moniker later, in the ~/.carbon/config/config.toml file:
```bash
# A custom human readable name for this node
moniker = "<your_custom_moniker>"
```

### Overwrite the Default Config
```bash
sed -i 's#timeout_commit = "5s"#timeout_commit = "1s"#g' ~/.carbon/config/config.toml
sed -i 's#cors_allowed_origins = \[\]#cors_allowed_origins = \["*"\]#g' ~/.carbon/config/config.toml
sed -i 's#laddr = "tcp:\/\/127.0.0.1:26657"#laddr = "tcp:\/\/0.0.0.0:26657"#g' ~/.carbon/config/config.toml
sed -i 's#addr_book_strict = true#addr_book_strict = false#g' ~/.carbon/config/config.toml
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml
sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml
```

### Setting up your keys
Copy previous keys from Switcheo Chain. If Carbon resides on a different machine, use `scp` and update the command accordingly.
```bash
cp ~/.switcheod/config/node_key.json ~/.carbon/config/
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config/
cp -r ~/.switcheocli/keyring-switcheo-tradehub ~/.carbon/keyring-file
```

### Setting up the database
```bash
createdb -U postgres carbon
POSTGRES_DB=carbon POSTGRES_USER=postgres carbond migrations
```

Your full node has been initialized!

## Genesis & Seeds

### Copy the Genesis File
Download the genesis file from:
```bash
wget -O ~/.carbon/config/genesis.json https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/carbon-0/genesis.json
```

Or alternatively, export switcheo chain's `genesis.json`
```bash
switcheoctl stop
switcheod node export > genesis.json
```
and migrate into carbon's `genesis.json`
```bash
carbond migrate genesis.json --chain-id carbon-0 > carbon-genesis.json
mv carbon-genesis.json ~/.carbon/config/genesis.json
```
Make sure the SHA matches with the rest.
```bash
openssl sha256 ~/.carbon/config/genesis.json

```

### Persist the Genesis File
```bash
POSTGRES_DB=carbon POSTGRES_USER=postgres carbond persist-genesis
```

### Add Seed Nodes
Your node needs to know how to find peers. You'll need to add healthy seed nodes to `$HOME/.carbon/config/config.toml`.

```bash
sed -i '/persistent_peers =/c\persistent_peers = "'"bd0a0ed977eabef81c60da2aac2dabb64a149173@3.0.180.87:26656"'"' ~/.carbon/config/config.toml
```

### Run a Full Carbon Node
Start the full node with this command:
```bash
carbond start --persistence --oracle --liquidator
```
If you're using a remote Redis and/or Postgres you want to add
```bash
REDIS_HOST=<your_remote_redis_host>
POSTGRES_HOST=<your_remote_postgres_host>
POSTGRES_USER=<your_postgres_user>
POSTGRES_PASSWORD=<your_postgres_password>
```

## Upgrades
To be best prepared for eventual upgrades, it is recommended to setup Cosmovisor, a small process manager, which can swap in new `carbond` binaries.

### Cosmovisor Setup
Create the folder for the genesis binary and copy the binary:
```bash
mkdir -p ~/.carbon/cosmovisor/genesis/bin
cp $(which carbond) ~/cosmovisor/genesis/bin
```

## Background Process
To run the node in a background process with automatic restarts, you can use a service manager like `systemd`. To set this up run the following:
```bash
sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
Wants=carbond-oracle.service
Wants=carbond-liquidator.service
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=$DAEMON"
Environment="PATH=$HOME/.carbon/cosmovisor/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="POSTGRES_USER=postgres"
ExecStart=/usr/local/bin/cosmovisor start --persistence
StandardOutput=append:/var/log/carbon/start.log
StandardError=append:/var/log/carbon/start.err
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```

#### Oracle Service
```bash
sudo tee /etc/systemd/system/carbond-oracle.service > /dev/null <<EOF
[Unit]
Description=Carbon Oracle Daemon
BindsTo=carbond.service
After=carbond.service
After=network-online.target

[Service]
User=$USER
Environment="ORACLE_WALLET_LABEL=oraclewallet"
Environment="WALLET_PASSWORD=$WALLET_PASSWORD"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond oracle
StandardOutput=append:/var/log/carbon/oracle.log
StandardError=append:/var/log/carbon/oracle.err
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```
If you're using a remote Redis you want to add
```bash
Environment="REDIS_HOST=<your_remote_host>"
```

#### Liquidator Service
```bash
sudo tee /etc/systemd/system/carbond-liquidator.service > /dev/null <<EOF
[Unit]
Description=Carbon Liquidator Daemon
BindsTo=carbond.service
After=carbond.service
After=network-online.target

[Service]
User=$USER
Environment="WALLET_PASSWORD=$WALLET_PASSWORD"
Environment="POSTGRES_USER=postgres"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond liquidator
StandardOutput=append:/var/log/carbon/liquidator.log
StandardError=append:/var/log/carbon/liquidator.err
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF
```
If you're using a remote Postgres you want to add
```bash
Environment="POSTGRES_HOST=<your_remote_host>"
Environment="POSTGRES_USER=<your_postgres_user>"
Environment="POSTGRES_PASSWORD=<your_postgres_password>"
```

### Setting up the daemon
Then setup the daemon
```bash
sudo systemctl daemon-reload
sudo systemctl enable carbond
```
We can then start the process and confirm that it is running
```bash
sudo systemctl start carbond

sudo service carbond status
```
And to stop:
```bash
sudo systemctl stop carbond
```
Stopping Carbon will stop the other services as well. To stop any of the individual services:
```shell
sudo systemctl stop carbond-oracle
sudo systemctl stop carbond-liquidator
```
Now inspect the logs and make sure everything is working fine.
```shell
tail -f /var/log/carbon/start.*
tail -f /var/log/carbon/oracle.*
tail -f /var/log/carbon/liquidator.*
```