#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'regions' '' 'A space-delimited list of AWS regions. e.g. \"us-east-1 us-west-1\"' 'r'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Log aws-cli API calls' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

filters() {
  local input="$1"

  option_if_not_blank "${FLAGS_regions:-$(extract "region" <<< "$INPUT")}" "--region-names ${FLAGS_regions:-$(extract "region" <<< "$INPUT")}"
}

output_jq() {
  local default=".RegionName"
  jq -C -r ".Regions[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region "FLAGS_regions")
aws ec2 --region us-west-2 describe-regions $(filters "$INPUT") \
  | output_jq
