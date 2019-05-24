#!/bin/bash

# Supported kernals: Darwin (macos) and Linux (linux)
# Windows, CYGWIN, etc are not supported at this time
unameIs="$(uname -s)"
case "${unameIs}" in
    Darwin*) OS=macos;;
    *)       OS=linux;;
esac

# Download release
VERSION=$(cat VERSION)

curl -Ls https://github.com/opolis/deployer/releases/download/$VERSION/opolis-deployer-config-$OS > opolis-deployer-config
chmod +x opolis-deployer-config

read -p "Save to /usr/local/bin? [y/n] " ALLOW_MOVE

if [[ "$ALLOW_MOVE" == "y" ]]; then
    mv opolis-deployer-config /usr/local/bin/
fi
