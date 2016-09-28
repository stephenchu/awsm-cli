#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_string  'hosted-zone-id' '' 'Route53 hosted zone id' 'z'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Log aws-cli API calls' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

jq_filters() {
  local filters=""

  [ -z "${FLAGS_hosted_zone_id}" ] || filters="$filters | map(select(.Id == \"${FLAGS_hosted_zone_id}\" ))"

  echo_if_not_blank "$filters" "$filters"
}

output_jq() {
  local default=$(cat <<EOS
    [
      .Id,
      .Name,
      (.ResourceRecordSetCount | tostring),
      (if .Config.PrivateZone then "Private" else "Public" end),
      .Config.Comment
    ] | join("\t")
EOS
  )
  jq -r ".HostedZones $(jq_filters) | sort_by(.Config.PrivateZone) | .[] | ${FLAGS_jq:-$default}"
}

headers "HostedZoneId Name ResourceRecordSetCount Public/Private Comment"
aws route53 list-hosted-zones \
  | output_jq
