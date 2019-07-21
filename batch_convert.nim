import
  # Standard library
  ospaths, json,
  # Utilities
  ./fixtures_utils

# Note state tests are not included as they need preprocessing
# see README.md

const yamlPath = "eth2.0-spec-tests"/"tests"
const jsonPath = "json_tests"

const InOut = [
  # Format:
  #   - Path without the "yamlPath" prefixed
  #     and without the yaml/json suffix
  #   - in lexicographical order
  "bls"/"aggregate_pubkeys"/"aggregate_pubkeys",
  "bls"/"aggregate_sigs"/"aggregate_sigs",
  "bls"/"msg_hash_g2_compressed"/"g2_compressed",
  "bls"/"priv_to_pub"/"priv_to_pub",
  "bls"/"sign_msg"/"sign_msg",
  # "operations"/"deposit"/"deposit_mainnet",
  # "operations"/"deposit"/"deposit_minimal",
  "shuffling"/"core"/"shuffling_full",
  "shuffling"/"core"/"shuffling_minimal",
  "ssz_generic"/"uint"/"uint_bounds",
  "ssz_generic"/"uint"/"uint_random",
  "ssz_generic"/"uint"/"uint_wrong_length",
  "ssz_static"/"core"/"ssz_mainnet_random",
  "ssz_static"/"core"/"ssz_minimal_lengthy",
  "ssz_static"/"core"/"ssz_minimal_max",
  "ssz_static"/"core"/"ssz_minimal_nil",
  "ssz_static"/"core"/"ssz_minimal_one",
  "ssz_static"/"core"/"ssz_minimal_random_chaos",
  "ssz_static"/"core"/"ssz_minimal_random",
  "ssz_static"/"core"/"ssz_minimal_zero",
]

proc main() =
  for path in InOut:
    let inFile = yamlPath / path & ".yaml"
    let outFile = jsonPath / path & ".json"

    let jsonString = pretty(yamlToJson(inFile)[0])
    writeFile(outFile, jsonString)

when isMainModule:
  main()
