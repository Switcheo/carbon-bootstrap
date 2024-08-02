#!/bin/bash

set -e

SNAP_RPC="https://tm-api.carbon.network:443"
SNAP_RPC2="https://rpc.carbon.bh.rocks:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
TRUST_HEIGHT=$((LATEST_HEIGHT / 10000 * 10000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)

echo "Setting trust_height=$TRUST_HEIGHT, trust_hash= $TRUST_HASH with current height=$LATEST_HEIGHT"

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC2\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$TRUST_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.carbon/config/config.toml
