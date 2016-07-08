#! /bin/bash

set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# $1 - Name of shflags REGION variable, so that caller can customize their
#      shflags name to plural form (e.g. FLAGS_regions).
script_input() {
  local region_variable_name="${1:-"FLAGS_region"}"

  if [ -t 0 ]; then
    if [ "${!region_variable_name}+defined" ]; then
      echo "${!region_variable_name}" | xargs printf "%s\n"
    else
      $DIR/ec2-describe-regions.sh $(option_if_not_blank "${!region_variable_name}" "-r ${!region_variable_name}")
    fi
  else
    cat /dev/stdin
  fi | $DIR/resources_by_region.awk
}

script_output() {
  local region="$1"
  if [ ! -z "${FLAGS_jq}" ]; then
    cat -
  else
    cat - | awk --assign region=$region '{ print region, $0 }'
  fi
}

extract() {
  local resource_type="$1"
  local region="${2:-}"

  if [ "$resource_type" == "region" ]; then
    awk "{ print \$1 }" | sort -u
  else
    awk "
      {
        if (\$1 == \"$region\" && \$2 == \"$resource_type\") {
          # Skip field #1 and #2
          print substr(\$0, index(\$0, \$3))
        }
      }"
  fi
}
