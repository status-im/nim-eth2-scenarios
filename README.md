# nim-eth2-official-tests

This repo used to reformat the official Ethereum 2 tests to a format suitable for [Nimbus](https://github.com/status-im/nimbus)/[nim-beacon-chain](https://github.com/status-im/nim-beacon-chain).

Currently it is used for:

- Having multiple test vectors versions side-by-side for progressive update between spec versions
- SSZ test vectors are still using a json format from 0.8.1.
- SSZ test vectors in json requires LFS

## Cloning the repo

Due to usage of [Git LFS](https://git-lfs.github.com) to store the large SSZ v0.8.1 test vectors,
there is an extra step after cloning the repo:

```bash
git clone https://github.com/status-im/nim-eth2-official-tests
cd nim-eth2-official-tests

# Download versionned test vectors
# TODO

# SSZ v0.8.1 test vectors
git lfs install
git submodule update --init --recursive
```
