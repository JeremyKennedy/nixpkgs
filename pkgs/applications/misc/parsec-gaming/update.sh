#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=../../../../ -i bash -p curl -p jq

set -euo pipefail

appdata=$(curl -qL https://builds.parsecgaming.com/channel/release/appdata/linux/latest)
so=https://builds.parsecgaming.com/channel/release/binary/linux/gz/$(echo "$appdata" | jq -r .so_name)
nix_hash=$(nix-prefetch-url $so)

echo "$appdata" | jq ".nix_hash=\"$nix_hash\"" > parsecd.json
