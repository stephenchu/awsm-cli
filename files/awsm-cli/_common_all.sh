#! /bin/bash

set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/_common_aws.sh
source $DIR/_common_cli.sh
source $DIR/_common_logging.sh
source $DIR/_common_pipes.sh
source $DIR/_common_utils.sh
