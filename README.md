# nim-eth2-official-tests

This repo reformats the official Ethereum 2 tests to a format suitable for [Nimbus](https://github.com/status-im/nimbus)/[nim-beacon-chain](https://github.com/status-im/nim-beacon-chain).

## Cloning the repo

Due to upstream usage of [Git LFS](https://git-lfs.github.com) to store the large test vectors,
there is an extra step after cloning the repo:

```
git clone https://github.com/status-im/nim-eth2-official-tests
cd nim-eth2-official-tests
git lfs install
git submodule update --init --recursive
```

## Usage in nim-beacon-chain

This repository is meant to be used in the devel branch of the [Nimbus build environment](https://github.com/status-im/nimbus)
where it appears as a submodule in `nimbus/vendor/nim-beacon-chain/tests/official/fixtures`.

This repository contains patches to Nim and NimYAML created to work around a number of outstanding issues:
  - no YAML support in [nim-serialization](https://github.com/status-im/nim-serialization) library
    which allows well-tested serialization and deserialization into and from Ethereum types.
  - [NimYAML](https://nimyaml.org) uses int by default for numerals and cannot deserialize
    18446744073709551615 (2^64-1), the FAR_FUTURE_SLOT constant.
  - Furthermore as of 0.7.1, the yaml test files includes thousands of random epochs
    in the [2^63-1 .. 2^64-1] range for the `source_epoch` and `target_epoch` field.
  - All those workarounds requires an intermediate reformatted JSON file, but the tests are huge (100k+ lines)
    and will cause review issues in the main repo.

The required patch application is automated in the `run_batch_convert.nims` script. After executing it, you'll find all
converted test vectors in the `json_tests` folder.

