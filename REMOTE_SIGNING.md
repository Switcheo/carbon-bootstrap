# Remote Signing

The following instructions is **ONLY** necessary if you are running a validator node **AND** using a remote signing service (e.g. horcrux). Run all of the following commands on your **VALIDATOR NODE**.

**⚠️ Run these steps in sequence, do not skip any steps! ⚠️**

1. Run the following command to update your node config:

    ```bash
    CARBON_HOME_PATH=~/.carbon # Update home path if necessary
    sed -i '/\[oraclesvc\]/a\
    \
    # Enables sub account signing for votes\
    enable_sub_account_signing = true\
    \
    # Path to the JSON file containing the sub account key to use to sign oracle votes\
    sub_account_key_file_path = "config/oracle_sub_account_key.json"
    ' $CARBON_HOME_PATH/config/config.toml
    ```

2. Run the following command to verify if the configs were added successfully:

    ```bash
    cat $CARBON_HOME_PATH/config/config.toml | grep sub_account
    ```

    You should get the following output:

    ```bash
    enable_sub_account_signing = true
    sub_account_key_file_path = "config/oracle_sub_account_key.json"
    ```

3. Get your oracle subaccount `address` and `pubkey`:

    ```bash
    ORACLE_KEYRING_NAME=oracle # or the oracle subaccount name in your carbond keyring
    carbond keys show $ORACLE_KEYRING_NAME
    ```

    Example:

    ```bash
    $ carbond keys show oracle
    #  - address: swth1m9h80cfhqn08x7hull0n7pwhlu9k0vp7hjm3rp
    #    name: oracle
    #    pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"AvSD0GfhaXK52g9omEn37WD2aOv+ntzLktloPnUtRQ0W"}'
    ```

    **⚠️ If you have not created an oracle subaccount, follow the instructions [here](https://github.com/Switcheo/carbon-bootstrap/blob/master/KEYS.md#create-oracle-subaccount-key) to create one: ⚠️**

4. Convert your oracle subaccount `address` in step 3 to hex:

    ```bash
    ORACLE_ADDRESS=swth1m9h80cfhqn08x7hull0n7pwhlu9k0vp7hjm3rp # from step 3 `address` field
    carbond keys parse $ORACLE_ADDRESS
    ```

    Example:

    ```bash
    $ carbond keys parse swth1m9h80cfhqn08x7hull0n7pwhlu9k0vp7hjm3rp
    => D96E77E13704DE737AFCFFDF3F05D7FF0B67B03E
    ```

5. Get your oracle `priv_key` and convert it to base64:

    ```bash
    ORACLE_KEYRING_NAME=oracle # or your oracle subaccount name in the keyring wallet
    carbond keys export $ORACLE_KEYRING_NAME --keyring-backend file --unsafe --unarmored-hex

    echo "<PRIVATE_KEY>" | xxd -r -p | base64
    ```

    Example:

    ```bash
    $ carbond keys export oracle --keyring-backend file --unsafe --unarmored-hex
    # 6F0AD0BFEE7D4B478AFED096E03CD80A

    $ echo "6F0AD0BFEE7D4B478AFED096E03CD80A" | xxd -r -p | base64
    # bwrQv+59S0eK/tCW4DzYCg==
    ```

6. Add your oracle subaccount key file in the following format to `~/.carbon/config/oracle_sub_account_key.json` (create the file if it does not exist):

    ```js
    {
      "address": "D96E77E13704DE737AFCFFDF3F05D7FF0B67B03E", # copy from step 4
      "pub_key": {
        "type": "tendermint/PubKeySecp256k1",
        "value'": "AvSD0GfhaXK52g9omEn37WD2aOv+ntzLktloPnUtRQ0W" # copy from step 3
      },
      "priv_key": {
        "type": "tendermint/PrivKeySecp256k1",
        "value'": "bwrQv+59S0eK/tCW4DzYCg==" # copy from step 5
      }
    }
    ```
