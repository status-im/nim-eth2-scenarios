#!/bin/bash

set -eu

source scripts/download_functions.sh

dl_version v0.8.3
dl_version v0.9.0

echo "Ignore the warnings \"unknown extended header keyword 'SCHILY.{dev,ino,nlink}'\" on Linux."
# tar: Ignoring unknown extended header keyword 'SCHILY.dev'
# tar: Ignoring unknown extended header keyword 'SCHILY.ino'
# tar: Ignoring unknown extended header keyword 'SCHILY.nlink'
echo "Those are due to the test vectors being packed with OSX BSD tar."

unpack_version v0.8.3
unpack_version v0.9.0
