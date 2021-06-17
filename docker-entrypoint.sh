#!/bin/bash

set -euo pipefail

echo "Using custom docker entrypoint"

instance_ip() {
  curl --fail -Ss 'http://169.254.169.254/latest/meta-data/local-ipv4'
}

consul_kv() {
  declare key="$1"
  curl --fail -Ss ${CONSUL_HOST}:8500/v1/kv/${key} \
    | jq -r ".[0].Value" | base64 --decode
}

if [ -z "${ANYCABLE_REDIS_URL:-}" ]; then
  echo "Setting redis url to local instance ip!"
  export ANYCABLE_REDIS_URL="redis://$(instance_ip):6379/"
  echo "ANYCABLE_REDIS_URL=${ANYCABLE_REDIS_URL}"
fi

if [ -z "${ANYCABLE_ALLOWED_ORIGINS:-}" ]; then
  echo "Fetching allowed origins from consul"
  export ANYCABLE_ALLOWED_ORIGINS=$(consul_kv anycable-websocket/allowed_origins | jq -r '. | join(",")')
  echo "ANYCABLE_ALLOWED_ORIGINS=${ANYCABLE_ALLOWED_ORIGINS}"
fi

set -- /usr/local/bin/anycable-go "$@"
exec "$@"
