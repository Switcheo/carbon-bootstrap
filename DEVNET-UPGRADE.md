# Upgrading from Switcheo Chain

## Quickstart

### Instant Gratification Snippet
```bash
bash <(wget -O - https://raw.githubusercontent.com/Switcheo/carbon-testnets/master/scripts/devnet-upgrade.sh) <your_moniker>
```
Copy previous keys from Switcheo Chain. If Carbon resides on a different machine, use `scp` and update the command accordingly.
```bash
cp ~/.switcheod/config/node_key.json ~/.carbon/config/
cp ~/.switcheod/config/priv_validator_key.json ~/.carbon/config/
cp -r ~/.switcheocli/keyring-switcheo-tradehub ~/.carbon/keyring-file
```
