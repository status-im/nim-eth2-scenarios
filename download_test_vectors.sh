#!/bin/bash

dl_version() {
	[[ -z "$1" ]] && { echo "usage: dl_version() vX.Y.Z"; exit 1; }

  [[ -d "tarballs/$1" ]] || {
    mkdir -p "tarballs/$1"
    pushd "tarballs/$1"
    curl -L --remote-name-all "https://github.com/ethereum/eth2.0-spec-tests/releases/download/$1/{general,minimal,mainnet}.tar.gz"
    popd
  }
}

unpack_version() {
	[[ -z "$1" ]] && { echo "usage: unpack_version() vX.Y.Z"; exit 1; }

  [[ -d "tests-$1" ]] || {
    cat "tarballs/$1"/{general,minimal,mainnet}.tar.gz | tar --one-top-level="tests-$1" --strip-components 1 -xvzf - -i
  }
}

dl_version v0.8.3
dl_version v0.9.0

unpack_version v0.8.3
unpack_version v0.9.0
