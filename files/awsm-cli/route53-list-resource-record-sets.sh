#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'hosted-zone-id' '' 'Route53 hosted zone id' 'z'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Log aws-cli API calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

set -euo pipefail
source $DIR/_common_all.sh

hosted_zone_id() {
  local hosted_zone_id="$1"
  option_if_not_blank "$hosted_zone_id" "--hosted-zone-id $hosted_zone_id"
}

output_jq() {
  local hosted_zone_id="$1"
  local default=$(cat <<EOS
    [
      \$hosted_zone_id,
      .Name,
      .Type,
      (.TTL // empty | tostring),
      (.ResourceRecords | values | map(.Value) | values | join("\t"))
    ] | sort_by(.Name) | join("\t")
EOS
  )
  jq -r --arg hosted_zone_id $hosted_zone_id ".ResourceRecordSets[] | ${FLAGS_jq:-$default}"
}


INPUT=$(script_input_with_hosted_zone_id)
for hosted_zone_id in ${FLAGS_hosted_zone_id:-$(extract "hostedzone" <<< "$INPUT")}; do
  aws route53 list-resource-record-sets $(hosted_zone_id $hosted_zone_id) \
    | output_jq $hosted_zone_id
done
