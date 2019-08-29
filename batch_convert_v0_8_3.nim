import
  # Standard library
  ospaths, json, os,
  # Utilities
  ./fixtures_utils

# This requires Nim 0.20.x for walkDirRec
# and `nimble install yaml@#devel` for 0.20.x compat

const yamlPath = "eth2.0-spec-tests"/"tests"
const jsonPath = "json_tests_v0.8.3"

const InOut = [
  # Format:
  #   - Path to a folder.
  #     yaml files inside will be recursively converted
  #     preserving the directory structure
  "general"/"phase0"/"bls",
  "mainnet"/"phase0"/"shuffling"
]

proc main() =
  for path in InOut:
    for file in walkDirRec(yamlPath/path, relative = true):
      echo "Processing: ", file
      let (subpath, filename, ext) = splitFile(file)
      doAssert ext == ".yaml", "This expects small pure YAML tests"
      let inFile = yamlPath/path/subpath/filename & ".yaml"
      let outFile = jsonPath/path/subpath/filename & ".json"

      let jsonString = pretty(yamlToJson(inFile)[0])

      createDir(jsonPath/path/subpath)
      writeFile(outFile, jsonString)

  echo "Finished"

when isMainModule:
  main()
