# Stargate Mainnet Upgrade

This guide specifically describes the steps required for validators already running pre-stargate mainnet chain `switcheo-tradehub-1` and are now upgrading to `carbon-1`.

There are two upgrade paths.

- Install `carbon-1` on a new machine (recommended) [link](#setup-on-new-machine)
- Install `carbon-1` on the same machine as `switcheo-tradehub-1` [link](#setup-on-same-machine)

Using a new machine allows automatic installation (easier), and also gives you the opportunity to downgrade your node's disk size. Using the same machine requires careful configuration to avoid conflicts or loss of data / operator keys.

## Node Requirements

Node requirements depend on whether the node is running a postgres instance locally (offchain-data node), and if it is publicly accessible (public API / RPC node).

Validators that are ran in a safe configuration should typically be private + state-only nodes.

Archival, seed, sentry, or API nodes are typically public + offchain-data nodes. It is recommended to connect to a remote postgres instance for these nodes, in which case their requirements for RAM and disk storage can be lowered to that of state-only nodes.

### Operating System

While any linux distribution should work in theory, only Ubuntu 18.04 / 20.04 is officialy supported as scripts and instructions assume an Ubuntu distro. You will need to modify the setup instructions yourself if you choose to use a non-Ubuntu distro.

### CPU

Both AMD-64 or ARM-64 are supported.

- Private Node: 4-core vCPU (e.g. m6gd.xlarge)
- Public API / RPC Node: 8-core vCPU and above (e.g. m6gd.x2large)

### RAM

- State-only Node: 16GB
- Offchain-data Node (remote postgres): 16GB
- Offchain-data Node (local postgres): 32GB

### SSD

- State-only Node: 500GB
- Offchain-data Node (remote postgres): 500GB
- Offchain-data Node (local postgres): 2TB

## Preparation

For a smooth upgrade, decide how you will install the new `carbond` node, and prepare the machine ahead of the upgrade height.

### Setup on new machine

1. Run the following script to download binaries and setup Carbon automatically. Replace `<your_moniker>` with your previous node's moniker.

    - For full nodes:

      `bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/setup.sh) -adops carbon-1 <your_moniker>`

    - For full node with remote db:

      `POSTGRES_URL=postgresql://username:password@hostname:5432/carbon <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/setup.sh) -aops carbon-1 <your_moniker>`

    - For validating-only nodes:

        `bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-bootstrap/master/scripts/setup.sh) -os carbon-1 <your_moniker>`

2. Copy validator keys from your old machine to the new machine.

    ```bash
    scp ~/.switcheod/config/node_key.json <new_node_ip>:~/.carbon/config/
    scp ~/.switcheod/config/priv_validator_key.json <new_node_ip>:~/.carbon/config/
    scp -r ~/.switcheocli/keyring-switcheo-tradehub <new_node_ip>:~/.carbon/keyring-file
    ```

### Setup on same machine

1. Follow the [manual installation guide](./INSTALL.md), skipping the setup sections for Redis and Postgres (as they should already be installed).
2. Copy your existing validator keys to the new node config directory. See [this section](./INSTALL.md#upgrading-from-existing-validator) for the files required.
3. Create the `carbon` postgres database

    `createdb carbon`

4. Ensure your `carbond` node is not running yet and await the upgrade height

    `sudo systemctl stop carbond`

## At Upgrade Height

1. Stop your `switcheod` node fully, once you observe that block progression has halted from the node logs:

    `switcheoctl stop`

2. Export the current state from your `switcheod` node into an exported genesis.json file.

    `switcheod node export > ~/genesis-exported.json`

    If exported is not possible for any reason, await the genesis file upload to this repo, and download it once it is ready, **skipping steps 3-5**.

3. Check hash of your exported genesis file:

    `openssl sha256 ~/genesis-exported.json`

    `=> # Hash = <TODO>`

4. If your `carbond` node will run on a new machine, copy the exported genesis file to the new node.

    `scp ~/genesis-exported.json <new-node-ip>:~/genesis-exported.json`

5. Run the genesis migration command on your `carbond` node:

    `carbond migrate genesis-exported.json --chain-id carbon-1 > ~/carbon/config/genesis.json`

6. Check hash of the migrated genesis file that will be used:

    `openssl sha256 ~/.carbon/config/genesis.json`

    `=> # Hash = <TODO>`

7. If running a offchain-data node, run:

    `carbond persist-genesis`

8. Ensure your seed peers are updated. You can find the latest peers [here](./carbon-1/PEERS), and you can [update them](./INSTALL.md#add-seed-nodes) in `config.toml` in `seeds="..."`.

## Notes

- It may take awhile to connect to initial peers as they are being bootstrapped at the same time
- It may take awhile before blocks prgoress as 66% of validator voting power need to come online
