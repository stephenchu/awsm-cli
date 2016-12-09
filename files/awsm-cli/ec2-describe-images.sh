#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string   'region' '' 'AWS region(s)' 'r'
DEFINE_string   'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-image-ids' '' 'AMI ids' 'v'
DEFINE_string  'filter-image-type' 'ami' 'Image type. One of "machine" (AMI), "kernel" (AKI), or "ramdisk" (ARI)' 'y'
DEFINE_boolean 'filter-ami' $FLAGS_FALSE 'Filter for only AMI results' ''
DEFINE_boolean 'filter-aki' $FLAGS_FALSE 'Filter for only AKI results' ''
DEFINE_boolean 'filter-ari' $FLAGS_FALSE 'Filter for only ARI results' ''
DEFINE_boolean 'filter-is-public' $FLAGS_FALSE 'Filter for only public images' ''
DEFINE_boolean 'filter-is-private' $FLAGS_FALSE 'Filter for only private images' ''
DEFINE_string  'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_string  'output-tags' '' 'Output any additional tags' 't'
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

  [ -z "${FLAGS_filters}" ]                                                     || filters="$filters $FLAGS_filters"
  [ ${FLAGS_filter_is_public} -eq $FLAGS_FALSE ]                                || filters="$filters Name=is-public,Values=true"
  [ ${FLAGS_filter_is_private} -eq $FLAGS_FALSE ]                               || filters="$filters Name=is-public,Values=false"
  {
    [ $FLAGS_filter_ami -eq $FLAGS_FALSE ] && \
    [ $FLAGS_filter_aki -eq $FLAGS_FALSE ] && \
    [ $FLAGS_filter_ari -eq $FLAGS_FALSE ]
  }                                                                             || filters="$filters Name=image-type,Values=$(filter_image_type | string.join ",")"
  [ -z "${FLAGS_filter_image_ids:-$(extract "a[krm]i" $region <<< "$input")}" ] || filters="$filters Name=image-id,Values=$(echo -n "${FLAGS_filter_image_ids:-$(extract "a[krm]i" $region <<< "$input")}" | string.join ",")"

  echo_if_not_blank "$filters" "--filters ${filters}"
}

filter_image_type() {
  local result=""

  [ $FLAGS_filter_ami -eq $FLAGS_FALSE ] || result="$result machine"
  [ $FLAGS_filter_aki -eq $FLAGS_FALSE ] || result="$result kernel"
  [ $FLAGS_filter_ari -eq $FLAGS_FALSE ] || result="$result ramdisk"

  echo -n "$result" | xargs
}

output_jq() {
  local region="$1"
  local default=$(cat <<EOS
    def tag_value(tag_name):
      . | values | map(
        select(.Key == tag_name)
      )[0].Value;

    (if .Public == "true" then "public" else "private" end) as \$public |
    [
      \$region,
      .ImageId,
      .State,
      .OwnerId,
      .Hypervisor,
      .VirtualizationType,
      .Architecture,
      .RootDeviceType,
      \$public,
      .CreationDate,
      .ImageLocation,
      $(output.tags "$FLAGS_output_tags")
    ] | join("\t")
EOS
  )
  jq -r --arg region $region ".Images[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input_with_region)
headers "Region ImageId State OwnerId Hypervisor VirtualizationType Architecture RootDeviceType Public CreationDate ImageLocation $(headers.tags "$FLAGS_output_tags")"
env_parallel -k 'aws ec2 --region {} describe-images $(filters {} "$INPUT") | output_jq {}' ::: ${FLAGS_region:-$(extract "region" <<< "$INPUT")}
