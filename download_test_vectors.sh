#!/usr/bin/env bash

# Copyright (c) 2019-2023 Status Research & Development GmbH. Licensed under
# either of:
# - Apache License, version 2.0
# - MIT license
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

set -eu

VERSIONS=(
  "v1.4.0-beta.2-hotfix"
)
FLAVOURS=(
  "general"
  "minimal"
  "mainnet"
)

# signal handler (we only care about the Ctrl+C generated SIGINT)
REL_PATH="$(dirname "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd "${REL_PATH}"; pwd)"
cleanup() {
	echo -e "\nCtrl+C pressed. Cleaning up."
	cd "$ABS_PATH"
	rm -rf tarballs tests-*
	exit 1
}
trap cleanup SIGINT

dl_version() {
	[[ -z "$1" ]] && { echo "usage: dl_version() vX.Y.Z"; exit 1; }
	version="$1"

	mkdir -p "tarballs/${version}"
	pushd "tarballs/${version}" >/dev/null
	for flavour in "${FLAVOURS[@]}"; do
		if [[ ! -e "${flavour}.tar.gz" ]]; then
			echo "Downloading: ${version}/${flavour}.tar.gz"
			curl --location --remote-name --silent --show-error --retry 3 --retry-connrefused \
				"https://github.com/ethereum/consensus-spec-tests/releases/download/${version}/${flavour}.tar.gz" \
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
		if [[ ! -d "tests-${version}" ]]; then
			for flavour in "${FLAVOURS[@]}"; do
				echo "Unpacking: ${version}/${flavour}.tar.gz"
				mkdir -p "tests-${version}"
				tar -C "tests-${version}" --strip-components 1 ${EXTRA_TAR_PARAMS} --exclude=phase1 -xzf \
					"tarballs/${version}/${flavour}.tar.gz" \
					|| {
						rm -rf "tests-${version}" "tarballs/${version}/${flavour}.tar.gz"
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
for tpath in tarballs/*; do
	if [[ "$tpath" == "tarballs/slashing-"* ]]; then
		continue  # avoid interfering with slashing interchange tests
	fi
	tdir="$(basename "$tpath")"
	if [[ ! " ${VERSIONS[@]} " =~ " $tdir " ]]; then
		rm -rf "$tpath"
	fi
done
for tpath in tests-*; do
	if [[ "$tpath" == "tests-slashing-"* ]]; then
		continue  # avoid interfering with slashing interchange tests
	fi
	tver="$(echo "$tpath" | sed -e's/^tests-//')"
	if [[ ! " ${VERSIONS[@]} " =~ " $tver " ]]; then
		rm -rf "$tpath"
	fi
done
