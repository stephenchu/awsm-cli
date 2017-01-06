#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/../vendor/shflags/src/shflags
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ $FLAGS_help -eq $FLAGS_FALSE ] || { exit 1; }

set -euo pipefail
source $DIR/../_common_logging.sh

check_awscli() {
  local errors=0

  installed() {
    if ! type aws &> /dev/null; then
      log.error "awscli is not installed or in \$PATH"
      ((errors+=1))
      return 1
    fi
  }

  describe_regions() {
    if ! aws ec2 describe-regions --region us-west-2 \
                                   --query 'Regions[*].RegionName' \
                                   --output text \
                                   2>/dev/null \
                                   | xargs printf '%s\n' \
                                   | grep --quiet 'us-west-2'; then
      log.error "Unable to run a simple \`aws ec2 describe-regions --region us-west-2\` locally. Please check your awscli credentials, or run the very command manually."
      ((errors+=1))
    fi
  }

  version() {
    local minimum_version="1.10.0"
    local current_version=$(aws --version 2>&1 | awk '{ print $1 }' | cut -d '/' -f 2)
    if [[ "$(echo -e "$minimum_version\n$current_version" | sort --unique --version-sort | tail -1)" == "$minimum_version" ]]; then
      log.error "The minimum supported version of awscli is $minimum_version. Currently you have $current_version."
      ((errors+=1))
    fi
  }

  installed
  describe_regions
  version

  return $errors
}

check_jq() {
  local errors=0

  installed() {
    if ! type jq &> /dev/null; then
      log.error "jq is not installed or in \$PATH"
      ((errors+=1))
      return 1
    fi
  }

  version() {
    local minimum_version="1.6"
    local current_version=$(jq --version | cut -d '-' -f 2)
    if [[ "$(echo -e "$minimum_version\n$current_version" | sort --unique --version-sort | tail -1)" == "$minimum_version" ]]; then
      log.error "The minimum supported version of jq is $minimum_version. Currently you have $current_version."
      ((errors+=1))
    fi
  }

  installed
  version
  return $errors
}

check_gawk() {
  local errors=0

  installed() {
    if ! type awk &> /dev/null; then
      log.error "GNU awk is not installed or in \$PATH"
      ((errors+=1))
      return 1
    fi
  }

  gnu() {
    if ! awk --version | grep --quiet -F 'GNU'; then
      log.error "Your awk is not GNU awk; awsm-cli requires the use of GNU Awk."
      ((errors+=1))
    fi
  }

  version() {
    local minimum_version="4.1.1"
    local current_version="$(awk --version | head -1 | cut -d ',' -f 1 | cut -f 3)"
    if [[ "$(echo -e "$minimum_version\n$current_version" | sort --unique --version-sort | tail -1)" == "$minimum_version" ]]; then
      log.error "The minimum supported version of GNU awk is $minimum_version. Currently you have $current_version."
      ((errors+=1))
    fi
  }

  installed
  gnu
  version

  return $errors
}

check_parallel() {
  local errors=0

  installed() {
    if ! type parallel &> /dev/null; then
      log.error "GNU parallel is not installed or in \$PATH"
      ((errors+=1))
      return 1
    fi
  }

  version() {
    local minimum_version="20160922"
    if ! parallel --minversion $minimum_version &> /dev/null; then
      local current_version="$(parallel --minversion $minimum_version)"
      log.error "The minimum supported version of GNU parallel is $minimum_version. Currently you have $current_version."
      ((errors+=1))
    fi
  }

  installed
  version

  return $errors
}

check() {
  local errors=0

  if check_awscli; then
    log.info "Your awscli is working properly."
  else
    ((errors+=1))
  fi

  if check_jq; then
    log.info "Your jq is working properly."
  else
    ((errors+=1))
  fi

  if check_gawk; then
    log.info "Your GNU awk is working properly."
  else
    ((errors+=1))
  fi

  if check_parallel; then
    log.info "Your GNU parallel is working properly."
  else
    ((errors+=1))
  fi

  return $errors
}


log.info "Checking for dependencies used by awsm-cli..."
if check; then
  log.info "Summary: Awesome! All required dependencies are installed correctly. Enjoy awsm-cli!"
  exit 0
else
  log.error "Summary: $? dependencies do not meet minimum requirements. awsm-cli may not function correctly. Please correct them and re-run this checker."
  exit 1
fi
