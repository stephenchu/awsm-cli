#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string   'bucket' '' 'S3 bucket name' 'b'
DEFINE_boolean  'yes' $FLAGS_FALSE 'Prevents confirmation prompt' 'y'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh


s3.does_bucket_exists() {
  aws s3api head-bucket --bucket "$FLAGS_bucket" 2>/dev/null
}


s3.fetch_versioned_objects() {
  aws s3api list-object-versions \
      --bucket "$FLAGS_bucket" \
      $(echo_if_not_blank "$page_token" "--starting-token $page_token") \
      --max-items 1000
}


s3.delete_versioned_objects() {
  local page_token="${1:-}"

  local objects_json="$(s3.fetch_versioned_objects "$page_token")"
  local delete_versions_request_json="$(jq -r '
    {
      Quiet: true,
      Objects: (.Versions // []) | map({ "Key": .Key, "VersionId": .VersionId })
    }
  ' <<< "$objects_json")"
  local delete_deletemarkers_request_json="$(jq -r '
    {
      Quiet: true,
      Objects: (.DeleteMarkers // []) | map({ "Key": .Key, "VersionId": .VersionId })
    }
  ' <<< "$objects_json")"

  printf "." >&2
  jq -e '.Objects | length > 0' <<< "$delete_versions_request_json" |>/dev/null      && aws s3api delete-objects --bucket "$FLAGS_bucket" --delete file://<(echo "$delete_versions_request_json")
  jq -e '.Objects | length > 0' <<< "$delete_deletemarkers_request_json" |>/dev/null && aws s3api delete-objects --bucket "$FLAGS_bucket" --delete file://<(echo "$delete_deletemarkers_request_json")

  local next_page_token="$(jq -r '.NextToken // ""' <<< "$objects_json")"
  echo -n "$next_page_token"
}


if [[ $FLAGS_yes == $FLAGS_FALSE ]]; then
  read -r -p "$(ansi.red "WARNING"): Are you sure you want to irreversibly delete the S3 bucket '$(ansi.green "$FLAGS_bucket")' and all of its versioned objects? [y/N] " confirmation
  if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    echo "Fine choice. Your S3 bucket is untouched."
    exit 0
  fi
fi

while :; do
  page_token="$(s3.delete_versioned_objects "${page_token:-}")"
  [ -z "$page_token" ] && break
done

aws s3 rb --force s3://$FLAGS_bucket
