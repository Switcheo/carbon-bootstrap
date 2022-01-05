# Stargate Mainnet Upgrade

This guide specifically describes the steps required for validators already running pre-stargate mainnet chain `switcheo-tradehub-1` and are now upgrading to `carbon-1`.

There are two upgrade paths.

- Install `carbon-1` on a new machine (recommended) [link](/setup-on-new-machine)
- Install `carbon-1` on the same machine as `switcheo-tradehub-1` [link](/setup-on-same-machine)

Using a new machine allows automatic installation (easier), and gives you the opportunity to downgrade your node's disk size. Using the same machine requires careful configuration to avoid conflicts or loss of data / operator keys.

## Node Requirements

### CPU

Private Node: 4-core
Public API / RPC Node: 8-core and above

### RAM

Validator: 16GB
Data Node: 32GB if pSQL is running on node, recommended to use remote pSQL database for easier upgrading and monitoring

### SSD

Validator: 500GB
Data Node: 2TB if pSQL is running on node, recommended to use remote pSQL database for easier upgrading and monitoring

## Setup On New Machine

WIP

### Before upgrade height

### At upgrade height

## Setup On Same Machine

WIP

## Notes

- It may take awhile to connect to initial peers as they are being bootstrapped at the same time
- It may take awhile before blocks prgoress as 66% of validator voting power need to come online
