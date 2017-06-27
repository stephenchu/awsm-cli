#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: ec2-describe-regions [-r <region>...] [options]

Options:
    -r --region=<region>...                AWS region(s) to describe
    --help                                 Show help options

Global Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied  [default: .RegionName]
    --log-awscli                           Logs every awscli command line runs to stderr. [default: false]
    --log-jq                               Logs every jq command runs to stderr.          [default: false]

Environment Variables:
    AWSM_LOG_AWS_CLI                       Logs every awscli command line runs to stderr. Same as \`--log-awscli\` but at a global level.
    AWSM_LOG_JQ                            Logs every jq command runs to stderr. Same as \`--log-jq\` but at a global level.
EOF
)"

aws:filters() {
  local input="$1"
  local regions="$(string.join " " <<< "${region[@]}")"

  echo_if_not_blank "${regions:-}" "--region-names ${regions}"
}

output:jq() {
  jq -r ".Regions[] | ${jq:-".RegionName"}"
}

output:headers "RegionName"
INPUT="$(stdin:aws-regional-input)"
aws ec2 --region us-west-2 describe-regions $(aws:filters "$INPUT") \
  | output:jq
