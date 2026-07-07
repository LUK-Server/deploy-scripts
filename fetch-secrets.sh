#!/bin/sh
# Fetch Infisical secrets and write each to a file.
# Usage: fetch-secrets.sh SECRET=filename [SECRET=filename ...]
# Or set INFISICAL_FILE_SECRETS="SECRET=filename ..." (space-separated).

set -eu

. "$(dirname "$0")/infisical-lib.sh"

fetch_secret_mapping() {
  line="$1"
  OUTPUT_DIR="$2"
  CLI="$3"
  SECRET_ARGS="$4"

  SECRET_NAME="${line%%=*}"
  OUTPUT_FILE="${line#*=}"

  if [ -z "$SECRET_NAME" ] || [ -z "$OUTPUT_FILE" ] || [ "$SECRET_NAME" = "$line" ]; then
    echo "error: invalid mapping: $line (expected SECRET=filename)" >&2
    exit 1
  fi

  DEST="$OUTPUT_DIR/$OUTPUT_FILE"
  # shellcheck disable=SC2086
  "$CLI" secrets get "$SECRET_NAME" $SECRET_ARGS --plain --silent > "$DEST"

  case "$OUTPUT_FILE" in
    *.key) chmod 600 "$DEST" ;;
  esac
}

if [ "$#" -eq 0 ] && [ -z "${INFISICAL_FILE_SECRETS:-}" ]; then
  echo "usage: $0 SECRET=filename [SECRET=filename ...]" >&2
  echo "   or set INFISICAL_FILE_SECRETS=\"SECRET=filename ...\"" >&2
  exit 1
fi

CLI="$(infisical_cli_path)"
infisical_ensure_cli

export INFISICAL_TOKEN
INFISICAL_TOKEN="$(infisical_login_token)"

SECRET_ARGS="$(infisical_secret_args)"
OUTPUT_DIR="${INFISICAL_SECRETS_OUTPUT_DIR:-${INFISICAL_STACK_ROOT}/certs}"
mkdir -p "$OUTPUT_DIR"

echo "fetching secrets from Infisical into $OUTPUT_DIR..."

if [ "$#" -gt 0 ]; then
  for mapping in "$@"; do
    fetch_secret_mapping "$mapping" "$OUTPUT_DIR" "$CLI" "$SECRET_ARGS"
  done
else
  # shellcheck disable=SC2086
  for mapping in $INFISICAL_FILE_SECRETS; do
    fetch_secret_mapping "$mapping" "$OUTPUT_DIR" "$CLI" "$SECRET_ARGS"
  done
fi

echo "fetch-secrets complete: wrote secrets to $OUTPUT_DIR"
