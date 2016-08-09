#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'A space-delimited list of region names to filter. e.g. \"us-east-1 us-west-1\"' 'r'
DEFINE_string  'filter-instance-id' '' 'EC2 instance id' 'i'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

instance_id() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_filter_instance_id:-$(extract "i" $region <<< "$input")}" ] || filters="$filters --instance-id ${FLAGS_filter_instance_id:-$(extract "i" $region <<< "$input" | awk '{ print $1 }')}"

  echo_if_not_blank "$filters" "$filters"
}

output_jq() {
  jq -r '.Output' | sed 's/\\n/\n/g' | sed 's/\\r/\r/g'
}

INPUT=$(script_input_with_region)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws ec2 --region $region get-console-output $(instance_id $region "$INPUT") \
    | output_jq
done
