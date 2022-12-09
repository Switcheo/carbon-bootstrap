# Carbon Bootstrap

This repo collects the genesis and configuration files for the various Carbon testnets / mainnets. It exists so the main Carbon repo does not get bogged down with large genesis files and status updates. This repo also contains scripts which allow bootstrapping or upgrading validators into a Carbon network in various recommended configurations easily.

## Network Status

Latest testnet: [carbon-testnet-42069](./carbon-testnet-42069/genesis.json)

Latest mainnet: [carbon-1](./carbon-1/genesis.json)

## Getting Started

To get started:

1. [Install your node binary](#installation)
2. [Configure validator keys](#configure-validator-keys)
3. [Getting chain data](#getting-chain-data)
4. [Start your node](#starting-nodes)

### Installation

#### Script installation

To quickly get started with the latest testnet / mainnet, run the following command to automatically set up all dependencies and a full node / validator node:

```bash
CHAIN_ID=carbon-1 # or: carbon-testnet-42069 for testnet
MONIKER=mynode    # choose a name for your node here
FLAGS="-adop"     # these flags set up a full node with off-chain persistence (supports all APIs),
                  # use: "-o" for set up with minimum validator requirements,
                  # use: "" for set up with minimum node requirements (no extra services)
URL=https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/setup.sh
bash <(wget -O - $URL) $FLAGS $CHAIN_ID $MONIKER
```

#### Manual installation

For manual installation of nodes, please see [INSTALL.md](/INSTALL.md)

### Configure Validator Keys

If you're running a validator node, you'll need to create your validator key and a few mandatory operator keys (this is different from your Tendermint keys `node_key` / `priv_validator_key.json`) before running your node and subservices. If you're running a non-validating node, you can skip this section.

#### Automatic key creation

To install all required validator and subaccount keys directly on your validator node, run [scripts/create-keys.sh](./scripts/create-keys.sh):

```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/create-keys.sh)
```

You'll need to fund your accounts and then run a few more commands to link your validator subaccounts and promote your node to a validator. Follow all instructions printed from the output of the above script carefully.

#### Manual key creation

You can also create your operator keys on another node, such as a developer machine, for better security and access. Follow this guide to create the required keys manually: [KEYS.md](KEYS.md)

### Getting chain data

There are two main ways to quickly get your node synced with the latest chain data - either through [Statesync](#statesync), or [Chain Download](#chain-download).

Note that this is not possible for nodes that wish to run full API services (-adp), and is only meant for quickly bootstrapping validator nodes. pSQL data dumps for quick syncing of all services is coming soon.

#### Statesync

In order to quickly run your node, configure your node for state syncing first.

1. Curl the latest block height and hash from a trusted RPC node:

    ```bash
    curl -s https://tm-api.carbon.network:443/block | \
      jq -r '.result.block.header.height + "\n" + .result.block_id.hash'
    34922501
    8A9BD3B45B7CE14514975E66F9740488BD0978DDD75A4275F9C445391E7EA2EA
    ```

2. Configure `~/.carbon/config/config.toml` to use state sync:

    ```toml
    [statesync]
    enable = true
    rpc_servers = "https://tm-api.carbon.network:443,https://rpc.carbon.blockhunters.org:443"
    trust_height = 1964
    trust_hash = "6FD28DAAAC79B77F589AE692B6CD403412CE27D0D2629E81951607B297696E5B"
    trust_period = "408h0m0s"
    ```

#### Chain Download

We periodically upload the compressed chain data to this repo under the `chain-name/data` directory.

1. Download the latest chain data, e.g.:

    ```bash
    wget https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/carbon-1/data/xxx-xxx-carbon-1-data.tar.lz4
    ```

2. Go to the carbond data folder and decompress the data:

    ```bash
    cd $HOME/.carbon
    lz4 -d xxx-xxx-carbon-1-data.tar.lz4 -c | tar xvf -
    ```

#### Troubleshooting Slow Sync

If you receive an AppHash mismatch error while slow syncing v2.15.6 binaries from genesis, attempt the following steps:

1. [Stop your node](#stopping-nodes):

    ```bash
    sudo systemctl stop carbond
    ```

2. Rollback the last block with:

    ```bash
    carbond rollback
    ```

3. Replace your binary with v2.15.4 using the [minor version upgrade steps](#minor-version-upgrades)

4. [Start your node](#starting-nodes) and observe its progress via logs.

5. Upgrade your binary back to v2.15.6 using the [minor version upgrade steps](#minor-version-upgrades) when the node panics with:

    ```bash
    ERRO[2022-12-06T11:29:55+01:00] EndBlock: pool virtual K value has reduced!, stack: goroutine 1 [running]:
    ```

### Starting Nodes

Once you have your required keys imported, you can now start the node.

The following command will start the carbon node itself, together with the oracle and liquidator services, which is required to be ran by validators.

```bash
sudo systemctl enable carbond
sudo service carbond start
```

Inspect the logs and make sure everything is working fine.

```shell
# Check that there are no errors:
tail -f /var/log/carbon/carbond*.err*
# Check that services are running:
tail -f /var/log/carbon/carbond*.out*
```

### Troubleshooting

AppHash mismatch:

## Stopping Nodes

To stop all services:

```bash
sudo systemctl stop carbond
```

To stop services individually:

```shell
sudo systemctl stop carbond@oracle
sudo systemctl stop carbond@liquidator
```

## Minor Version Upgrades

To upgrade your node between non-consensus breaking versions (e.g. v2.1.0 to v2.1.1), stopping the node and swapping binaries is sufficient.

Ensure you have perl >5.30, you can check with `perl -v`.

Otherwise replace with `MINOR=x.x.0`. e.g. `VERSION=2.1.1`, `MINOR=2.1.0`.

```bash
# set the version / network to upgrade to here:
VERSION=2.15.6
MINOR=$(perl -pe 's/(?<=\d\.\d{1,2}\.)\d{1,2}/0/g' <<< $VERSION)
NETWORK=mainnet
FILE=carbond${VERSION}-${NETWORK}.linux-$(dpkg --print-architecture).tar.gz
wget https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/${FILE}
tar -xvf ${FILE}
rm ${FILE}
sudo service carbond stop
mv carbond ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin/carbond
sudo service carbond start
```
