
# Creating validator keys

To run a validator, you'll need:

i)  a validator key (cold) that allows you to control your validator parameters
ii) a separate oracle subaccount key (hot) that signs oracle vote transactions if you are using a remote signing service

## Create validator key

1. On your validator node, get it's public key and note it down:

      ```bash
      carbond tendermint show-validator
      ```

2. On the machine(s) that you wish to install your keys, download and install the appropriate [release](https://github.com/Switcheo/carbon-bootstrap/releases).

3. Create your validator operator key and password:

    ```bash
    # Note that this can be on any machine that has `carbond`, so the key can be kept secure, separate from the validator machine.
    carbond keys add val --keyring-backend file -i
    ```

4. Your validator address is:

    ```bash
    carbond keys show val -a --keyring-backend file
    ```

5. You will need some Carbon tokens ($SWTH) to start your validator. You can get testnet tokens from the [faucet](https://test-faucet.carbon.network).

6. After receiving tokens, promote your node to a validator by running:

    ```bash
    carbond tx staking create-validator --amount 100000000000swth --commission-max-change-rate "0.025" --commission-max-rate "0.20" --commission-rate "0.05" --details "Some details about your validator" --from val --pubkey='PublicKeyFromStep1' --moniker "NameForYourValidator" --min-self-delegation "1" --fees 100000000swth --gas 300000 --chain-id <chain_id> --keyring-backend file
    # add --node="https://tm-api.carbon.network:443" if using a separate machine
    ```

## Create oracle subaccount key (Remote signing only)

Validators that run their nodes via a remote signing service require an oracle subaccount.

1. On any node, create the oracle key:

    ```bash
    # Secure the key with the same password you used during node setup!
    carbond keys add oracle --keyring-backend file -i
    ```

    >! Your oracle subservice needs access to your oracle wallet (hot wallet). Ensure that it is installed on the same node that is running the oracle subservice, and that the service has the right password for decrypting the wallet.

2. Send some Carbon tokens ($SWTH) to your oracle wallet (mainnet), or get them from the [faucet](https://test-faucet.carbon.network) (testnet).

    ```bash
    # From validator or other wallet with funds
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

## Create liquidator subaccount key (Optional)

The steps for creating a liquidator are exactly the same as an oracle (replace `oracle` with `liquidator`). Liquidator incentives / penalties are not enabled yet, so validators can choose to run this subservice on an altruistic basis. Just one validator / operator needs to run the liquidator for liquidations to execute correctly.
