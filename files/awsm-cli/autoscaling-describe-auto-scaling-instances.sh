#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region(s)' 'r'
DEFINE_string  'auto-scaling-group-names' '' 'ASG name(s) to look up' 'a'
DEFINE_string  'instance-ids' '' 'EC2 instance ids' 'i'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

instance_ids() {
  local region="$1"
  local input="$2"

  echo "${FLAGS_instance_ids:-$(extract "i" $region <<< "$input")}"
}

instance_ids_clause() {
  local instance_ids="$1"

  echo_if_not_blank "${FLAGS_instance_ids:-$(string.join "," <<< "$instance_ids")}" "--instance-ids ${FLAGS_instance_ids:-$(string.join "," <<< "$instance_ids")}"
}

output_jq() {
  local region="$1"
  local default="$(cat <<EOS
    [
      \$region,
      .AvailabilityZone,
      .InstanceId,
      .HealthStatus,
      .LifecycleState,
      .AutoScalingGroupName,
      .LaunchConfigurationName // "n/a"
    ] | join("\t")
EOS
  )"

  jq -r --arg region $region ".AutoScalingInstances[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region ZoneName InstanceId HealthStatus LifecycleState AutoScalingGroupName LaunchConfigurationName"
env_parallel -I '{region}' \
             -k 'env_parallel -I "{ids}" -N 50 aws autoscaling --region {region} describe-auto-scaling-instances $(instance_ids_clause {ids}) ::: $(instance_ids {region} "$INPUT") | output_jq {region}' \
             ::: ${FLAGS_region:-$(extract "region" <<< "$INPUT")}
