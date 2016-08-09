#! /bin/bash

set -euo pipefail

### String Functions
string.join() {
  local delimiter="${1:-" "}"
  sed "s/ /${delimiter}/g"
}

### JSON Functions
json.to_array() {
  local input=$(cat /dev/stdin)
  local field_separator="${2:- }"
  jq --null-input --arg input "$input" --arg separator "$field_separator" '$input | split($separator)'
}


### ANSI Colors Functions
black()   { echo "$(tput setaf 0)$*$(tput sgr0)"; }
red()     { echo "$(tput setaf 1)$*$(tput sgr0)"; }
green()   { echo "$(tput setaf 2)$*$(tput sgr0)"; }
yellow()  { echo "$(tput setaf 3)$*$(tput sgr0)"; }
blue()    { echo "$(tput setaf 4)$*$(tput sgr0)"; }
magenta() { echo "$(tput setaf 5)$*$(tput sgr0)"; }
cyan()    { echo "$(tput setaf 6)$*$(tput sgr0)"; }
white()   { echo "$(tput setaf 7)$*$(tput sgr0)"; }
