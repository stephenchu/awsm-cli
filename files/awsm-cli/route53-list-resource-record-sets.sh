#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'hosted-zone-id' '' 'Route53 hosted zone id' 'z'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Log aws-cli API calls' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

hosted_zone_id() {
  local hosted_zone_id="$1"
  local filters=""

  [ -z "${FLAGS_hosted_zone_id:-$hosted_zone_id}" ] || filters="$filters ${FLAGS_hosted_zone_id:-$hosted_zone_id}"

  echo_if_not_blank "$filters" "--hosted-zone-id $filters"
}

output_jq() {
  local hosted_zone_id="$1"
  local default=$(cat <<EOS
    [
      \$hosted_zone_id,
      .Name,
      .Type,
      (.TTL // empty | tostring),
      (.ResourceRecords | values | map(.Value) | values | join(","))
    ] | sort_by(.Name) | join("\t")
EOS
  )
  jq -r --arg hosted_zone_id $hosted_zone_id ".ResourceRecordSets[] | ${FLAGS_jq:-$default}"
}


INPUT=$(script_input_with_hosted_zone_id)
headers "HostedZoneId Name Type TTL Value"
env_parallel -k 'aws route53 list-resource-record-sets $(hosted_zone_id {}) | output_jq {}' ::: ${FLAGS_hosted_zone_id:-$(extract "hostedzone" <<< "$INPUT")}
