#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'A space-delimited list of region names to filter. e.g. \"us-east-1 us-west-1\"' 'r'
DEFINE_string  'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-vpc-ids' '' 'VPC Id' 'v'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_string  'output-tags' '' 'Output any additional tags' 't'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

filters() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_filters}" ]                                               || filters="$filters $FLAGS_filters"
  [ -z "${FLAGS_filter_vpc_ids:-$(extract "vpc" $region <<< "$input")}" ] || filters="$filters Name=vpc-id,Values=$(string.join "," <<< "${FLAGS_filter_vpc_ids:-$(extract "vpc" $region <<< "$input")}")"

  echo_if_not_blank "$filters" "--filters ${filters}"
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
      .VpcId,
      (.Tags | tag_value("Name")) // "n/a",
      $(output.tags "$FLAGS_output_tags")
    ] | join("\t")
EOS
  )

  jq -C -r --arg region $region ".Vpcs[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region VpcId $(headers.tag "Name") $(headers.tags "$FLAGS_output_tags")"
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws ec2 --region $region describe-vpcs $(filters $region "$INPUT") \
    | output_jq $region
done
