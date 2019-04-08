# beacon_chain
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  # Standard lib
  json, streams,
  # Dependencies
  yaml.tojson

# #######################
# Yaml to JSON conversion

proc yamlToJson*(file: string): seq[JsonNode] =
  try:
    let fs = openFileStream(file)
    defer: fs.close()
    result = fs.loadToJson()
  except IOError:
    echo "Exception when reading file: " & file
    raise
  except OverflowError:
    echo "Overflow exception when parsing. Did you stringify 18446744073709551615 (-1)?"
    raise

when isMainModule:
  # Do not forget to stringify FAR_EPOCH_SLOT = 18446744073709551615 (-1) in the YAML file
  # And unstringify it in the produced JSON file

  import os, typetraits

  const
    # TODO: consume the whole YAML test and not just the first test
    DefaultYML = "json_tests/state/sanity-check_default-config_100-vals.yaml"
    DefaultOutputPath = "json_tests/state/sanity-check_default-config_100-vals.json"

  var fileName, outputPath: string
  if paramCount() == 0:
    fileName = DefaultYML
    outputPath = DefaultOutputPath
  elif paramCount() == 1:
    fileName = paramStr(1)
    outputPath = DefaultOutputPath
  elif paramCount() >= 2:
    fileName = paramStr(1)
    outputPath = paramStr(2)

  let jsonString = $DefaultYML.yamlToJson[0]
  DefaultOutputPath.writeFile jsonString

