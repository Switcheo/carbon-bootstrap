# Carbon Testnets

This repo collects the genesis and configuration files for the various Carbon testnets. It exists so the main Carbon repo does not get bogged down with large genesis files and status updates. This repo also contains scripts which allow bootstrapping or upgrading validators into a Carbon testnet in various recommended configurations easily.

## Testnet Status

Latest testnet: [carbon-0](/carbon-0/README.md)

## Getting Started

### Automatic Installation

To quickly get started with the latest testnet, run this command to automatically set up all dependencies and a full validator node:

```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/scripts/setup.sh) <chain_id> <your_moniker>
```

### Configure Validator Keys

If you're running a validator node, you'll need to install or import your validator keys before running your node and subservices. If you're running a non-validating node, you can skip this section.

#### Upgrading from previous validator node

To upgrade from a pre-stargate / hardforked chain (e.g. Carbon `carbon-0` from Switcheo TradeHub `switcheo-chain`), copy your existing validator keys from the legacy daemon config directory. If Carbon resides on a different machine, use `scp` instead of `cp`.

```bash
cp ~/.switcheod/config/node_key.json ~/.carbon/config/
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config/
cp -r ~/.switcheocli/keyring-switcheo-tradehub ~/.carbon/keyring-file
```

#### Installing for new validator node

To install a new set of validator / subaccount keys, run [scripts/create-keys.sh]:

```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/scripts/create-keys.sh)
```

You'll need to fund your accounts and then run a few more commands to link your validator subaccounts and promote your node to a validator. Start your node and then follow all instructions printed from the output of the above script carefully.

### Starting Nodes

Once you have your required keys imported, you can now start the node.

The following command will start the carbon node itself, together with the oracle and liquidator services, which is required to be ran by validators.

```bash
sudo systemctl start carbond
```

Inspect the logs and make sure everything is working fine.

```shell
tail -f /var/log/journal/carbon.*
tail -f /var/log/journal/carbon@oracle.*
tail -f /var/log/journal/carbon@liquidator.*
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
