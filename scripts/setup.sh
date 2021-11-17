#!/bin/bash

set -e

function printUsage {
   cat << EOF

Usage: setup.sh [options] <chain_id> <moniker>

Example: setup.sh -adlop carbon-1 tothemoon

Options:
-a  Configures the node to run with the api and ws service enabled.
-d  Sets ups a local postgresql database which is used as the database backend for the persistence service. Omit this if you are using a remote psql database.
-l  Sets up the liquidator subservice (redis, systemd, wallet, request for postgres host & pw).
-o  Sets up the oracle subservice (redis, systemd, wallet, request for postgres host & pw).
-p  Sets up the off-chain persistence service, which persists data required by api, ws, liquidator and oracle service to an off-chain postgresql database. \
Omit this if services are not enabled or data should be read from a remote database which has data written to from another node.
-v  Creates a new validator wallet labelled "val". Only required if setting up a new validator node.
-w  Creates new wallets for the liquidator or oracle service as required.
-h  Displays this usage message.
EOF
}

# Install configuration variables
PUBLIC_NODE=false
LOCAL_DATABASE=false
SETUP_API=false
SETUP_LIQUIDATOR=false
SETUP_ORACLE=false
SETUP_PERSISTENCE=false
CREATE_WALLETS=false
INSTALL_REDIS=false

while getopts ":adlopvwh" opt; do
  case $opt in
    a)
      SETUP_API=true
      ;;
    d)
      LOCAL_DATABASE=true
      ;;
    l)
      SETUP_LIQUIDATOR=true
      ;;
    o)
      SETUP_ORACLE=true
      ;;
    p)
      SETUP_PERSISTENCE=true
      ;;
    v)
      CREATE_WALLETS=true
      ;;
    h)
      printUsage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      printUsage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      printUsage
      exit 1
      ;;
  esac
done

if [[ $(( $# - $OPTIND )) -ne 1 ]]; then
  echo "Wrong number of parameters."
  printUsage
  exit 1
fi

# Chain variables
DAEMON=carbond
CHAIN_ID=${@:$OPTIND:1}
MONIKER=${@:$OPTIND+1:1}
CHAIN_CONFIG_URL=https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/${CHAIN_ID}
VERSION=$(wget -qO- $CHAIN_CONFIG_URL/VERSION)
PERSISTENT_PEERS=$(wget -qO- $CHAIN_CONFIG_URL/PEERS)

# if oracle or liquidator is installed, redis and hot wallet is required.
WALLET_STRING=
if [ "$SETUP_LIQUIDATOR" = true ] || [ "$SETUP_ORACLE" = true ]; then
  INSTALL_REDIS=true
  echo "Enter your keyring passphrase for running the liquidator or oracle service:"
  read -s WALLET_PASSWORD
  WALLET_STRING="Environment=\"WALLET_PASSWORD=$WALLET_PASSWORD\""
fi

# if local database is not installed, check dependencies
if [ "$LOCAL_DATABASE" != true ]; then
  if [ "$SETUP_PERSISTENCE" = true ] && [ -z "$POSTGRES_URL" ]; then
    echo "Error: No psql database configured for the persistence writer service (-p). Either run with -d to configure
    a local postgres instance, or provide a \$POSTGRES_URL connection string to a psql database where write permssions are enabled."
    exit 1
  fi
  if [ ( "$SETUP_API" = true ] || [ "$SETUP_ORACLE" = true ] || [ "$SETUP_LIQUIDATOR" = true ) && [ -z "$POSTGRES_URL" ]; then
    echo "Error: No psql database configured for reading off-chain data (required by -a, -o or -l). Either run with -d -p
    to configure a local postgres instance and persistence service, or provide a \$POSTGRES_URL connection string to the psql database
    where a node running the persistence service is writing this data."
    exit 1
  fi
  if [ "$SETUP_API" = true ] && [ -z "$WS_GRPC_URL" ]; then
    echo "Error: No persistence service configured for streaming off-chain data. Either run with -d -p
    to configure a local postgres instance and persistence service, or provide a \$WS_GRPC_URL address
    (e.g. WS_GRPC_URL=127.0.01:9091) of a node running the persistence service."
    exit 1
  fi
fi

echo "-- Carbon Setup --"

# TODO: install deps if data required
# node-only: no flags
# node-with-data: -ap
# node-with-validator-services -lop (-d if local psql db) (-w if new validator)
# node-with-data-and-validator-services -alop (-d if local psql db) (-w if new validator)
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/scripts/install-deps.sh)

echo "-- Downloading carbond"

wget https://github.com/Switcheo/carbon-testnets/releases/download/v${VERSION}/carbon${VERSION}.tar.gz
tar -zxvf carbon${VERSION}.tar.gz
sudo mv cosmovisor /usr/local/bin
rm carbon${VERSION}.tar.gz

echo "---- Downloading genesis file"

./$DAEMON init $MONIKER
wget -O ~/.carbon/config/genesis.json ${CHAIN_CONFIG_URL}/genesis.json

echo "-- Stopping any previous system service of carbond"

sudo systemctl stop carbond || true
sudo systemctl stop carbond@oracle || true
sudo systemctl stop carbond@liquidator || true

echo "-- Clearing carbon directory"

rm -rf ~/.carbon
sudo rm -f /usr/local/bin/carbond
sudo rm -f /usr/local/bin/cosmovisor
sudo rm -rf /var/log/journal/carbon*

echo "---- Setting node configuration"

sed -i 's#timeout_commit = "5s"#timeout_commit = "1s"#g' ~/.carbon/config/config.toml
sed -i 's#cors_allowed_origins = \[\]#cors_allowed_origins = \["*"\]#g' ~/.carbon/config/config.toml
sed -i 's#laddr = "tcp:\/\/127.0.0.1:26657"#laddr = "tcp:\/\/0.0.0.0:26657"#g' ~/.carbon/config/config.toml
sed -i 's#addr_book_strict = true#addr_book_strict = false#g' ~/.carbon/config/config.toml
sed -i 's#db_backend = "goleveldb"#db_backend = "cleveldb"#g' ~/.carbon/config/config.toml
sed -i '/persistent_peers =/c\persistent_peers = "'"$PERSISTENT_PEERS"'"' ~/.carbon/config/config.toml
sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml

echo "---- Creating node directories"

mkdir -p ~/.carbon/cosmovisor/genesis/bin
mv $DAEMON ~/.carbon/cosmovisor/genesis/bin
sudo ln -s ~/.carbon/cosmovisor/current/bin/$DAEMON /usr/local/bin/$DAEMON

# configure database strings
PERSISTENCE_FLAG=
DB_NAME=carbon
if [ "$LOCAL_DATABASE" = true ]; then
  POSTGRES_URL=postgresql://postgres@localhost:5432/carbon
  MAINTENANCE_DB_URL=postgresql://postgres@localhost:5432/postgres
else
  [[ $POSTGRES_URL =~ '[a-z0-9]/(.+)$' ]]
  DB_NAME=${BASH_REMATCH[1]}
  [[ $POSTGRES_URL =~ '(.+)/(.+)$' ]]
  MAINTENANCE_DB_URL=${BASH_REMATCH[1]}$DB_NAME
fi

if [ "$SETUP_PERSISTENCE" = true ]; then
  echo "---- Initializing database"

  echo "Creating db \"$DB_NAME\" using $MAINTENANCE_DB_URL"

  dropdb --maintenance-db=$MAINTENANCE_DB_URL --if-exists $DB_NAME
  mkdir ~/.carbon/migrations
  createdb --maintenance-db=$MAINTENANCE_DB_URL $DB_NAME

  POSTGRES_URL=$POSTGRES_URL ./$DAEMON migrations
  POSTGRES_URL=$POSTGRES_URL ./$DAEMON persist-genesis
  PERSISTENCE_FLAG=--persistence
fi

echo "---- Creating carbon systemd service"

WANTS=
if [ "$SETUP_ORACLE" = true ]; then
  WANTS=$WANTScarbond@oracle.service\n
fi
if [ "$SETUP_LIQUIDATOR" = true ]; then
  WANTS=$WANTScarbond@liquidator.service\n
fi
if [ "$SETUP_API" = true ]; then
  WANTS=$WANTScarbond@ws-api.service\n
fi
if [ "$SETUP_PERSISTENCE" = true ]; then
  WANTS=$WANTScarbond@ext-events.service\n
fi

# TODO: add for relayer nodes
# Wants=carbond@fee.service

sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
$WANTS
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=$DAEMON"
Environment="PATH=$HOME/.carbon/cosmovisor/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="POSTGRES_URL=$POSTGRES_URL"
ExecStart=/usr/local/bin/cosmovisor start $PERSISTENCE_FLAG
Storage=persistent
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

echo "---- Creating carbon systemd subservices"

sudo tee /etc/systemd/system/carbond@.service > /dev/null <<EOF
[Unit]
Description=Carbon %i Daemon
BindsTo=carbond.service
After=carbond.service
After=network-online.target

[Service]
User=$USER
$WALLET_STRING
Environment="POSTGRES_URL=$POSTGRES_URL"
ExecStart=$HOME/.carbon/cosmovisor/current/bin/carbond %i
Storage=persistent
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
