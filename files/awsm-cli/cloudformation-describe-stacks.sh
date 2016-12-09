#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region(s)' 'r'
DEFINE_string  'stack-name-or-arn' '' 'Stack name or ARN id' 'a'
DEFINE_string  'filter-vpc-id' '' 'VPC Id' 'v'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_string  'output-tags' '' 'output any additional tags' 't'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

stack_name() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_stack_name_or_arn:-$(extract "cloudformation" $region <<< "$input")}" ] || filters="--stack-name ${FLAGS_stack_name_or_arn:-$(extract "cloudformation" $region <<< "$input")}"

  echo_if_not_blank "$filters" "$filters"
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    def tag_value(tag_name):
      . | values | map(
        select(.Key == tag_name)
      )[0].Value;

    [
      \$region,
      .StackName,
      .StackStatus,
      .CreationTime,
      .LastUpdatedTime // "n/a",
      .StackId,
      $(output.tags "$FLAGS_output_tags"),
      .StackStatusReason // "n/a"
    ] | sort_by(.CreationTime) | join("\t")
EOS
  )

  jq -r --arg region $region ".Stacks[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region StackName StackStatus CreationTime LastUpdatedTime StackId $(headers.tags "$FLAGS_output_tags") StackStatusReason"
env_parallel -k 'aws cloudformation --region {} describe-stacks $(stack_name {} "$INPUT") | output_jq {}' ::: ${FLAGS_region:-$(extract "region" <<< "$INPUT")}
