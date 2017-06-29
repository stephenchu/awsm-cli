#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: ec2-describe-vpcs [-r <region>...] [options]

Options:
    -r --region=<region>...                AWS region(s) in which the vpc(s) are in [required: as argument or stdin]
    -i --vpc-id=<vpc-id>...                AWS vpc-id(s) to describe
    -f --filter=<filter>...                Passed as-is to the \`--filters\` option in awscli command
    -t --tag=<tag>...                      Any additional tags on the vpc(s) to display in the output
    --help                                 Show help options

Other Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied
    --log-awscli                           Logs every awscli command line runs to stderr [default: false]
    --log-jq                               Logs every jq command runs to stderr          [default: false]
EOF
)"

aws:filters() {
  local region="$1"
  local input="$2"
  local filter_values=""

  local vpc_ids="${vpc_id[@]:-$(stdin:extract "vpc" $region <<< "$input")}"

  [ -z "$(string.join " " <<< "${filter[@]}")" ] || filter_values="$filter_values $(string.join " " <<< "${filter[@]}")"
  [ -z "$(string.join "," <<< "$vpc_ids")" ]     || filter_values="$filter_values Name=vpc-id,Values=$(string.join "," <<< "$vpc_ids")"

  echo_if_not_blank "$filter_values" "--filters ${filter_values}"
}

output:jq() {
  local region="$1"
  local default=$(cat <<EOS
    [
      \$region,
      .VpcId,
      (.Tags | tag_value("Name")) // "n/a",
      $(output.tags "${tag[@]}")
    ] | join("\t")
EOS
  )

  jq -L $DIR/jq -r --arg region $region "include \"aws\"; .Vpcs[] | ${jq:-$default}"
}

INPUT="$(stdin:aws-regional-input)"
output:headers "Region VpcId $(headers.tag "Name") $(headers.tags "${tag[@]:-}")"
env_parallel -k 'aws ec2 --region {} describe-vpcs $(aws:filters {} "$INPUT") | output:jq {}' ::: ${region[@]:-$(stdin:extract "region" <<< "$INPUT")}
