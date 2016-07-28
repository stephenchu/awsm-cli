#!/bin/bash

set -o errexit
set -o nounset

VERSION=0.0.1

if ! gem list --installed package_cloud > /dev/null; then
  sudo gem install package_cloud
fi

echo "sudo yanking..."
sudo package_cloud yank cosmos/dev/debian/jessie awsm-cli_${VERSION}_amd64.deb || { echo 'Ignoring `package_cloud yank` failure.'; /bin/true; }
echo "sudo pushing..."
sudo package_cloud push cosmos/dev/debian/jessie ./build/artifacts/awsm-cli_${VERSION}_amd64.deb
