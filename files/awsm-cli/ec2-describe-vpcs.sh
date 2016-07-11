#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'A space-delimited list of region names to filter. e.g. \"us-east-1 us-west-1\"' 'r'
DEFINE_string  'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-vpc-ids' '' 'VPC Id' 'v'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

set -euo pipefail
source $DIR/_common_all.sh

filters() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_filters}" ]                                               || filters="$filters $FLAGS_filters"
  [ -z "${FLAGS_filter_vpc_ids:-$(extract "vpc" $region <<< "$input")}" ] || filters="$filters Name=vpc-id,Values=$(join_str "," <<< "${FLAGS_filter_vpc_ids:-$(extract "vpc" $region <<< "$input")}")"

  option_if_not_blank "$filters" "--filters ${filters}"
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
      (.Tags | tag_value("Name")) // "n/a"
    ] | join("\t")
EOS
  )

  jq -C -r --arg region $region ".Vpcs[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws ec2 --region $region describe-vpcs $(filters $region "$INPUT") \
    | output_jq $region
done
