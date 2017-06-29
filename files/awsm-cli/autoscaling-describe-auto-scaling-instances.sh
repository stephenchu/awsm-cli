#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: autoscaling-describe-auto-scaling-instances [-r <region>...] [-i <instance-id>...] [options]

Options:
    -r --region=<region>...                 AWS region(s) in which the autoscaling group instance(s) are in [required: as argument or stdin]
    -i --instance-id=<instance-id>...       AWS instance-id(s) to describe
    --help                                  Show help options

Other Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied
    --log-awscli                           Logs every awscli command line runs to stderr [default: false]
    --log-jq                               Logs every jq command runs to stderr          [default: false]
EOF
)"

aws:instance_ids() {
  echo_if_not_blank "$(string.join "," <<< "$1")" "--instance-ids $(string.join "," <<< "$1")"
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
      .LaunchConfigurationName
    ] | join("\t")
EOS
  )"

  jq -r --arg region $region ".AutoScalingInstances[] | ${jq:-$default}"
}

INPUT="$(stdin:aws-regional-input)"
output:headers "Region ZoneName InstanceId HealthStatus LifecycleState AutoScalingGroupName LaunchConfigurationName"
env_parallel -I '{region}' \
             -k 'env_parallel -I "{ids_batch}" -N 50 aws autoscaling --region {region} describe-auto-scaling-instances $(aws:instance_ids {ids_batch}) ::: ${instance_ids[@]:-$(stdin:extract "i" {region} <<< "$INPUT")} | output_jq {region}' \
             ::: ${region[@]:-$(stdin:extract "region" <<< "$INPUT")}
