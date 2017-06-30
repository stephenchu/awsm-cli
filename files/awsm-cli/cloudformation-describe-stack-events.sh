#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: cloudformation-describe-stack-events [-r <region>...] [-n <stack-name>] [options]

Options:
    -r --region=<region>...                 AWS region(s) in which the CloudFormation stack(s) are in [required: as argument or stdin]
    -n --stack-name=<stack-name>            AWS CloudFormation stack or arn to describe events for [required: as argument or stdin]
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

  [ -z "${stack_name:-$(stdin:extract "cloudformation" $region <<< "$input")}" ] || filter_values="--stack-name ${stack_name:-$(extract "cloudformation" $region <<< "$input" | awk '{ print $1 }')}"

  echo_if_not_blank "$filter_values" "$filter_values"
}

output:jq() {
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
    ] | join("\t")
EOS
  )

  jq -r --arg region $region ".StackEvents[] | ${jq:-$default}"
}

INPUT="$(stdin:aws-regional-input)"
output:headers "Region StackName LogicalResourceId ResourceType ResourceStatus Timestamp EventId"
env_parallel -k 'aws cloudformation --region {} describe-stack-events $(aws:stack_name {} "$INPUT") | output:jq {}' ::: ${region[@]:-$(stdin:extract "region" <<< "$INPUT")}
