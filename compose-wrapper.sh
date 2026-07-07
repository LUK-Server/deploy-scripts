#!/bin/sh
set -eu

. "$(dirname "$0")/infisical-lib.sh"

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <command> [args...]" >&2
  exit 1
fi

CLI="$(infisical_cli_path)"
infisical_ensure_cli

export INFISICAL_DISABLE_UPDATE_CHECK=true
export INFISICAL_TOKEN
INFISICAL_TOKEN="$(infisical_login_token)"

if [ -z "${INFISICAL_PROJECT_ID:-}" ]; then
  echo "error: INFISICAL_PROJECT_ID must be set" >&2
  exit 1
fi

API_URL="$(infisical_resolve_api_url)"

exec "$CLI" run \
  --token="$INFISICAL_TOKEN" \
  --projectId="$INFISICAL_PROJECT_ID" \
  --env="${INFISICAL_ENVIRONMENT:-prod}" \
  --domain="$API_URL" \
  -- "$@"
