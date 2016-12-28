#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'region' '' 'AWS region(s)' 'r'
DEFINE_string  'stack-name' '' 'Stack name or ARN id' 'a'
DEFINE_string  'stack-status-filter' '' 'Stack status to use as a filter. ' 'f'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

stack_name() {
  local region="$1"
  local input="$2"
  local filters=""

  [ -z "${FLAGS_stack_name:-$(extract "cloudformation" $region <<< "$input")}" ] || filters="--stack-name ${FLAGS_stack_name:-$(extract "cloudformation" $region <<< "$input" | awk '{ print $1 }')}"

  echo_if_not_blank "$filters" "$filters"
}

stack_status_filter() {
  local all_statuses=(
    CREATE_IN_PROGRESS
    CREATE_FAILED
    CREATE_COMPLETE
    ROLLBACK_IN_PROGRESS
    ROLLBACK_FAILED
    ROLLBACK_COMPLETE
    DELETE_IN_PROGRESS
    DELETE_FAILED
    DELETE_COMPLETE
    UPDATE_IN_PROGRESS
    UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
    UPDATE_COMPLETE
    UPDATE_ROLLBACK_IN_PROGRESS
    UPDATE_ROLLBACK_FAILED
    UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
    UPDATE_ROLLBACK_COMPLETE
    REVIEW_IN_PROGRESS
  )
  local without_delete_complete=${all_statuses[@]/DELETE_COMPLETE}

  echo_if_not_blank "${FLAGS_stack_status_filter:-${without_delete_complete[@]}}" "--stack-status-filter ${FLAGS_stack_status_filter:-${without_delete_complete[@]}}"
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    [
      \$region,
      .StackName,
      .CreationTime,
      .LastUpdatedTime // "",
      .DeletionTime // "",
      .StackStatus,
      .StackId
    ] | sort_by(.CreationTime) | join("\t")
EOS
  )

  jq -r --arg region $region ".StackSummaries[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region StackName CreationTime LastUpdatedTime DeletionTime StackStatus StackId"
env_parallel -k 'aws cloudformation --region {} list-stacks $(stack_name {} "$INPUT") $(stack_status_filter) | output_jq {}' ::: ${FLAGS_region:-$(extract "region" <<< "$INPUT")}
