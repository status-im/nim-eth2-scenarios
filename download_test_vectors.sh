#!/bin/bash

set -eu

VERSIONS=(
  "v1.0.1"
  "v1.1.0-alpha.2"
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
			curl --location --remote-name --silent --show-error \
				"https://github.com/ethereum/eth2.0-spec-tests/releases/download/${version}/${flavour}.tar.gz" \
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

	dl_version "$version"

	# suppress warnings when unpacking with GNU tar an archive created with BSD tar (probably on macOS)
	EXTRA_TAR_PARAMS=""
	tar --version | grep -qi 'gnu' && EXTRA_TAR_PARAMS="--warning=no-unknown-keyword --ignore-zeros"

	if [[ ! -d "tests-${version}" ]]; then
		for flavour in "${FLAVOURS[@]}"; do
			echo "Unpacking: ${version}/${flavour}.tar.gz"
			mkdir -p "tests-${version}"
			tar -C "tests-${version}" --strip-components 1 ${EXTRA_TAR_PARAMS} --exclude=phase1 -xzf \
				"tarballs/${version}/${flavour}.tar.gz" \
				|| {
					echo "Tar failed. Aborting."
					rm -rf "tests-${version}"
					exit 1
				}
		done
	fi
}

# download and unpack
for version in "${VERSIONS[@]}"; do
	unpack_version "$version"
done

# delete tarballs and unpacked data from old versions
for tpath in tarballs/*; do
	tdir="$(basename "$tpath")"
	if [[ ! " ${VERSIONS[@]} " =~ " $tdir " ]]; then
		rm -rf "$tpath"
	fi
done
for tpath in tests-*; do
	tver="$(echo "$tpath" | sed -e's/^tests-//')"
	if [[ ! " ${VERSIONS[@]} " =~ " $tver " ]]; then
		rm -rf "$tpath"
	fi
done
