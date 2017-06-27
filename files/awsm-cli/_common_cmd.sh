#! /bin/bash

aws() {
  local cmd="$@"
  if [ "${AWSM_LOG_AWS_CLI+defined}" ] || $log_awscli; then
    ansi.yellow "[API] aws $cmd" >&2
  fi
  eval `which aws` $cmd
}

jq() {
  if [ "${AWSM_LOG_JQ+defined}" ] || $log_jq; then
    ansi.yellow " [JQ] jq $(printf "%s " "$@")" >&2
  fi
  `which jq` "$@"
}
