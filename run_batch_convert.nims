#!/usr/bin/env nim

import
  ospaths, strformat

let nimbusDir = getEnv "NIMBUS_ENV_DIR"
if nimbusDir.len == 0:
  echo "This script must be executed in the Nimbus build environment"
  quit 1

let patchesDir = thisDir() / "patches"

proc applyPatch(submoduleName: string) =
  let
    fullPatchPath = patchesDir / submoduleName & ".patch"
    submoduleDir = nimbusDir / "vendor" / submoduleName

  cd submoduleDir
  exec &"""git apply "{fullPatchPath}" """

proc revertPatch(submoduleName: string) =
  cd nimbusDir / "vendor" / submoduleName
  exec "git reset --hard HEAD"

try:
  cd thisDir() / "eth2.0-spec-tests"
  exec "git lfs fetch"
  exec "git lfs checkout"

  applyPatch "Nim"
  applyPatch "NimYAML"

  cd thisDir()
  exec "nim c -r batch_convert.nim"

finally:
  revertPatch "Nim"
  revertPatch "NimYAML"

