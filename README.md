# nim-eth2-official-tests

This repo reformats the official Ethereum 2 tests to a format suitable for [Nimbus](https://github.com/status-im/nimbus)/[nim-beacon-chain](https://github.com/status-im/nim-beacon-chain).

This repository is meant to be submoduled in `nim-beacon-chain/tests/official/` with the `fixtures` name.

From the nim-beacon-chain project folder:

```sh
git submodule add https://github.com/status-im/nim-eth2-official-tests ./tests/official/fixtures
```


This repository allows use to workaround the current following limitations:
  - no YAML support in [nim-serialization](https://github.com/status-im/nim-serialization) library
    which allows well-tested serialization and deserialization into and from Ethereum types.
  - [NimYAML](https://nimyaml.org) uses int by default for numerals and cannot deserialize
    18446744073709551615 (2^64-1), the FAR_FUTURE_SLOT constant.
  - Eth2.0 tests currently uses an invalid BLS signature https://github.com/ethereum/eth2.0-tests/issues/27
  - All those workarounds requires an intermediate reformatted JSON file, but the tests are huge (100k+ lines)
    and will cause review issues in the main repo.

Only state tests are worked on at the moment.

## State tests conversion.

Note on serialization hacks:

### FAR_FUTURE_SLOT (18446744073709551615)

The FAR_FUTURE_SLOT (18446744073709551615) has been rewritten as a string **in the YAML file**
as it's 2^64-1 and Nim by default try to parse it into a int64 (which can represents up to 2^63-1).

The YAML file is then converted to JSON for easy input to the json serialization/deserialization
with beacon chain type support.

"18446744073709551615" is then replaced again by uint64 18446744073709551615.

### Compressed signature

In `latest_block_header` field, the signatures and randao_reveals are
`"0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"`
but that is not a valid compressed BLS signature, the zero signature should be:
`"0xc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"`

### Commands

Example commands to generate the tests and apply the proper workarounds on UNIX systems.
To be used from this repo root directory.
Please double-check the commands.

```sh
# Out of place replace
sed 's/18446744073709551615/"18446744073709551615"/g' eth2.0-tests/state/sanity-check_default-config_100-vals.yaml > json_tests/state/sanity-check_default-config_100-vals.yaml
# Create Nim build directory if it doesn't exist
mkdir -p build
# Compile conversion utility
nim c -r -o:build/yamlToJson fixtures_utils.nim # Will convert "json_tests/state/sanity-check_default-config_100-vals-first_test.yaml" by default
# In-place replaces
sed -i 's/"18446744073709551615"/18446744073709551615/g' json_tests/state/sanity-check_default-config_100-vals.json
sed -i 's/"randao_reveal":"0x00000000/"randao_reveal":"0xc0000000/g' json_tests/state/sanity-check_default-config_100-vals.json
sed -i 's/"signature":"0x00000000/"signature":"0xc0000000/g' json_tests/state/sanity-check_default-config_100-vals.json
sed -i 's/"proof_of_possession":"0x00000000/"proof_of_possession":"0xc0000000/g' json_tests/state/sanity-check_default-config_100-vals.json
sed -i 's/"aggregate_signature":"0x00000000/"aggregate_signature":"0xc0000000/g' json_tests/state/sanity-check_default-config_100-vals.json
# Interactive delete
rm -i json_tests/state/sanity-check_default-config_100-vals.yaml
```