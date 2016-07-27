#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Log aws-cli API calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

output_jq() {
  local default=$(cat <<EOS
    [
      .Id,
      .Name,
      (.ResourceRecordSetCount | tostring),
      (if .Config.PrivateZone then "Private" else "Public" end),
      .Config.Commend
    ] | join("\t")
EOS
  )
  jq -r ".HostedZones | sort_by(.Config.PrivateZone) | .[] | ${FLAGS_jq:-$default}"
}

aws route53 list-hosted-zones \
  | output_jq
