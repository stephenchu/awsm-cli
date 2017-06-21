#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -euo pipefail
source $DIR/_common_all.sh
source $(which env_parallel.bash)

eval "$($DIR/vendor/docopts/docopts -h - : "$@" <<EOF
Traces the origin of how an AMI was built using its image tags.

Usage: awsm ec2* describe-image-provenance -r <region> -i <ami-id> [options]

    -r --region=<region>                   AWS region of <ami-id>
    -i --ami-id=<ami-id>                   AMI to find provenance of
    -n --parent-ami-tag=<tag-name>         Tag name that indicates the source AMI that <ami-id> was built with           [default: SourceAMI]
    -s --parent-ami-region-tag=<tag-name>  Tag name that indicates the source AMI\'s region that <ami-id> was built with [default: SourceAMIRegion]
    -t --tags=<tags>                       Additional tags to output on each result
    --help                                 Show help options

Example Output:
    Region     ImageId       State      OwnerId       Hypervisor  VirtualizationType  Architecture  RootDeviceType  Public   CreationDate              ImageLocation                                             tag:SourceAMI  tag:SourceAMIRegion
    us-west-2  ami-a1d74cc1  available  782759316251  xen         hvm                 x86_64        ebs             private  2017-05-04T01:43:09.000Z  782759316251/kafka-2017-05-04-01-33-09                    ami-9b2c438d   us-east-1
    us-east-1  ami-9b2c438d  available  782759316251  xen         hvm                 x86_64        ebs             private  2017-05-04T01:14:53.000Z  782759316251/base-image-2017-05-04-01-06-39               ami-b14ba7a7   us-east-1
    us-east-1  ami-b14ba7a7  available  379101102735  xen         hvm                 x86_64        ebs             public   2017-01-15T12:28:53.000Z  379101102735/debian-jessie-amd64-hvm-2017-01-15-1221-ebs
EOF
)"


awsm:describe_images() {
  local ami_region="$1"
  local ami="$2"
  shift 2
  awsm ec2 describe-images -r $ami_region -v "$ami" -t "${parent_ami_tag} ${parent_ami_region_tag} ${tags}" "$@"
}


columns.pluck() {
  parallel --header : echo $(printf "{%s} " $@)
}


row="$(awsm:describe_images $region $ami_id --header)"
[[ "$(wc -l <<< "$row")" -gt 1 ]] || process.die "ERROR: Cannot locate ami-id $ami_id in $region"

header_row="$(head -1 <<< "$row")"
echo "$row"

while :; do
  ami="$(columns.pluck "tag:$parent_ami_tag" <<< "$row")"
  ami_region="$(columns.pluck "tag:$parent_ami_region_tag" <<< "$row")"
  [[ -z "$ami" ]] && break
  row="$(awsm:describe_images ${ami_region:-us-east-1} $ami --noheader)"
  [[ -z "$row" ]] && break

  echo "$row"
  row="$(printf "%s\n" "$header_row" "$row")"
done
