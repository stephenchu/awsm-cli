#! /bin/bash

set -euo pipefail

STDIN="$(cat /dev/stdin)"

if [[ "${STDIN:0:1}" =~ [[:upper:]] ]]; then
  (read -r; printf "%s\n" "$REPLY"; exec sort --field-separator $'\t' "$@")
else
  exec sort "$@"
fi <<< "$STDIN"
