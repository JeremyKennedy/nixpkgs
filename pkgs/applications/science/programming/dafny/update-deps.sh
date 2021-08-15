#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nuget-to-nix dotnet-sdk_5 dotnetPackages.Nuget
set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

deps_file="$(realpath "./deps.nix")"

cd ../../../../..

store_src="$(nix-build . -A dafny.src --no-out-link)"
src="$(mktemp -d /tmp/dafny-src.XXX)"
echo "Temp src dir: $src"
cp -rT "$store_src" "$src"
chmod -R +w "$src"

pushd "$src"

mkdir ./nuget_tmp.packages
dotnet restore Source/Dafny.sln --packages ./nuget_tmp.packages

nuget-to-nix ./nuget_tmp.packages > "$deps_file"

popd
rm -r "$src"
