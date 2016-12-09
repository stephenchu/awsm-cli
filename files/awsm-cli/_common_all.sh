#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/_common_cli.sh
source $DIR/_common_cmd.sh
source $DIR/_common_logging.sh
source $DIR/_common_pipes.sh
source $DIR/_common_utils.sh
source $(which env_parallel.bash)
