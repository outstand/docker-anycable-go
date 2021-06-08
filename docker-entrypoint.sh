#!/bin/bash

set -euo pipefail

echo "Using custom docker entrypoint"

instance_ip() {
  curl --fail -Ss 'http://169.254.169.254/latest/meta-data/local-ipv4'
}

if [ -z "${ANYCABLE_REDIS_URL:-}" ]; then
  echo "Setting redis url to local instance ip!"
  export ANYCABLE_REDIS_URL="redis://$(instance_ip):6379/"
fi

set -- /usr/local/bin/anycable-go "$@"
exec "$@"
