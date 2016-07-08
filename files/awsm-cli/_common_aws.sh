#! /bin/bash

set -euo pipefail

aws() {
  local cmd="$@"
  if [ "${AWSM_LOG_AWS_CLI+defined}" ] || [ $FLAGS_log_aws_cli -eq $FLAGS_TRUE ]; then
    yellow "[API] aws $cmd" >&2
  fi
  eval `which aws` $cmd
}

