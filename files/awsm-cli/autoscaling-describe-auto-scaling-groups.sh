#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region(s)' 'r'
DEFINE_string  'auto-scaling-group-names' '' 'ASG name(s) to look up' 'a'
DEFINE_string  'filter-vpc-id' '' 'VPC Id' 'v'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

set -euo pipefail
source $DIR/_common_all.sh

auto_scaling_group_names() {
  option_if_not_blank "$FLAGS_auto_scaling_group_names" "--auto-scaling-group-names $FLAGS_auto_scaling_group_names"
}


jq_filters() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_filter_vpc_id:-$(extract "vpc" $region <<< "$input")}" ] || {
    local vpc_ids="${FLAGS_filter_vpc_id:-$(extract "vpc" $region <<< "$input")}"
    local subnet_ids=$(extract "subnet" $region <<< "$($DIR/ec2-describe-subnets.sh -r $region -v "$vpc_ids" < /dev/null | script_input)")

    filters="$filters | ($(echo "$subnet_ids" | xargs jo -a)) as \$vpc_subnets | map(select(  (.VPCZoneIdentifier | split(\",\")) as \$asg_subnets | ( \$vpc_subnets | contains(\$asg_subnets) )  ))"
  }
  [ -z "$(extract "subnet" $region <<< "$input")" ] || filters="$filters | ($(extract "subnet" $region <<< "$input" | xargs jo -a)) as \$vpc_subnets | map(select(  (.VPCZoneIdentifier | split(\",\")) as \$asg_subnets | ( \$vpc_subnets | contains(\$asg_subnets) )  ))"

  option_if_not_blank "$filters" "$filters"
}

output_jq() {
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
      (.Instances | map(.InstanceId) | join("\t"))
    ] | join("\t")
EOS
  )

  jq -r --arg region $region ".AutoScalingGroups $(jq_filters $region "$INPUT")" \
    | jq -C -r --arg region $region ".[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws autoscaling --region $region describe-auto-scaling-groups $(auto_scaling_group_names) \
    | output_jq $region
done
