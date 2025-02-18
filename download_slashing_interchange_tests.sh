#!/usr/bin/env bash

# Copyright (c) 2021-2025 Status Research & Development GmbH. Licensed under
# either of:
# - Apache License, version 2.0
# - MIT license
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

set -Eeuo pipefail

VERSIONS=(
  "v5.3.0"
)
FLAVOURS=(
  "v5.3.0"
)

# signal handler (we only care about the Ctrl+C generated SIGINT)
REL_PATH="$(dirname "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd "${REL_PATH}"; pwd)"
cleanup() {
	echo -e "\nCtrl+C pressed. Cleaning up."
	cd "$ABS_PATH"
	rm -rf tarballs tests-slashing-*
	exit 1
}
trap cleanup SIGINT

dl_version() {
	[[ -z "$1" ]] && { echo "usage: dl_version() vX.Y.Z"; exit 1; }
	version="$1"

	mkdir -p "tarballs/slashing-${version}"
	pushd "tarballs/slashing-${version}" >/dev/null
	for flavour in "${FLAVOURS[@]}"; do
		if [[ ! -e "${flavour}.tar.gz" ]]; then
			echo "Downloading: slashing-${version}/${flavour}.tar.gz"
			curl --location --remote-name --silent --show-error --retry 3 --retry-all-errors \
				"https://github.com/eth-clients/slashing-protection-interchange-tests/archive/refs/tags/${flavour}.tar.gz" \
				|| {
					echo "Curl failed. Aborting"
					rm -f "${flavour}.tar.gz"
					exit 1
				}
		fi
	done
	popd >/dev/null
}

unpack_version() {
	[[ -z "$1" ]] && { echo "usage: unpack_version() vX.Y.Z"; exit 1; }
	version="$1"

	local retries=0 ok=0
	while (( !ok && ++retries <= 5 )); do  # downloaded tar.gz may be corrupted
		dl_version "$version"

		# suppress warnings when unpacking with GNU tar an archive created with BSD tar (probably on macOS)
		EXTRA_TAR_PARAMS=""
		tar --version | grep -qi 'gnu' && EXTRA_TAR_PARAMS="--warning=no-unknown-keyword --ignore-zeros"

		ok=1
		if [[ ! -d "tests-slashing-${version}" ]]; then
			for flavour in "${FLAVOURS[@]}"; do
				echo "Unpacking: slashing-${version}/${flavour}.tar.gz"
				mkdir -p "tests-slashing-${version}"
				tar -C "tests-slashing-${version}" --strip-components 1 ${EXTRA_TAR_PARAMS} -xzf \
					"tarballs/slashing-${version}/${flavour}.tar.gz" \
					|| {
						rm -rf "tests-slashing-${version}" "tarballs/slashing-${version}/${flavour}.tar.gz"
						ok=0
					}
			done
		fi
	done
	if (( !ok )); then
		echo "Unpacking failed too often. Aborting."
		exit 1
	fi
}

# download and unpack
for version in "${VERSIONS[@]}"; do
	unpack_version "$version"
done

# delete tarballs and unpacked data from old versions
for tpath in tarballs/slashing-*; do
	tdir="$(basename "$tpath")"
	if [[ ! " slashing-${VERSIONS[@]} " =~ " $tdir " ]]; then
		rm -rf "$tpath"
	fi
done
for tpath in tests-slashing-*; do
	tver="$(echo "$tpath" | sed -e's/^tests-slashing-//')"
	if [[ ! " ${VERSIONS[@]} " =~ " $tver " ]]; then
		rm -rf "$tpath"
	fi
done
