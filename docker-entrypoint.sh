#!/bin/bash

set -euo pipefail

echo "Using custom docker entrypoint"

instance_ip() {
  curl --fail -Ss 'http://169.254.169.254/latest/meta-data/local-ipv4'
}

consul_kv() {
  declare key="$1"
  curl --fail -Ss ${CONSUL_HOST}:8500/v1/kv/${key} \
    | jq -r ".[0].Value" | base64 -d -
}

consul_kv_exists() {
  declare key="$1"
  local retval=0
  curl --fail -s ${CONSUL_HOST}:8500/v1/kv/${key} &> /dev/null \
    || retval=$?

  echo ${retval}
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

internal_ca_exists=$(consul_kv_exists anycable-websocket/internal_ca)
if [ "${internal_ca_exists}" -eq 0 ]; then
  echo "Internal CA detected."
  internal_ca=$(consul_kv anycable-websocket/internal_ca)
  echo "${internal_ca}" > /usr/local/share/ca-certificates/internal_ca.crt
  chmod 644 /usr/local/share/ca-certificates/internal_ca.crt
fi

if [ -n "$(ls -A /usr/local/share/ca-certificates)" ]; then
  echo "Updating ca-certificates"
  update-ca-certificates
fi

set -- /usr/local/bin/anycable-go "$@"
exec "$@"
