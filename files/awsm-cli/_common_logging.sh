#! /bin/bash

log.debug() {
  local message="${1:-}"
  if [ ${FLAGS_log_debug:-1} -eq $FLAGS_TRUE ]; then
    ansi.yellow "[DEBUG] $message" >&2
  fi
}

log.info() {
  local message="${1:-}"
  if [ ${FLAGS_log_info:-$FLAGS_TRUE} -eq $FLAGS_TRUE ]; then
    ansi.green "[INFO] $message" >&2
  else
    echo "$message" >&2
  fi
}

log.warn() {
  local message="${1:-}"
  anis.red "[WARN] $message" >&2
}

ansi.black()   { echo "$(tput setaf 0)$*$(tput sgr0)"; }
ansi.red()     { echo "$(tput setaf 1)$*$(tput sgr0)"; }
ansi.green()   { echo "$(tput setaf 2)$*$(tput sgr0)"; }
ansi.yellow()  { echo "$(tput setaf 3)$*$(tput sgr0)"; }
ansi.blue()    { echo "$(tput setaf 4)$*$(tput sgr0)"; }
ansi.magenta() { echo "$(tput setaf 5)$*$(tput sgr0)"; }
ansi.cyan()    { echo "$(tput setaf 6)$*$(tput sgr0)"; }
ansi.white()   { echo "$(tput setaf 7)$*$(tput sgr0)"; }
