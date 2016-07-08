#! /bin/bash

set -euo pipefail

option_if_not_blank() {
  local value_to_check="$1"
  local value_to_return="$2"

  if [ ! -z "$value_to_check" ]; then
    echo "$value_to_return"
  fi
}
