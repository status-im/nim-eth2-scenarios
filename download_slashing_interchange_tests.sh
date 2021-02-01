#!/bin/bash

set -eu

VERSIONS=(
  "v5.0.0"
)
FLAVOURS=(
  "eip-3076-tests-v5.0.0"
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
			curl --location --remote-name --show-error \
				"https://github.com/eth2-clients/slashing-protection-interchange-tests/releases/download/${version}/${flavour}.tar.gz" \
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

	if [[ ! -d "tests-slashing-${version}" ]]; then
		for flavour in "${FLAVOURS[@]}"; do
			echo "Unpacking: slashing-${version}/${flavour}.tar.gz"
			mkdir -p "tests-slashing-${version}"
			tar -C "tests-slashing-${version}" --strip-components 1 ${EXTRA_TAR_PARAMS} -xzf \
				"tarballs/slashing-${version}/${flavour}.tar.gz" \
				|| {
					echo "Tar failed. Aborting."
				  rm -rf "tests-slashing-${version}"
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
for tpath in tarballs/slashing-*; do
	tdir="$(basename "$tpath")"
	if [[ ! " ${VERSIONS[@]} " =~ " $tdir " ]]; then
		rm -rf "$tpath"
	fi
done
for tpath in tests-slashing-*; do
	tver="$(echo "$tpath" | sed -e's/^tests-slashing-//')"
	if [[ ! " ${VERSIONS[@]} " =~ " $tver " ]]; then
		rm -rf "$tpath"
	fi
done
