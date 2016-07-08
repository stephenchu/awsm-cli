#! /bin/bash

set -euo pipefail

### String Functions
join_str() {
  local delimiter="${1:-" "}"
  sed "s/ /${delimiter}/g"
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
