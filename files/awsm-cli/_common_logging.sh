#! /bin/bash

set -euo pipefail

debug() {
  local message="${1:-}"
  if [ ${FLAGS_log_debug:-1} -eq $FLAGS_TRUE ]; then
    yellow "[DEBUG] $message" >&2
  fi
}

info() {
  local message="${1:-}"
  if [ ${FLAGS_log_info:-$FLAGS_TRUE} -eq $FLAGS_TRUE ]; then
    green "[INFO] $message" >&2
  else
    echo "$message" >&2
  fi
}

warn() {
  local message="${1:-}"
  red "[WARN] $message" >&2
}
