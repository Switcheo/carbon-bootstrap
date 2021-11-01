# Quickstart

Upgrading from Switcheo TradeHub internal devnet:

```bash
# Install
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/carbon-devnet-0/carbon-devnet-0-scripts/setup.sh) <your_moniker>

# Copy validator keys
cp ~/.switcheod/config/node_key.json ~/.carbon/config/
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config/
cp -r ~/.switcheocli/keyring-switcheo-tradehub ~/.carbon/keyring-file
```
