#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: autoscaling-describe-auto-scaling-groups [-r <region>...] [(-v <vpc-id>... | -s <subnet-id>...)] [options]

Options:
    -r --region=<region>...                 AWS region(s) in which the autoscaling group(s) are in [required: as argument or stdin]
    -n --auto-scaling-group-name=<name>...  AWS auto-scaling-group-name(s) to describe
    -v --vpc-id=<vpc-id>...                 AWS vpc-id(s) for the autoscaling group(s)' subnets are under. A shorthand to include all of the vpc(s)' subnet-id(s)
    -s --subnet-id=<subnet-id>...           AWS subnet-id(s) for the autoscaling group(s)
    -t --tag=<tag>...                       Any additional resource tags to display in the output
    --help                                  Show help options

Other Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied
    --log-awscli                           Logs every awscli command line runs to stderr [default: false]
    --log-jq                               Logs every jq command runs to stderr          [default: false]
EOF
)"

aws:auto_scaling_group_names() {
  echo_if_not_blank "${auto_scaling_group_name[@]}" "--auto-scaling-group-names ${auto_scaling_group_name[@]}"
}

jq:filter() {
  local region="$1"
  local input="$2"
  local filter_values=""

  local vpc_ids="${vpc_id[@]:-$(stdin:extract "vpc" $region <<< "$input")}"
  local subnet_ids="${subnet_id[@]:-$(stdin:extract "subnet" $region <<< "$input")}"

  [ -z "$vpc_ids" ] || {
    local vpc_subnet_ids_input="$($DIR/ec2-describe-subnets.sh --region $region --vpc-id "$vpc_ids" < /dev/null | stdin:aws-regional-input)"
    subnet_ids="$(stdin:extract "subnet" $region <<< "$vpc_subnet_ids_input")"
    subnet_ids="${subnet_ids:-"no-subnets-found-in-${vpc_ids}"}"
  }

  [ -z "$subnet_ids" ] || {
    filter_values+=" | ($(json.to_array <<< "$subnet_ids")) as \$vpc_subnets"
    filter_values+=' |
      map(
        select(
          (.VPCZoneIdentifier | split(",")) as $asg_subnets | ($vpc_subnets | contains($asg_subnets))
        )
      )
    '
  }

  echo_if_not_blank "$filter_values" "$filter_values"
}

output:jq() {
  local region="$1"
  local default=$(cat <<EOS
    [
      \$region,
      .AutoScalingGroupName,
      .LaunchConfigurationName,
      (.AvailabilityZones | join(",")),
      .VPCZoneIdentifier,
      (.MinSize | tostring),
      (.MaxSize | tostring),
      (.DesiredCapacity | tostring),
      .CreatedTime,
      $(output.tags "${tag[@]}"),
      (.Instances | map(.InstanceId) | join("\t"))
    ] | join("\t")
EOS
  )

  jq -r --arg region $region ".AutoScalingGroups $(jq:filter $region "$INPUT")" \
    | jq -L $DIR/jq -r --arg region $region "include \"aws\"; .[] | ${jq:-$default}"
}

INPUT="$(stdin:aws-regional-input)"
output:headers "Region AutoScalingGroupName LaunchConfigurationName ZoneName VPCZoneIdentifier MinSize MaxSize DesiredCapacity CreatedTime $(headers.tags "${tag[@]}") Instances..."
env_parallel -k 'aws autoscaling --region {} describe-auto-scaling-groups $(aws:auto_scaling_group_names) | output:jq {}' ::: ${region[@]:-$(stdin:extract "region" <<< "$INPUT")}
