#!/bin/sh
set -eu

# The production image keeps only the deployed runtime closure, so it launches the built CLI directly.
HOST_IP="${DSH_BIND_HOST:-}"
if [ -z "$HOST_IP" ]; then
  HOST_IP="$(hostname -i 2>/dev/null | cut -d ' ' -f 1)"
fi
if [ -z "$HOST_IP" ]; then
  echo "dsh-web-prod: failed to resolve a concrete bind address; set DSH_BIND_HOST." >&2
  exit 1
fi

if [ -n "${DSH_TLS_CERT:-}" ] || [ -n "${DSH_TLS_KEY:-}" ]; then
  if [ -z "${DSH_TLS_CERT:-}" ] || [ -z "${DSH_TLS_KEY:-}" ]; then
    echo "dsh-web-prod: DSH_TLS_CERT and DSH_TLS_KEY must be set together." >&2
    exit 1
  fi
fi

set -- web --host "$HOST_IP" --port "${DSH_PORT:-3080}"

if [ -n "${DSH_PUBLIC_URL:-}" ]; then
  set -- "$@" --public-url "$DSH_PUBLIC_URL"
fi

TRUSTED_HOSTS="${DSH_TRUSTED_HOSTS:-localhost,127.0.0.1}"
OLD_IFS="$IFS"
IFS=','
for host in $TRUSTED_HOSTS; do
  if [ -n "$host" ]; then
    set -- "$@" --trusted-host "$host"
  fi
done
IFS="$OLD_IFS"

if [ -n "${DSH_TLS_CERT:-}" ]; then
  set -- "$@" --tls-cert "$DSH_TLS_CERT" --tls-key "$DSH_TLS_KEY"
fi

if [ "${DSH_NO_OPEN:-1}" = "1" ]; then
  set -- "$@" --no-open
fi

# `DSH_EXTRA_ARGS` is intentionally shell-split so callers can pass through uncommon flags.
if [ -n "${DSH_EXTRA_ARGS:-}" ]; then
  set -- "$@" ${DSH_EXTRA_ARGS}
fi

exec node /opt/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js "$@"
