#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region' 'r'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_string  'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-vpc-id' '' 'VPC Id' 'v'
DEFINE_string  'filter-instance-ids' '' 'EC2 instance ids' 'i'
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

  [ -z "${FLAGS_filters}" ]                                                  || filters="$filters $FLAGS_filters"
  [ -z "${FLAGS_filter_vpc_id:-$(extract "vpc" $region <<< "$input")}" ]     || filters="$filters Name=vpc-id,Values=${FLAGS_filter_vpc_id:-$(extract "vpc" $region <<< "$input" | string.join ",")}"
  [ -z "${FLAGS_filter_instance_ids:-$(extract "i" $region <<< "$input")}" ] || filters="$filters Name=instance-id,Values=${FLAGS_filter_instance_ids:-$(extract "i" $region <<< "$input" | string.join ",")}"

  option_if_not_blank "$filters" "--filters ${filters}"
}

output_jq() {
  local default=$(cat <<EOS
    def tag_value(tag_name):
      . | values | map(
        select(.Key == tag_name)
      )[0].Value;

    (if .PrivateDnsName == "" then null else .PrivateDnsName end) as \$private_dns_name |
    [
      \$region,
      (.Tags | tag_value("Name")) // "n/a", 
      .InstanceId,
      .Placement.AvailabilityZone,
      .InstanceType,
      .State.Name,
      .PublicIpAddress // "n/a",
      .PrivateIpAddress // "n/a",
      \$private_dns_name // "n/a",
      .VpcId // "n/a",
      .ImageId // "n/a",
      .LaunchTime,
      (.Tags | tag_value("Dimension"))
    ] | join("\t")
EOS
  )

  jq -C -r --arg region $region ".Reservations[].Instances[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws ec2 --region $region describe-instances $(filters $region "$INPUT") \
    | output_jq $region
done
