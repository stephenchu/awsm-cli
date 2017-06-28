#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: ec2-describe-availability-zones [-r <region>...] [-z <availability-zone>...] [options]

Options:
    -r --region=<region>...                AWS region(s) to describe the availability zones for [required: as argument or stdin]
    -z --availability-zone=<zone>...       AWS availability zone(s) to describe
    -f --filter=<filter>...                Passed as-is to the \`--filters\` option in awscli command
    --help                                 Show help options

Other Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied  [default: [\$region, .ZoneName] | join("\\t")]
    --log-awscli                           Logs every awscli command line runs to stderr [default: false]
    --log-jq                               Logs every jq command runs to stderr          [default: false]
EOF
)"

aws:filters() {
  local region="$1"
  local input="$2"
  local filter_values=""

  local zones="${availability_zone[@]:-$(stdin:extract "az" $region <<< "$input")}"

  [ -z "$(string.join " " <<< "${filter[@]}")" ] || filter_values="$filter_values $(string.join " " <<< "${filter[@]}")"
  [ -z "$(string.join "," <<< "$zones")" ]       || filter_values="$filter_values Name=zone-name,Values=$(string.join "," <<< "$zones")"

  echo_if_not_blank "$filter_values" "--filters ${filter_values}"
}

output:jq() {
  local region="$1"
  jq -r --arg region $region ".AvailabilityZones[] | $jq"
}

INPUT="$(stdin:aws-regional-input)"
output:headers "Region ZoneName"
env_parallel 'aws ec2 --region {} describe-availability-zones $(aws:filters {} "$INPUT") | output:jq {}' ::: ${region[@]:-$(stdin:extract "region" <<< "$INPUT")}
