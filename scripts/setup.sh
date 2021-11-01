#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
  echo "Wrong number of parameters. Usage: setup.sh <chain_id> <moniker>"
  exit 1
fi

CHAIN_ID=$1
MONIKER=$2
DAEMON=carbond
CHAIN_CONFIG_URL=https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/${CHAIN_ID}
VERSION=$(wget -qO- $CHAIN_CONFIG_URL/VERSION)
PERSISTENT_PEERS=$(wget -qO- $CHAIN_CONFIG_URL/PEERS)

echo "-- Carbon Setup --"

# TODO: install deps if data required
# node-only
# node-with-data
# node-with-validator-services
# node-with-data-and-validator-services
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/scripts/install-deps.sh)

echo "-- Stopping any previous system service of carbond"

sudo systemctl stop carbond || true
sudo systemctl stop carbond-oracle || true
sudo systemctl stop carbond-liquidator || true

echo "-- Clearing carbon directory"

dropdb -U postgres --if-exists carbon
rm -rf ~/.carbon
sudo rm -f /usr/local/bin/carbond
sudo rm -f /usr/local/bin/cosmovisor
sudo rm -rf /var/log/journal/carbon*

echo "-- Downloading carbond"

wget https://github.com/Switcheo/carbon-testnets/releases/download/v${VERSION}/carbon${VERSION}.tar.gz
tar -zxvf carbon${VERSION}.tar.gz
sudo mv cosmovisor /usr/local/bin
rm carbon${VERSION}.tar.gz

echo "---- Downloading genesis file"

./$DAEMON init $MONIKER
wget -O ~/.carbon/config/genesis.json ${CHAIN_CONFIG_URL}/genesis.json

echo "---- Setting node configuration"

sed -i 's#timeout_commit = "5s"#timeout_commit = "1s"#g' ~/.carbon/config/config.toml
sed -i 's#cors_allowed_origins = \[\]#cors_allowed_origins = \["*"\]#g' ~/.carbon/config/config.toml
sed -i 's#laddr = "tcp:\/\/127.0.0.1:26657"#laddr = "tcp:\/\/0.0.0.0:26657"#g' ~/.carbon/config/config.toml
sed -i 's#addr_book_strict = true#addr_book_strict = false#g' ~/.carbon/config/config.toml
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml
sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml

echo "---- Creating node directories"

mkdir ~/.carbon/migrations
createdb -U postgres carbon
POSTGRES_DB=carbon POSTGRES_USER=postgres ./$DAEMON migrations
POSTGRES_DB=carbon POSTGRES_USER=postgres ./$DAEMON persist-genesis

mkdir -p ~/.carbon/cosmovisor/genesis/bin
mv $DAEMON ~/.carbon/cosmovisor/genesis/bin
sudo ln -s ~/.carbon/cosmovisor/current/bin/$DAEMON /usr/local/bin/$DAEMON

echo "---- Creating carbon systemd service"

sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
Wants=carbond@oracle.service
Wants=carbond@liquidator.service
Wants=carbond@ws-api.service
Wants=carbond@fee.service
Wants=carbond@ext-events.service
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=$DAEMON"
Environment="PATH=$HOME/.carbon/cosmovisor/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="POSTGRES_USER=postgres"
ExecStart=/usr/local/bin/cosmovisor start --persistence
Storage=persistent
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

echo "---- Creating carbon systemd subservices"

echo "Enter your keyring passphrase:"
read -s WALLET_PASSWORD

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
Environment="POSTGRES_USER=postgres"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond %i
Storage=persistent
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable carbond

# TODO: only run required
