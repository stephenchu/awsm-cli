#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Usage: $0 -r <region> -i <ami-id> [options]

      -r --region=<region>                   AWS region of <ami-id>
      -i --ami-id=<ami-id>                   AMI to find provenance of
      -n --parent-ami-tag=<tag-name>         Tag name that indicates the source AMI that <ami-id> was built with           [default: SourceAMI]
      -s --parent-ami-region-tag=<tag-name>  Tag name that indicates the source AMI\'s region that <ami-id> was built with [default: SourceAMIRegion]
      -t --tags=<tags>                       Additional tags to output on each result
      --help                                 Show help options
EOF
)"


describe_images() {
  local ami_region="$1"
  local ami="$2"
  shift 2
  awsm ec2 describe-images -r $ami_region -v "$ami" -t "${parent_ami_tag} ${parent_ami_region_tag} ${tags}" "$@"
}


columns.pluck() {
  parallel --header : echo $(printf "{%s} " $@)
}


row="$(describe_images $region $ami_id --header)"
[[ "$(wc -l <<< "$row")" -gt 1 ]] || process.die "ERROR: Cannot locate ami-id $ami_id in $region"

header_row="$(head -1 <<< "$row")"
echo "$row"

while :; do
  ami="$(columns.pluck "tag:$parent_ami_tag" <<< "$row")"
  ami_region="$(columns.pluck "tag:$parent_ami_region_tag" <<< "$row")"
  [[ -z "$ami" ]] && break
  row="$(describe_images ${ami_region:-us-east-1} $ami --noheader)"
  [[ -z "$row" ]] && break

  echo "$row"
  row="$(printf "%s\n" "$header_row" "$row")"
done
