#!/bin/bash

set -e

# node-only: no flags
# node-with-data: -ap
# node-with-validator-services -lop (-d if local psql db) (-w if new validator)
# node-with-data-and-validator-services -alop (-d if local psql db) (-w if new validator)
function printUsage {
   cat << EOF

Usage: setup.sh [options] <chain_id> <moniker>

Example: setup.sh -adlop carbon-1 tothemoon

Options:
-a  Configures the node to run with the api and websocket service enabled (and installs redis as a dependency).
-d  Installs a local postgresql database which is used as the database backend for the persistence service. Omit this if you are using a remote psql database.
Setting this flag automatically sets the -p flag as well.
-l  Installs the liquidator subservice (with redis as a dependency).
-o  Installs the oracle subservice  (with redis as a dependency).
-p  Installs the off-chain persistence service, which persists data required by api, websocket, liquidator and oracle service to an off-chain postgresql database. \
Omit this if services are not enabled or data should be read from a remote database which has data written to from another node.
-r  Sets up the relayer fee subservice. Only required by operators of cross-chain relayers.
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
SETUP_RELAYER=false
INSTALL_REDIS=false

while getopts ":adloprsth" opt; do
  case $opt in
    a)
      SETUP_API=true
      ;;
    d)
      LOCAL_DATABASE=true
      SETUP_PERSISTENCE=true
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
    r)
      SETUP_RELAYER=true
      ;;
    t)
      STATE_SYNC=true
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

# if liquidator is installed, wallet password is required.
WALLET_STRING=
if [ "$SETUP_LIQUIDATOR" = true ]; then
  echo "Enter your keyring passphrase for running the liquidator / oracle service(s):"
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
  if ( [ "$SETUP_API" = true ] || [ "$SETUP_LIQUIDATOR" = true ] ) && [ -z "$POSTGRES_URL" ]; then
    echo "Error: No psql database configured for reading off-chain data (required by -a or -l). Either run with -d
    to configure a local postgres instance and persistence service, or provide a \$POSTGRES_URL connection string to the psql database
    where a node running the persistence service is writing this data."
    exit 1
  fi
fi

# if persistence is not installed, api requires a remote persistence WS GRPC address and port
WS_ENV_VAR=
if [ "$SETUP_PERSISTENCE" != true ] && [ "$SETUP_API" = true ]; then
  if [ -z "$WS_GRPC_URL" ]; then
    echo "Error: No persistence service configured for streaming off-chain data. Either run with -d -p
    to configure a local postgres instance and persistence service, or provide a \$WS_GRPC_URL address
    (e.g. WS_GRPC_URL=127.0.0.1:9091) of a node running the persistence service."
    exit 1
  else
    WS_ENV_VAR="Environment=\"WS_GRPC_URL=$WS_GRPC_URL\""
  fi
fi

DEP_FLAGS=
if [ "$LOCAL_DATABASE" = true ]; then
  DEP_FLAGS+=" -p"
elif [ "$SETUP_PERSISTENCE" = true ]; then
  DEP_FLAGS+=" -c"
fi
if [ "$SETUP_API" = true ] || [ "$SETUP_ORACLE" = true ] || [ "$SETUP_LIQUIDATOR" = true ]; then
  DEP_FLAGS+=" -r"
  INSTALL_REDIS=true
fi

# Install dependencies, jq required for setting $VERSION
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/install-deps.sh) $DEP_FLAGS

DAEMON=carbond
CHAIN_ID=${@:$OPTIND:1}
MONIKER=${@:$OPTIND+1:1}
CHAIN_CONFIG_URL=https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/${CHAIN_ID}
CHAIN_MEDIA_URL=https://media.githubusercontent.com/media/Switcheo/carbon-bootstrap/master/${CHAIN_ID}
VERSION=$(curl -s https://api.github.com/repos/Switcheo/carbon-bootstrap/releases/latest | jq -r .tag_name)
VERSION=${VERSION:1}
NETWORK=$(wget -qO- $CHAIN_CONFIG_URL/NETWORK)
ARCH=$(dpkg --print-architecture)
case $NETWORK in
  mainnet)
    ;;

  testnet)
    ;;

  devnet)
    ;;

  *)
    echo "unknown net: ${NETWORK}"
    exit 1
    ;;
esac
if [ -z ${VERSION+x} ]; then
  echo "Error: Invalid chain ID. Chain with ID: $CHAIN_ID could not be found at https://github.com/Switcheo/carbon-testnet"
  exit 1
fi
PEERS=$(wget -qO- $CHAIN_CONFIG_URL/PEERS)

echo "-- Carbon Setup --"

echo "-- Downloading carbond and cosmovisor"

wget -c https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/carbond${VERSION}-${NETWORK}.linux-${ARCH}.tar.gz -O - | tar -xz
wget -c https://github.com/Switcheo/carbon-bootstrap/releases/download/cosmovisor%2Fv1.0.0/cosmovisor1.0.0.linux-${ARCH}.tar.gz -O - | tar -xz

echo "-- Stopping any previous system service of carbond"

sudo systemctl stop carbond || true
sudo systemctl stop carbond@oracle || true
sudo systemctl stop carbond@liquidator || true

echo "-- Clearing node directories"

rm -rf ~/.carbon
sudo rm -f /usr/local/bin/carbond
sudo rm -f /usr/local/bin/cosmovisor
sudo rm -rf /var/log/carbon/*

echo "---- Downloading and initializing"

./$DAEMON init $MONIKER

echo "---- Setting node configuration"

sed -i 's#timeout_commit = "5s"#timeout_commit = "1s"#g' ~/.carbon/config/config.toml
sed -i 's#cors_allowed_origins = \[\]#cors_allowed_origins = \["*"\]#g' ~/.carbon/config/config.toml
sed -i 's#laddr = "tcp:\/\/127.0.0.1:26657"#laddr = "tcp:\/\/0.0.0.0:26657"#g' ~/.carbon/config/config.toml
sed -i 's#addr_book_strict = true#addr_book_strict = false#g' ~/.carbon/config/config.toml
sed -i 's#db_backend = ".*"#db_backend = "goleveldb"#g' ~/.carbon/config/config.toml
sed -i 's#^persistent_peers =.*#persistent_peers = "'$PEERS'"#g' ~/.carbon/config/config.toml
sed -i 's#log_level = "info"#log_level = "warn"#g' ~/.carbon/config/config.toml
sed -i 's#address = "tcp:\/\/localhost:1317"#address = "tcp:\/\/0.0.0.0:1317"#g' ~/.carbon/config/app.toml  # configure api to listen on all network interface
sed -i 's#pruning = "default"#pruning = "custom"#g' ~/.carbon/config/app.toml                               # use custom pruning
sed -i 's#pruning-keep-recent = "0"#pruning-keep-recent = "100"#g' ~/.carbon/config/app.toml                # keep state for recent 100 blocks
sed -i 's#pruning-keep-every = "0"#pruning-keep-every = "10000"#g' ~/.carbon/config/app.toml                # and every 10,000 blocks
sed -i 's#pruning-interval = "0"#pruning-interval = "10"#g' ~/.carbon/config/app.toml                       # prune the rest every 10 blocks
sed -i 's#snapshot-interval = 0#snapshot-interval = 10000#g' ~/.carbon/config/app.toml                      # save snapshot every 10,000 blocks to allow other nodes to fast-sync here

if [ "$SETUP_API" = true ]; then
  sed -i 's#enable = false#enable = true#g' ~/.carbon/config/app.toml                                       # enable all apis
  sed -i 's#swagger = false#swagger = true#g' ~/.carbon/config/app.toml                                     # enable swagger endpoint
  sed -i -e 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' ~/.carbon/config/app.toml            # enable grpc-web-unsafe-cors
  sed -i -e 's/address = "127.0.0.1:8545"/address = "0.0.0.0:8545"/g' ~/.carbon/config/app.toml             # configure evm json-rpc to listen on all network interface
  sed -i -e 's/ws-address = "127.0.0.1:8546"/ws-address = "0.0.0.0:8546"/g' ~/.carbon/config/app.toml       # configure evm json-rpc websocket to listen on all network interface
fi

echo "---- Creating node directories"

MINOR=$(perl -pe 's/(?<=\d\.\d{1,2}\.)\d{1,2}/0/g' <<< $VERSION)
sudo mv cosmovisor /usr/local/bin
mkdir -p ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin
mv carbond ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin/carbond
rm -f ~/.carbon/cosmovisor/current
ln -s ~/.carbon/cosmovisor/upgrades/v${MINOR} ~/.carbon/cosmovisor/current
sudo ln -s ~/.carbon/cosmovisor/current/bin/carbond /usr/local/bin/carbond

if [ "$SETUP_ORACLE" = true ]; then
  echo "-- Installing oracle SSL cert"
  bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/cert.sh) "127.0.0.1" "127.0.0.1" "~/.carbon"
fi

# configure database strings
START_FLAG=""
if [ -n "$POSTGRES_URL" ]; then
  db_regex="^(.+[a-z0-9])\/([a-zA-Z0-9]+)(\?.*)*$"
  if [[ $POSTGRES_URL =~ $db_regex ]]; then
    DB_NAME=${BASH_REMATCH[2]}
    MAINTENANCE_DB_URL=${BASH_REMATCH[1]}/${CONNECT_DB_NAME:=postgres}${BASH_REMATCH[3]}
  else
    echo "POSTGRES_URL is invalid. Must end with database name (e.g. postgresql://username:password@localhost:5432/carbon)"
    exit 1
  fi
else
  DB_NAME=carbon
  MAINTENANCE_DB_URL=postgresql://postgres@localhost:5432/postgres
  POSTGRES_URL=postgresql://postgres@localhost:5432/carbon
fi

# create empty migrations folder even if persistence flag is set to false
mkdir ~/.carbon/migrations

if [ "$SETUP_PERSISTENCE" = true ]; then
  echo "---- Initializing database"

  echo "Creating db \"$DB_NAME\" using $MAINTENANCE_DB_URL"

  dropdb --maintenance-db=$MAINTENANCE_DB_URL --if-exists $DB_NAME --force
  createdb --maintenance-db=$MAINTENANCE_DB_URL $DB_NAME

  POSTGRES_URL=$POSTGRES_URL $DAEMON migrations
  if [ "$SKIP_GENESIS" != true ]; then
    POSTGRES_URL=$POSTGRES_URL $DAEMON persist-genesis
  fi
  START_FLAG+=" --persistence"
fi

echo "---- Creating carbon systemd service"

# wrap exec command with appropriate log redirection
# $1 - daemon name
# $2 - exec start cmd
wrapCmd () {
  local systemdver=$(systemctl --version | sed -nE "s/systemd ([0-9]+).*/\1/p")
  local wrapped=""
  if [[ $systemdver -gt 239 ]]; then
    wrapped=$(cat <<EOF
StandardOutput=append:/var/log/carbon/$1.out.log
StandardError=append:/var/log/carbon/$1.err.log
ExecStart=$2
EOF
)
  else
    wrapped="ExecStart=/bin/sh -c 'exec "$2" >>/var/log/carbon/"$1".out.log 2>>/var/log/carbon/"$1".err.log'"
  fi
  echo "$wrapped"
}

# configure required services
WANTS=""
if [ "$SETUP_ORACLE" = true ]; then
  WANTS+="Wants=carbond@oracle.service"$'\n'
fi
if [ "$SETUP_LIQUIDATOR" = true ]; then
  WANTS+="Wants=carbond@liquidator.service"$'\n'
fi
if [ "$SETUP_API" = true ]; then
  WANTS+="Wants=carbond@ws-api.service"$'\n'
  START_FLAG+=" --db-api"
fi
if [ "$SETUP_RELAYER" = true ]; then
  WANTS+="Wants=carbond@fee.service"$'\n'
fi

# configure log and start cmds

sudo mkdir -p /var/log/carbon

START_FLAG=$(echo $START_FLAG | xargs echo -n) # strip lead/trail spaces
MAIN_CMD="$(wrapCmd "carbond" "/usr/local/bin/cosmovisor start $START_FLAG")"

sudo tee /etc/systemd/system/carbond.service > /dev/null <<EOF
[Unit]
Description=Carbon Daemon
$WANTS
After=network-online.target

[Service]
User=$USER
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_HOME=$HOME/.carbon"
Environment="DAEMON_NAME=$DAEMON"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="POSTGRES_URL=$POSTGRES_URL"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=false"
$MAIN_CMD
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

echo "---- Creating carbon systemd subservices"

SUB_CMD="$(wrapCmd "carbond@%i" "$HOME/.carbon/cosmovisor/current/bin/carbond %i")"

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
$WS_ENV_VAR
$SUB_CMD
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

echo "---- Creating logrotate"

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
