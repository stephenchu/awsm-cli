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
      $DIR/ec2-describe-regions.sh $(option_if_not_blank "${!region_variable_name}" "--region \"${!region_variable_name}\"")
    fi
  else
    cat /dev/stdin
  fi | $DIR/resources_by_region.awk
}

script_input_with_hosted_zone_id() {
  local hosted_zone_id_variable_name="${1:-"FLAGS_hosted_zone_id"}"

  if [ -t 0 ]; then
    $DIR/route53-list-hosted-zones.sh $(option_if_not_blank "${!hosted_zone_id_variable_name}" "--hosted-zone-id \"${!hosted_zone_id_variable_name}\"")
  else
    cat /dev/stdin
  fi | $DIR/resources_by_hosted_zone_id.awk
}

extract() {
  local resource_type="$1"
  local region="${2:-undefined}"

  if [ "$resource_type" == "region" ]; then
    awk "{ print \$1 }" | sort -u
  else
    awk "
      function aws_resource_without_region(field_1) {
        return (field_1 == \"$resource_type\" && \"$region\" == \"undefined\")
      }

      function aws_resource_with_region(field_1, field_2) {
        return (field_1 == \"$region\" && field_2 ~ /^$resource_type\$/)
      }

      function skip_fields(starting_field_number) {
        return substr(\$0, index(\$0, \$starting_field_number))
      }

      {
        if (aws_resource_without_region(\$1)) {
          print skip_fields(2)
        } else if (aws_resource_with_region(\$1, \$2)) {
          print skip_fields(3)
        }
      }" | paste --serial --delimiter ' ' -
  fi
}
