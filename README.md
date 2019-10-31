# nim-eth2-official-tests

This repo used to reformat the official Ethereum 2 tests to a format suitable for [Nimbus](https://github.com/status-im/nimbus)/[nim-beacon-chain](https://github.com/status-im/nim-beacon-chain).

Currently it is used for:

- Having multiple test vectors versions side-by-side for progressive update between spec versions
- SSZ test vectors that are still using a JSON format from 0.8.1.
- SSZ test vectors in JSON that require LFS

## Cloning the repo

### Git LFS (Large File Storage)

You need git-lfs installed to clone the JSON test vectors
```
git lfs install
```
Afterwards any `git clone` will also do the required `git lfs pull` implicitly

It you do not want to download the LFS files, export the following variable before `git clone`:
```
export GIT_LFS_SKIP_SMUDGE=1
```

### Cloning and downloading the official test vectors

After cloning the repo, you will need to download the official test vectors.
This is done via the `download_test_vectors.sh` script.

```bash
git clone https://github.com/status-im/nim-eth2-official-tests
cd nim-eth2-official-tests

# Download versioned test vectors
./download_test_vectors.sh
```

