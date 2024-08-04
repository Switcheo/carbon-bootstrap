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
FLAGS="-o"        # these flags set up a node with minimum validator requirements,
                  # use: "" for set up a non-validator node with no extra services
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

You'll need to fund your accounts and then run a few more commands to promote your node to a validator. Follow all instructions printed from the output of the above script carefully.

#### ii) Manual key creation

You can also create your operator keys on another node, such as a developer machine, for better security and access. Follow this guide to create the required keys manually: [KEYS.md](KEYS.md).

### 3. Getting the latest chain data

You should use statesync to get the latest chain data quickly.

⚠️ Note that this is not possible for nodes that wish to run full API services (`FLAGS="-adp"`), and is only meant for quickly bootstrapping validator nodes. pSQL data dumps for quick syncing of all services is coming soon.

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
    44949303
    ```

2. Get the hash for latest 10kth block:


    ```bash
    curl -s https://tm-api.carbon.network:443/block?height=44940000 | \
      jq -r '.result.block.header.height + "\n" + .result.block_id.hash'
    44940000
    F6C9A8590E4F4C2D1669AF759FCF99E8097981B18067B49E507A360F46B78F0C
    ```

3. Configure `~/.carbon/config/config.toml` to use statesync:

    ```toml
    [statesync]
    enable = true
    rpc_servers = "https://tm-api.carbon.network:443,https://rpc.carbon.blockhunters.org:443"
    trust_height = 44940000
    trust_hash = "F6C9A8590E4F4C2D1669AF759FCF99E8097981B18067B49E507A360F46B78F0C"
    ```

4. [Start your node](#4-starting-nodes) to begin statesync

### 4. Starting Nodes

The following command will start the carbon node itself, together with the installed sub-services.

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

```bash
VERSION=$(curl -s https://api.github.com/repos/Switcheo/carbon-bootstrap/releases/latest | jq -r .tag_name | cut -c 2-) # OR replace this with the version you want
MINOR=$(perl -pe 's/(?<=\d\.\d{1,2}\.)\d{1,2}/0/g' <<< $VERSION) # if you do not have perl >=5.30, replace this with `MINOR=x.x.0`. e.g. `VERSION=2.1.1`, `MINOR=2.1.0`.
NETWORK=mainnet
FILE=carbond${VERSION}-${NETWORK}.linux-$(dpkg --print-architecture).tar.gz
wget https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/${FILE}
tar -xvf ${FILE}
rm ${FILE}
sudo service carbond stop
mv carbond ~/.carbon/cosmovisor/upgrades/v${MINOR}/bin/carbond
sudo service carbond start
```

### 5. Stopping Nodes

To stop all services:

```bash
sudo systemctl stop carbond
```

To stop services individually:

```shell
sudo systemctl stop carbond@oracle
sudo systemctl stop carbond@liquidator
```
