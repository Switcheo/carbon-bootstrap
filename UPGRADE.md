# Upgrading from Switcheo Chain 

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

### Enable cleveldb
```bash
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
```

### Setting up your Validator
Copy the following two files from switcheo chain to carbon.
```bash
cp ~/.switcheod/config/node_key.json ~/.carbon/config
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config
```

### Setting up your Subaccounts
```bash
carbond keys add oracle --keyring-backend file -i
carbond keys add liquidator --keyring-backend file -i
```

Your full node has been initialized!

## Genesis & Seeds

### Copy the Genesis File
Export switcheo chain's `genesis.json`
```bash
switcheod node export > genesis.json
```
and migrate into carbon's `genesis.json`
```bash
carbond migrate genesis.json --chain-id $(jq -r ".chain_id" genesis.json) > carbon-genesis.json
mv carbon-genesis.json ~/.carbon/config/genesis.json
```

### Add Seed Nodes
Your node needs to know how to find peers. You'll need to add healthy seed nodes to `$HOME/.carbon/config/config.toml`.

```bash
sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml
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
Install the `cosmovisor` binary:
```bash
go install github.com/Switcheo/cosmos-sdk/cosmovisor/cmd/cosmovisor@73f5c224725d922f1e4b9fa334be8be6db16fc12
```
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
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=carbond"
Environment="PATH=$HOME/.carbon/cosmovisor/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStartPre=-killall -q -w -s 9 carbond
ExecStart=$(which cosmovisor) start --persistence
StandardOutput=append:/var/log/carbon/start.log
StandardError=append:/var/log/carbon/start.err
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
```
Then setup the daemon
```bash
sudo -S systemctl daemon-reload
sudo -S systemctl enable carbond
```
We can then start the process and confirm that it is running
```bash
sudo -S systemctl start carbond

sudo service carbond status
```

### Oracle Service
```bash
sudo tee /etc/systemd/system/carbond-oracle.service > /dev/null <<EOF  
[Unit]
Description=Carbon Oracle Daemon
After=network-online.target

[Service]
User=$USER
Environment="WALLET_PASSWORD=<your_wallet_password>"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond oracle
StandardOutput=append:/var/log/carbon/oracle.log
StandardError=append:/var/log/carbon/oracle.err
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable carbond-oracle
sudo -S systemctl start carbond-oracle
sudo service carbond-oracle status
```
If you're using a remote Redis you want to add
```bash
Environment="REDIS_HOST=<your_remote_host>"
```

### Liquidator Service
```bash
sudo tee /etc/systemd/system/carbond-liquidator.service > /dev/null <<EOF  
[Unit]
Description=Carbon Liquidator Daemon
After=network-online.target

[Service]
User=$USER
Environment="WALLET_PASSWORD=<your_wallet_password>"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond liquidator
StandardOutput=append:/var/log/carbon/liquidator.log
StandardError=append:/var/log/carbon/liquidator.err
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable carbond-liquidator
sudo -S systemctl start carbond-liquidator
sudo service carbond-liquidator status
```
If you're using a remote Postgres you want to add
```bash
Environment="POSTGRES_HOST=<your_remote_host>"
Environment="POSTGRES_USER=<your_postgres_user>"
Environment="POSTGRES_PASSWORD=<your_postgres_password>"
```