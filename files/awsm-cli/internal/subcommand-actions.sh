#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/../vendor/shflags/src/shflags
DEFINE_string  'subcommand' '' 'Any awsm-cli recognized subcommand (i.e. awsm <subcommand>)' 's'
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail

[ -z "$FLAGS_subcommand" ] || {
  find $DIR/.. -maxdepth 1 \
               -type f \
               -name "*.sh" \
               ! -name "_common*.sh" \
               -exec basename {} '.sh' \; \
    | grep -Fw "$FLAGS_subcommand" \
    | cut -d '-' -f 2- \
    | sort -u
}
