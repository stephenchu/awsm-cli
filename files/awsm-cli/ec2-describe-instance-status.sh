#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region' 'r'
DEFINE_string  'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-instance-ids' '' 'EC2 instance ids' 'i'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

filters() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_filters}" ]                                                  || filters="$filters $FLAGS_filters"
  [ -z "${FLAGS_filter_instance_ids:-$(extract "i" $region <<< "$input")}" ] || filters="$filters Name=instance-id,Values=${FLAGS_filter_instance_ids:-$(extract "i" $region <<< "$input" | string.join ",")}"

  echo_if_not_blank "$filters" "--filters ${filters}"
}


output_jq() {
  local region="$1"
  local default="[
      \$region,
      .AvailabilityZone,
      .InstanceId,
      .InstanceState.Name,
      .SystemStatus.Status,
      .InstanceStatus.Status
    ] | join(\"\t\")"
  jq -r --arg region $region ".InstanceStatuses[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region AvailabilityZone InstanceId InstanceState SystemStatus InstanceStatus"
env_parallel -k 'aws ec2 --region {} describe-instance-status $(filters {}) | output_jq {}' ::: ${FLAGS_region:-$(extract "region" <<< "$INPUT")}

