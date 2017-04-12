#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region' 'r'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_string  'output-tags' '' 'Output any additional tags' 't'
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
  # [ -z "${FLAGS_filter_instance_ids:-$(extract "i" $region <<< "$input")}" ] || filters="$filters Name=instance-id,Values=${FLAGS_filter_instance_ids:-$(extract "i" $region <<< "$input" | string.join ",")}"

  echo_if_not_blank "$filters" "--filters ${filters}"
}

instance_ids_clause() {
  local region="$1"
  local input="$2"
  local instance_ids="$(extract "i" $region <<< "$input")"

  echo_if_not_blank "${FLAGS_filter_instance_ids:-$(string.join "," <<< "$instance_ids")}" "--instance-ids ${FLAGS_filter_instance_ids:-$(string.join "," <<< "$instance_ids")}"
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    (if .PrivateDnsName == "" then null else .PrivateDnsName end) as \$private_dns_name |
    [
      \$region,
      $(output.tags "Name") // "n/a",
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
      $(output.tags "$FLAGS_output_tags")
    ] | join("\t")
EOS
  )

  jq -L $DIR/jq -r --arg region $region "include \"aws\"; .Reservations[].Instances[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region $(headers.tag "Name") InstanceId AvailabilityZone InstanceType State PublicIpAddress PrivateIpAddress PrivateDnsName VpcId ImageId LaunchTime $(headers.tags "$FLAGS_output_tags")"
env_parallel -I '{region}' \
             -k 'env_parallel -I "{ids}" -N 200 aws ec2 --region {region} describe-instances $(instance_ids_clause {region} {ids}) $(filters {region} "$INPUT") | output_jq {region}' \
             ::: ${FLAGS_region:-$(extract "region" <<< "$INPUT")}
