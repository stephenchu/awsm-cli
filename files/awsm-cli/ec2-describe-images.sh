#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/vendor/shflags/src/shflags
DEFINE_string   'region' '' 'AWS region(s)' 'r'
DEFINE_string   'filters' '' 'The raw \`--filters\` attribute used with the AWS command' 'f'
DEFINE_string  'filter-image-ids' '' 'AMI ids' 'v'
DEFINE_string  'filter-image-type' 'ami' 'Image type. One of "machine" (AMI), "kernel" (AKI), or "ramdisk" (ARI)' 't'
DEFINE_boolean 'filter-ami' $FLAGS_FALSE 'Filter for only AMI results' ''
DEFINE_boolean 'filter-aki' $FLAGS_FALSE 'Filter for only AKI results' ''
DEFINE_boolean 'filter-ari' $FLAGS_FALSE 'Filter for only ARI results' ''
DEFINE_boolean 'filter-is-public' $FLAGS_FALSE 'Filter for only public images' ''
DEFINE_boolean 'filter-is-private' $FLAGS_FALSE 'Filter for only private images' ''
DEFINE_string   'jq' '' 'Output \`jq\` filter' 'j'
DEFINE_boolean  'log-aws-cli' $FLAGS_FALSE 'Show aws-cli API calls info made' ''
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

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
  }                                                                             || filters="$filters Name=image-type,Values=$(filter_image_type | join_str ",")"
  [ -z "${FLAGS_filter_image_ids:-$(extract "a[krm]i" $region <<< "$input")}" ] || filters="$filters Name=image-id,Values=$(echo -n "${FLAGS_filter_image_ids:-$(extract "a[krm]i" $region <<< "$input")}" | join_str ",")"

  option_if_not_blank "$filters" "--filters ${filters}"
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
      .ImageLocation
    ] | join("\t")
EOS
  )
  jq -C -r --arg region $region ".Images[] | ${FLAGS_jq:-$default}"
}

INPUT=$(script_input)
for region in ${FLAGS_region:-$(extract "region" <<< "$INPUT")}; do
  aws ec2 --region $region describe-images $(filters $region "$INPUT") \
    | output_jq $region
done