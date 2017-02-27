#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string  'path-prefix' '' 'The native \`--path-prefix\` parameter for filtering' 'p'
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
DEFINE_boolean  'log-jq' $FLAGS_FALSE 'Log jq calls' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/_common_all.sh

path_prefix() {
  local filters=""
  [ -z "${FLAGS_path_prefix}" ] || filters="$filters $FLAGS_path_prefix"
  echo_if_not_blank "$filters" "--path-prefix ${filters}"
}

output_jq() {
  local default=$(cat <<EOS
    def tag_value(tag_name):
      . | values | map(
        select(.Key == tag_name)
      )[0].Value;

    [
      .ServerCertificateId,
      .ServerCertificateName,
      .Expiration,
      .Path,
      .UploadDate
    ] | join("\t")
EOS
  )

  jq -r ".ServerCertificateMetadataList[] | ${FLAGS_jq:-$default}"
}

headers "ServerCertificateId ServerCertificateName Expiration Path UploadDate"
aws iam list-server-certificates $(path_prefix) | output_jq
