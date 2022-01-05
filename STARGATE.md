# Stargate Mainnet Upgrade

This guide specifically describes the steps required for validators already running pre-stargate mainnet chain `switcheo-tradehub-1` and are now upgrading to `carbon-1`.

There are two upgrade paths.

- Install `carbon-1` on a new machine (recommended) [link](/setup-on-new-machine)
- Install `carbon-1` on the same machine as `switcheo-tradehub-1` [link](/setup-on-same-machine)

Using a new machine allows automatic installation (easier), and gives you the opportunity to downgrade your node's disk size. Using the same machine requires careful configuration to avoid conflicts or loss of data / operator keys.

## Node Requirements

Node requirements depend on whether the node is running a postgres instance locally (offchain-data node), and if it is publicly accessible (public API / RPC node).

Validators in a safe configuration are typically private, state-only nodes.

Archival, seed, sentry, or API nodes are typically public, off-chain data nodes. It is recommended to connect to a remote postgres instance for these nodes, in which case they can be considered "state-only nodes".

### CPU

- Private Node: 4-core vCPU (e.g. m6gd.xlarge)
- Public API / RPC Node: 8-core vCPU and above (e.g. m6gd.x2large)

### RAM

- State-only Node: 16GB
- Offchain-data Node (local postgres): 32GB

### SSD

- State-only Node: 500GB
- Offchain-data Node (local postgres): 2TB

## Preparation

WIP

### Setup On New Machine

1. Run wget bash script to download binaries and setup automatically.
2. Copy validator keys to the new machine.

### Setup on Same Machine

1. Download the genesis binary
2. Follow the [manual installation guide](./INSTALL.md), skipping the setup for Redis and Postgres
3. Copy your existing validator keys to the new node config directory
4. Create the `carbon` postgres database
5. Ensure your `carbond` node is not running yet and await the upgrade height

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

7. Ensure your seed peers are updated. You can find the latest peers [here](./carbon-1/PEERS), and you can [update them](./INSTALL.md#add-seed-nodes) in `config.toml` in `seeds="..."`.

## Notes

- It may take awhile to connect to initial peers as they are being bootstrapped at the same time
- It may take awhile before blocks prgoress as 66% of validator voting power need to come online
