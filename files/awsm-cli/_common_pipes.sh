#! /bin/bash

set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# $1 - Name of shflags REGION variable, so that caller can customize their
#      shflags name to plural form (e.g. FLAGS_regions).
script_input_with_region() {
  local region_variable_name="${1:-"FLAGS_region"}"

  if [ -t 0 ]; then
    if [ "${!region_variable_name}+defined" ]; then
      echo "${!region_variable_name}" | xargs printf "%s\n"
    else
      $DIR/ec2-describe-regions.sh $(echo_if_not_blank "${!region_variable_name}" "--region \"${!region_variable_name}\"")
    fi
  else
    cat /dev/stdin
  fi | $DIR/resources_by_region.awk
}

script_input_with_hosted_zone_id() {
  local hosted_zone_id_variable_name="${1:-"FLAGS_hosted_zone_id"}"

  if [ -t 0 ]; then
    $DIR/route53-list-hosted-zones.sh $(echo_if_not_blank "${!hosted_zone_id_variable_name}" "--hosted-zone-id \"${!hosted_zone_id_variable_name}\"")
  else
    cat /dev/stdin
  fi | $DIR/resources_by_hosted_zone_id.awk
}

extract() {
  local resource_type="$1"
  local region="${2:-undefined}"

  if [ "$resource_type" == "region" ]; then
    awk "/^(us|ap|eu|sa)-/ { print \$1 }" | sort -u
  else
    $DIR/extract_aws_resource_by_type.awk -v resource_type=$resource_type -v region=$region
  fi | paste --serial --delimiter ' ' -
}
