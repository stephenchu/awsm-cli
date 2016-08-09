#! /bin/bash

set -euo pipefail

echo_if_not_blank() {
  [ -z "$1" ] || echo "$2"
}
