#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-zone-names' '' 'The list of availability zone names' 'z'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

filters() {
  local region="$1"
  local filters=""

  [ -z "${FLAGS_filters}" ]           || filters="$filters $FLAGS_filters"
  [ -z "${FLAGS_filter_zone_names}" ] || filters="$filters Name=zone-name,Values=${FLAGS_filter_zone_names}"

  echo_if_not_blank "$filters" "--filters ${filters}"
}

output_jq() {
  local default="[
    .service,
    .eventTypeCategory,
    .statusCode,
    .eventTypeCode,
    (.startTime | gmtime | todate),
    (.endTime | gmtime | todate),
    (.lastUpdatedTime | gmtime | todate)
  ] | join(\"\t\")"
  jq -r ".events[] | ${FLAGS_jq:-$default}"
}

headers "Service EventTypeCategory StatusCode EventTypeCode StartTime EndTime LastUpdatedTime"
aws health --region us-east-1 describe-events $(filters {}) | output_jq
