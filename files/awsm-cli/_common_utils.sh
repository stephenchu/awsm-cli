#! /bin/bash

### String Functions
string.join() {
  local delimiter="${1:-" "}"
  sed "s/ /${delimiter}/g"
}

string.strip() {
  xargs <<< "${1}"
}

### JSON Functions
json.to_array() {
  local input=$(cat /dev/stdin)
  local field_separator="${2:- }"
  jq --null-input --arg input "$input" --arg separator "$field_separator" '$input | split($separator)'
}
