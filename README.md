# ETH 2 Scenarios

This repo holds Ethereum 2 scenarios of particular interest for [Nimbus Eth2](https://github.com/status-im/nimbus-eth2)

At the moment it contains:
- A test vector downloader for [Ethereum 2.0 specs](https://github.com/ethereum/eth2.0-specs)

Future plans include:
- Bugs arising from usage or fuzzing
- Benchmark scenarios in particular those that might trigger degenerate cases

## Cloning the repo

### Cloning and downloading the official test vectors

After cloning the repo, you will need to download the official test vectors.
This is done via the `download_test_vectors.sh` script.

```bash
git clone https://github.com/status-im/nim-eth2-scenarios
cd nim-eth2-scenarios

# Download versioned test vectors
./download_test_vectors.sh
```
