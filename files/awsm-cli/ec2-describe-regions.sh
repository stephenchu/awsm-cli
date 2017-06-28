#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: ec2-describe-regions [-r <region>...] [options]

Options:
    -r --region=<region>...                AWS region(s) to describe [required: as argument or stdin]
    --help                                 Show help options

Other Options:
    --jq=<jq_filter>                       Turns tabular output into JSON output, with a JQ filter already applied  [default: .RegionName]
    --log-awscli                           Logs every awscli command line runs to stderr [default: false]
    --log-jq                               Logs every jq command runs to stderr          [default: false]
EOF
)"

aws:filters() {
  local regions="$(string.join " " <<< "${region[@]:-}")"

  echo_if_not_blank "${regions:-}" "--region-names ${regions}"
}

output:jq() {
  jq -r ".Regions[] | $jq"
}

output:headers "RegionName"
aws ec2 --region us-west-2 describe-regions $(aws:filters) | output:jq
