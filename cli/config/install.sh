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

curl -Ls https://github.com/opolis/build/releases/download/$VERSION/opolis-build-config-$OS > opolis-build-config
chmod +x opolis-build-config

read -p "Save to /usr/local/bin? [y/n] " ALLOW_MOVE

if [[ "$ALLOW_MOVE" == "y" ]]; then
    mv opolis-build-config /usr/local/bin/
fi
