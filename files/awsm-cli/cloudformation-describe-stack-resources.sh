#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region(s)' 'r'
DEFINE_string  'stack-name-or-arn' '' 'Stack name or ARN id' 'a'
DEFINE_string  'physical-resource-id' '' 'Physical resource id' 'p'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

set -euo pipefail
source $DIR/_common_all.sh

filter_stack_name() {
  local region="$1"
  local input="$2"
  local filters=""

  local stack_name_or_arn="${FLAGS_stack_name_or_arn:-$(extract "cloudformation" $region <<< "$input")}"
  [ -z "$stack_name_or_arn" ] || filters="--stack-name '$(awk '{ print $1 }' <<< "$stack_name_or_arn")'"
  [ -z "$stack_name_or_arn" ] && [ ! -z "$FLAGS_physical_resource_id" ] && filters="--physical-resource-id ${FLAGS_physical_resource_id}"

  option_if_not_blank "$filters" "$filters"
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    [
      \$region,
      .StackName,
      .ResourceStatus,
      .ResourceType,
      .Timestamp,
      .PhysicalResourceId,
      .LogicalResourceId
    ] | sort_by(.Timestamp) | join("\t")
EOS
  )

  jq -r --arg region $region ".StackResources[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws cloudformation --region $region describe-stack-resources $(filter_stack_name $region "$INPUT") \
    | output_jq $region
done
