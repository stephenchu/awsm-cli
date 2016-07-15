#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region(s)' 'r'
DEFINE_string  'stack-name-or-arn' '' 'Stack name or ARN id' 'a'
DEFINE_string  'filter-vpc-id' '' 'VPC Id' 'v'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

set -euo pipefail
source $DIR/_common_all.sh

stack_name() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_stack_name_or_arn:-$(extract "cloudformation" $region <<< "$input")}" ] || filters="--stack-name ${FLAGS_stack_name_or_arn:-$(extract "cloudformation" $region <<< "$input" | awk '{ print $1 }')}"

  option_if_not_blank "$filters" "$filters"
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    [
      \$region,
      .StackName,
      .LogicalResourceId,
      .ResourceType,
      .ResourceStatus,
      .Timestamp,
      .EventId
    ] | sort_by(.Timestamp) | join("\t")
EOS
  )

  jq -r --arg region $region ".StackEvents[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws cloudformation --region $region describe-stack-events $(stack_name $region "$INPUT") \
    | output_jq $region
done
