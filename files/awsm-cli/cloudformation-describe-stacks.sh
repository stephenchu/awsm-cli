#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: cloudformation-describe-stacks [-r <region>...] [-n <stack-name>] [options]

Options:
    -r --region=<region>...                 AWS region(s) in which the CloudFormation stack(s) are in [required: as argument or stdin]
    -n --stack-name=<stack-name>            AWS CloudFormation stack or arn to describe for [required: as argument or stdin]
    -t --tag=<tag>...                       Any additional resource tags to display in the output
    --help                                  Show help options

Other Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied
    --log-awscli                           Logs every awscli command line runs to stderr [default: false]
    --log-jq                               Logs every jq command runs to stderr          [default: false]
EOF
)"

aws:stack_name() {
  local region="$1"
  local input="$2"
  local filter_values=""

  local stacks="${stack_name:-$(stdin:extract "cloudformation" $region <<< "$input")}"

  [ -z "$stacks" ] || filter_values="--stack-name $(string.join " " <<< "$stacks")"

  echo_if_not_blank "$filter_values" "$filter_values"
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    [
      \$region,
      .StackName,
      .StackStatus,
      .CreationTime,
      .LastUpdatedTime // "n/a",
      .StackId,
      $(output.tags "${tag[@]}"),
      .StackStatusReason // "n/a"
    ] | join("\t")
EOS
  )

  jq -L $DIR/jq -r --arg region $region "include \"aws\"; .Stacks[] | ${jq:-$default}"
}

INPUT="$(stdin:aws-regional-input)"
output:headers "Region StackName StackStatus CreationTime LastUpdatedTime StackId $(headers.tags "${tag[@]}") StackStatusReason"
env_parallel -k 'aws cloudformation --region {} describe-stacks $(aws:stack_name {} "$INPUT") | output_jq {}' ::: ${region[@]:-$(stdin:extract "region" <<< "$INPUT")}
