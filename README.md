# Carbon Bootstrap

This repo collects the genesis and configuration files for the various Carbon testnets / mainnets. It exists so the main Carbon repo does not get bogged down with large genesis files and status updates. This repo also contains scripts which allow bootstrapping or upgrading validators into a Carbon network in various recommended configurations easily.

For validators upgrading to `carbon-1` mainnet, go [here](/STARGATE.md) for a detailed upgrade guide.

## Network Status

Latest testnet: [carbon-42069](./carbon-42069/genesis.json)

Latest mainnet: [carbon-1](./carbon-1/genesis.json)

## Getting Started

### Automatic Installation

To quickly get started with the latest testnet / mainnet, run this command to automatically set up all dependencies and a full node / validator node:

```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/setup.sh) -adlop <chain_id> <your_moniker>
```

If running a validator, configure your operator keys in the section below.

### Configure Validator Keys

If you're running a validator node, you'll need to create or import your validator keys before running your node and subservices. If you're running a non-validating node, you can skip this section.

#### Upgrading from existing validator

To upgrade from a pre-stargate or hardforked-upgraded chain (e.g. Carbon `carbon-1` from Switcheo TradeHub `switcheo-tradehub-1`), copy your existing both your validator operator keys (`keyring-file`) and Tendermint node keys (`node_key.json` and `priv_validator_key.json`) from the legacy daemon config directory. If Carbon resides on a different machine, use `scp` instead of `cp`.

```bash
cp ~/.switcheod/config/node_key.json ~/.carbon/config/
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config/
cp -r ~/.switcheocli/keyring-switcheo-tradehub ~/.carbon/keyring-file
```

#### Installing for new validator

If you are running a validator for the first time, you will need to create a few mandatory operator keys (this is different from your Tendermint keys `node_key` / `priv_validator_key.json` which are automatically created when bootstrapping).

#### Automatic key creation

To install all required validator and subaccount keys directly on your validator node, run [scripts/create-keys.sh](./scripts/create-keys.sh):

```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/create-keys.sh)
```

You'll need to fund your accounts and then run a few more commands to link your validator subaccounts and promote your node to a validator. Follow all instructions printed from the output of the above script carefully.

#### Manual key creation

You can also create your operator keys on another node, such as a developer machine, for better security and access. Here's how to create the required keys manually:

##### Create validator

1. On your validator node, get it's public key and note it down:

      ```bash
      carbond tendermint show-validator
      ```

2. On the machine(s) that you wish to install your keys, download and install the appropriate [release](https://github.com/Switcheo/carbon-bootstrap/releases).

3. Create your validator operator key and password:

    ```bash
    carbond keys add val --keyring-backend file -i
    ```

4. Your validator address is:

    ```bash
    carbond keys show val -a --keyring-backend file
    ```

5. You will need some Switcheo tokens to start your validator. You can get testnet tokens from the [faucet](https://test-faucet.carbon.network).

6. After receiving tokens, promote your node to a validator by running:

    ```bash
    carbond tx staking create-validator --amount 100000000000swth --commission-max-change-rate "0.025" --commission-max-rate "0.20" --commission-rate "0.05" --details "Some details about your validator" --from val --pubkey='PublicKeyFromStep1' --moniker "NameForYourValidator" --min-self-delegation "1" --fees 100000000swth --gas 300000  --chain-id <chain_id> --keyring-backend file
    ```

##### Create oracle

All validators need to run a node (either the same node as the validator, or some other secondary node) that has the oracle service enabled.

1. On your node that is running the oracle service, create the oracle key:

    ```bash
    # Secure the key with the same password you used during node setup!
    carbond keys add oracle --keyring-backend file -i
    ```

    >! Your oracle subservice needs access to your oracle wallet (hot wallet). Ensure that it is installed on the same node that is running the oracle subservice, and that the service has the right password for decrypting the wallet.

2. Send some Switcheo tokens to your oracle wallet (mainnet), or get them from the [faucet](https://test-faucet.carbon.network) (testnet).

    ```bash
    # From validator walelt
    carbond tx bank send [from_key_or_address] [to_address] [amount]
    ```

3. After receiving tokens, initiate linking your oracle account as a subaccount of your validator by running this from a node that has access to your validator operator wallet.

    ```bash
    carbond tx subaccount create-sub-account <oracle_address> --from val --fees 100000000swth  --gas 300000 --chain-id <chain_id> --keyring-backend file -y
    ```

4. Accept the link from a node that has access to the oracle account (i.e. oracle subservice node).

    ```bash
    carbond tx subaccount activate-sub-account <val_address> --from oracle --fees 100000000swth --gas 300000 --chain-id <chain_id> --keyring-backend file -y
    ```

    > By running the oracle as a subaccount, your validator operator key can be secured without exposing it on a hot machine.

##### Create liquidator

The steps for creating a liquidator is exactly the same as an oracle (replace `oracle` with `liquidator`). Liquidator incentives / penalties are not enabled yet, so validators can choose to run this subservice on an altrustic basis. Just one operator needs to run the liquidator for liquidations to execute correctly.

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

### Manual Installation

For manual installation of nodes, please see [INSTALL.md](/INSTALL.md)

### Minor Version Upgrades

To upgrade your node between non-consensus breaking versions (e.g. v2.1.0 to v2.1.1), stopping the node and swapping binaries is sufficient.

```bash
# set the version / network to upgrade to here:
VERSION=2.0.3
NETWORK=mainnet
FILE=carbond${VERSION}-${NETWORK}.linux-$(dpkg --print-architecture).tar.gz
wget https://github.com/Switcheo/carbon-bootstrap/releases/download/v${VERSION}/${FILE}
tar -xvf ${FILE}
sudo service carbond stop
mv carbond ~/.carbon/cosmovisor/current/bin/carbond
sudo service carbond start
rm ${FILE}
```
