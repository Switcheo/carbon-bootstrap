# Carbon Bootstrap

This repo collects the genesis and configuration files for the various Carbon testnets / mainnets. It exists so the main Carbon repo does not get bogged down with large genesis files and status updates. This repo also contains scripts which allow bootstrapping or upgrading validators into a Carbon network in various recommended configurations easily.

## Network Status

Latest testnet: [carbon-testnet-42069](./carbon-testnet-42069/genesis.json)

Latest mainnet: [carbon-1](./carbon-1/genesis.json)

## Getting Started

You will need to perform these steps to get a Carbon node up and running:

1. [Install your node binary](#1-installation)
2. [Configure validator keys](#2-configure-validator-keys)
3. [Getting latest chain data (optional)](#3-getting-the-latest-chain-data)
4. [Start your node](#4-starting-nodes)

### 1. Installation

You can install your node via i) a [single command script](#i-script-installation) or ii) [manually](#ii-manual-installation).

#### i) Script installation

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

#### ii) Manual installation

For manual installation of nodes, please see [INSTALL.md](/INSTALL.md).

### 2. Configure Validator Keys

If you're running a validator node, you'll need to create your validator key and a few mandatory operator keys (this is different from your Tendermint keys `node_key` / `priv_validator_key.json`) before running your node and subservices. If you're running a non-validating node, you can skip this section.

You can do this using i) the [script below](#i-automatic-key-creation), or ii) [by creating them manually](#ii-manual-key-creation).

#### i) Automatic key creation

To install all required validator and subaccount keys directly on your validator node, run [scripts/create-keys.sh](./scripts/create-keys.sh):

```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/create-keys.sh)
```

You'll need to fund your accounts and then run a few more commands to link your validator subaccounts and promote your node to a validator. Follow all instructions printed from the output of the above script carefully.

#### ii) Manual key creation

You can also create your operator keys on another node, such as a developer machine, for better security and access. Follow this guide to create the required keys manually: [KEYS.md](KEYS.md).

### 3. Getting the latest chain data

There are two main ways to quickly get your node synced with the latest chain data - either through i) [Statesync](#i-statesync), or ii) [Chain Download](#ii-chain-download).

⚠️ Note that this is not possible for nodes that wish to run full API services (`FLAGS="-adp"`), and is only meant for quickly bootstrapping validator nodes. pSQL data dumps for quick syncing of all services is coming soon.

**Before running any statesync/chain-download steps:**

1. Update and link current binaries to the latest version:
    ```bash
    # set the version / network to upgrade to here:
    VERSION=2.22.1
    MINOR=2.22.0
    NETWORK=mainnet
    FILE=carbond${VERSION}-${NETWORK}.linux-$(dpkg --print-architecture).tar.gz
    wget https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/${FILE}
    tar -xvf ${FILE}
    rm ${FILE}
    mkdir -p ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin
    mv carbond ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin/carbond
    rm ~/.carbon/cosmovisor/current
    ln -s ~/.carbon/cosmovisor/upgrades/v${MINOR} ~/.carbon/cosmovisor/current
    ```

#### i) Statesync

If your node has already started before, you need to remove existing blockchain data. Do not delete any other files such as node/wallet keys.

```bash
rm -rf ~/.carbon/data/*.db ~/.carbon/data/snapshots ~/.carbon/data/cs.wal ~/.carbon/config/addrbook.json ~/.carbon/data/upgrade-info.json
```

You can configure statesync a) via our [helper script](#a-helper-script), or b) [manually](#b-configure-manually).

##### a) Helper Script

1. Execute the following script:

    ```bash
    bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/configure-statesync.sh)
    ```

2. [Start your node](#4-starting-nodes) to begin statesync

##### b) Configure Manually

1. Find the latest block height and hash from a trusted RPC node:

    ```bash
    curl -s https://tm-api.carbon.network:443/block | \
      jq -r '.result.block.header.height'
    34922501
    ```

2. Get the hash for 10k blocks behind the current height:


    ```bash
    curl -s https://tm-api.carbon.network:443/block?height=34912501 | \
      jq -r '.result.block.header.height + "\n" + .result.block_id.hash'
    34912501
    8D8A6C7BC2559AF778545B8B983D5C33013E99B628AE013CBE967FACAC3C09BE
    ```

3. Configure `~/.carbon/config/config.toml` to use statesync:

    ```toml
    [statesync]
    enable = true
    rpc_servers = "https://tm-api.carbon.network:443,https://rpc.carbon.blockhunters.org:443"
    trust_height = 34912501
    trust_hash = "8D8A6C7BC2559AF778545B8B983D5C33013E99B628AE013CBE967FACAC3C09BE"
    ```

4. [Start your node](#4-starting-nodes) to begin statesync

#### ii) Chain Download

We periodically upload the compressed chain data to this repo under the `<chain-name>/data` directory. The data filenames are prefixed by date and block height.

1. Download the latest chain data, e.g.:

    ```bash
    wget https://github.com/Switcheo/carbon-bootstrap/raw/master/carbon-1/data/20221209-34931459-carbon-1-data.tar.lz4
    ```

2. Go to the carbond data folder and decompress the data:

    ```bash
    cd $HOME/.carbon
    lz4 -d ~/20221209-34931459-carbon-1-data.tar.lz4 -c | tar xvf -
    ```

### 4. Starting Nodes

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

## Minor Version Upgrades

To upgrade your node between non-consensus breaking versions (e.g. v2.1.0 to v2.1.1), stopping the node and swapping binaries is sufficient.

Ensure you have perl >5.30, you can check with `perl -v`.

Otherwise replace with `MINOR=x.x.0`. e.g. `VERSION=2.1.1`, `MINOR=2.1.0`.

```bash
# set the version / network to upgrade to here:
VERSION=2.22.1
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

## Troubleshooting

### Troubleshooting Slow Sync

If you receive an AppHash mismatch error while slow syncing from genesis (crash at v2.15.6 binary), attempt the following steps:

1. [Stop your node](#stopping-nodes)

2. Rollback the last block with:

    ```bash
    carbond rollback
    ```

3. Replace your binary with v2.15.4 using the [minor version upgrade steps](#minor-version-upgrades)

4. [Start your node](#starting-nodes) and observe its progress via logs

5. Upgrade your binary back to v2.15.6 using the [minor version upgrade steps](#minor-version-upgrades) when the node panics with:

    ```bash
    ERRO[2022-12-06T11:29:55+01:00] EndBlock: pool virtual K value has reduced!, stack: goroutine 1 [running]:
    ```

### Stopping Nodes

To stop all services:

```bash
sudo systemctl stop carbond
```

To stop services individually:

```shell
sudo systemctl stop carbond@oracle
sudo systemctl stop carbond@liquidator
```
