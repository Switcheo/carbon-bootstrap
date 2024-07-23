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

function preDownloadUpgrade () {
  majorVersion=$1
  minorVersion=$2
  echo "---- Pre-downloading upgrades for major version: ${majorVersion} and minor version: ${minorVersion}"
  FILE=carbond${minorVersion}-${NETWORK}.linux-$(dpkg --print-architecture).tar.gz
  wget https://github.com/Switcheo/carbon-bootstrap/releases/download/v${minorVersion}/${FILE}
  tar -xvf ${FILE}
  rm ${FILE}
  mkdir -p ~/.carbon/cosmovisor/upgrades/v${majorVersion}/bin
  mv carbond ~/.carbon/cosmovisor/upgrades/v${majorVersion}/bin/carbond
}

# Install configuration variables
PUBLIC_NODE=false
LOCAL_DATABASE=false
SETUP_API=false
SETUP_LIQUIDATOR=false
SETUP_ORACLE=false
SETUP_PERSISTENCE=false
SETUP_RELAYER=false
SKIP_GENESIS=false
STATE_SYNC=false
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
    s)
      SKIP_GENESIS=true
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

if [ "$SETUP_PERSISTENCE" = true ] && [ "$STATE_SYNC" = true ]; then
  echo "Error: State sync does not support persistence."
  exit 1
fi

# Chain variables
DAEMON=carbond
CHAIN_ID=${@:$OPTIND:1}
MONIKER=${@:$OPTIND+1:1}
CHAIN_CONFIG_URL=https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/${CHAIN_ID}
CHAIN_MEDIA_URL=https://media.githubusercontent.com/media/Switcheo/carbon-bootstrap/master/${CHAIN_ID}
VERSION=$(wget -qO- $CHAIN_CONFIG_URL/VERSION)
NETWORK=$(wget -qO- $CHAIN_CONFIG_URL/NETWORK)
UPGRADES=()
while read UPGRADE; do
  UPGRADES+=($UPGRADE)
done < <(wget -qO- ${CHAIN_CONFIG_URL}/UPGRADES)
if [ "$STATE_SYNC" = true ] && [ ${#UPGRADES[@]} -ne 0 ]; then
  IFS='=' read majorVersion minorVersion <<< ${UPGRADES[-1]}
  VERSION=$minorVersion
fi
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

# if ws-api, oracle or liquidator is installed, redis and hot wallet is required.
WALLET_STRING=
if [ "$SETUP_API" = true ] || [ "$SETUP_ORACLE" = true ] || [ "$SETUP_LIQUIDATOR" = true ]; then
  INSTALL_REDIS=true
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

echo "-- Carbon Setup --"

DEP_FLAGS=
if [ "$LOCAL_DATABASE" = true ]; then
  DEP_FLAGS+=" -p"
elif [ "$SETUP_PERSISTENCE" = true ]; then
  DEP_FLAGS+=" -c"
fi
if [ "$SETUP_ORACLE" = true ] || [ "$SETUP_LIQUIDATOR" = true ]; then
  DEP_FLAGS+=" -r"
fi

bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/install-deps.sh) $DEP_FLAGS

echo "-- Downloading carbond and cosmovisor"

wget -c https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/carbond${VERSION}-${NETWORK}.linux-$(dpkg --print-architecture).tar.gz -O - | tar -xz
wget -c https://github.com/Switcheo/carbon-bootstrap/releases/download/cosmovisor%2Fv1.0.0/cosmovisor1.0.0.linux-$(dpkg --print-architecture).tar.gz -O - | tar -xz

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
if [ "$SKIP_GENESIS" != true ]; then
  wget -O ~/.carbon/config/genesis.json ${CHAIN_MEDIA_URL}/genesis.json
fi

echo "---- Setting node configuration"


# preload evm config in app.toml for mainnet since genesis carbond init is pre-evm
if [ "$NETWORK" == "mainnet" ]; then

cat << EOF >> ~/.carbon/config/app.toml


###############################################################################
###                         Store / State Streaming                         ###
###############################################################################

[store]
streamers = []

[streamers]
[streamers.file]
keys = ["*", ]
write_dir = ""
prefix = ""

# output-metadata specifies if output the metadata file which includes the abci request/responses
# during processing the block.
output-metadata = "true"

# stop-node-on-error specifies if propagate the file streamer errors to consensus state machine.
stop-node-on-error = "true"

# fsync specifies if call fsync after writing the files.
fsync = "false"

###############################################################################
###                             EVM Configuration                           ###
###############################################################################

[evm]

# Tracer defines the 'vm.Tracer' type that the EVM will use when the node is run in
# debug mode. To enable tracing use the '--evm.tracer' flag when starting your node.
# Valid types are: json|struct|access_list|markdown
tracer = ""

# MaxTxGasWanted defines the gas wanted for each eth tx returned in ante handler in check tx mode.
max-tx-gas-wanted = 0

###############################################################################
###                           JSON RPC Configuration                        ###
###############################################################################

[json-rpc]

# Enable defines if the gRPC server should be enabled.
enable = true

# Address defines the EVM RPC HTTP server address to bind to.
address = "0.0.0.0:8545"

# Address defines the EVM WebSocket server address to bind to.
ws-address = "0.0.0.0:8546"

# API defines a list of JSON-RPC namespaces that should be enabled
# Example: "eth,txpool,personal,net,debug,web3"
api = "eth,net,web3"

# GasCap sets a cap on gas that can be used in eth_call/estimateGas (0=infinite). Default: 25,000,000.
gas-cap = 25000000

# EVMTimeout is the global timeout for eth_call. Default: 5s.
evm-timeout = "5s"

# TxFeeCap is the global tx-fee cap for send transaction. Default: 1eth.
txfee-cap = 1

# FilterCap sets the global cap for total number of filters that can be created
filter-cap = 200

# FeeHistoryCap sets the global cap for total number of blocks that can be fetched
feehistory-cap = 100

# LogsCap defines the max number of results can be returned from single 'eth_getLogs' query.
logs-cap = 10000

# BlockRangeCap defines the max block range allowed for 'eth_getLogs' query.
block-range-cap = 10000

# HTTPTimeout is the read/write timeout of http json-rpc server.
http-timeout = "30s"

# HTTPIdleTimeout is the idle timeout of http json-rpc server.
http-idle-timeout = "2m0s"

# AllowUnprotectedTxs restricts unprotected (non EIP155 signed) transactions to be submitted via
# the node's RPC when the global parameter is disabled.
allow-unprotected-txs = false

# MaxOpenConnections sets the maximum number of simultaneous connections
# for the server listener.
max-open-connections = 0

# EnableIndexer enables the custom transaction indexer for the EVM (ethereum transactions).
enable-indexer = false

# MetricsAddress defines the EVM Metrics server address to bind to. Pass --metrics in CLI to enable
# Prometheus metrics path: /debug/metrics/prometheus
metrics-address = "0.0.0.0:6065"

###############################################################################
###                             TLS Configuration                           ###
###############################################################################

[tls]

# Certificate path defines the cert.pem file path for the TLS configuration.
certificate-path = ""

# Key path defines the key.pem file path for the TLS configuration.
key-path = ""

EOF

fi

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

if [ "$STATE_SYNC" = true ]; then
  RPC_SERVERS=$(sed -E 's#[^,@]+@([^@:]+):26656#\1:26657#g' <<< $PEERS)

  IFS=',' read URL REST <<< $RPC_SERVERS
  BLOCK_RESP=$(wget -qO- "http://$URL/block")
  BLOCK_HEIGHT=$(jq -r '.result.block.header.height' <<< $BLOCK_RESP)
  BLOCK_HASH=$(jq '.result.block_id.hash' <<< $BLOCK_RESP)
  UNBONDING_TIME=$(jq '.app_state.staking.params.unbonding_time' ~/.carbon/config/genesis.json)

  sed -i 's#enable = false#enable = true#g' ~/.carbon/config/config.toml
  sed -i 's#rpc_servers = ""#rpc_servers = "'"$RPC_SERVERS"'"#g' ~/.carbon/config/config.toml
  sed -i 's#trust_height = 0#trust_height = '"$BLOCK_HEIGHT"'#g' ~/.carbon/config/config.toml
  sed -i 's#trust_hash = ""#trust_hash = '"$BLOCK_HASH"'#g' ~/.carbon/config/config.toml
  sed -i 's#trust_period = "168h0m0s"#trust_period = '"$UNBONDING_TIME"'#g' ~/.carbon/config/config.toml
fi

echo "---- Creating node directories"

mkdir -p ~/.carbon/cosmovisor/genesis/bin
mv $DAEMON ~/.carbon/cosmovisor/genesis/bin
if [ "$STATE_SYNC" != true ]; then
  for UPGRADE in "${UPGRADES[@]}"; do
    IFS='=' read majorVersion minorVersion <<< $UPGRADE
    preDownloadUpgrade $majorVersion $minorVersion
  done
fi
sudo mv cosmovisor /usr/local/bin
sudo ln -s ~/.carbon/cosmovisor/genesis ~/.carbon/cosmovisor/current
sudo ln -s ~/.carbon/cosmovisor/current/bin/$DAEMON /usr/local/bin/$DAEMON

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

  dropdb --maintenance-db=$MAINTENANCE_DB_URL --if-exists $DB_NAME
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
