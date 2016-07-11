#! /bin/bash

set -eu

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
docker build -t awsm-cli.deb -f $DIR/Dockerfile.deb .
docker run -v $DIR/artifacts:/output awsm-cli.deb
