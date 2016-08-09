#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string   'region' '' 'AWS region(s)' 'r'
DEFINE_string   'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-vpc-id' '' 'VPC Id' 'v'
DEFINE_string  'subnet-ids' '' 'Subnet Id' 's'
DEFINE_string   'jq' '' 'Output \`jq\` filter' 'j'
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

  [ -z "${FLAGS_filters}" ]                                              || filters="$filters $FLAGS_filters"
  [ -z "${FLAGS_filter_vpc_id:-$(extract "vpc" $region <<< "$input")}" ] || filters="$filters Name=vpc-id,Values=$(echo -n "${FLAGS_filter_vpc_id:-$(extract "vpc" $region <<< "$input")}" | string.join ",")"
  [ -z "${FLAGS_filter_subnet_ids:-$(extract "subnet" $region <<< "$input")}" ] || filters="$filters Name=subnet-id,Values=$(echo -n "${FLAGS_filter_subnet_ids:-$(extract "subnet" $region <<< "$input")}" | string.join ",")"

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
      .AvailabilityZone,
      .SubnetId,
      .CidrBlock,
      .State,
      (.Tags | tag_value("Name")) // "n/a"
    ] | join("\t")
EOS
  )
  jq -C -r --arg region $region ".Subnets[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region VpcId AvailabilityZone SubnetId CidrBlock State Name"
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws ec2 --region $region describe-subnets $(filters $region "$INPUT") \
    | output_jq $region
done
