#! /bin/bash

set -euo pipefail

headers() {
  [ ! -z "$FLAGS_jq" ] || string.join "\t" <<< "$1"
}

echo_if_not_blank() {
  [ -z "$1" ] || echo "$2"
}
