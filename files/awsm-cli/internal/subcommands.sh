#! /bin/bash

set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWSCLI_SCRIPTS_DIR="$DIR/.."

printf "_\n"
find "$AWSCLI_SCRIPTS_DIR" -maxdepth 1 \
                      -type f \
                      -name "*.sh" \
                      ! -name "_common*.sh" \
                      -exec basename {} \; \
  | cut -d '-' -f 1 \
  | sort -u
  
