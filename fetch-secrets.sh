#!/bin/sh
# Fetch Infisical secrets listed in a mapping file.
# Usage: fetch-secrets.sh <mapping-file> [output-dir]
#
# Mapping format (one per line):
#   INFISICAL_SECRET_NAME=output-filename
# Lines starting with # and blank lines are ignored.

set -eu

. "$(dirname "$0")/infisical-lib.sh"

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <mapping-file> [output-dir]" >&2
  exit 1
fi

MAP_FILE="$1"
OUTPUT_DIR="${2:-${INFISICAL_SECRETS_OUTPUT_DIR:-${INFISICAL_STACK_ROOT}/certs}}"

if [ ! -f "$MAP_FILE" ]; then
  echo "error: mapping file not found: $MAP_FILE" >&2
  exit 1
fi

CLI="$(infisical_cli_path)"
infisical_ensure_cli

export INFISICAL_TOKEN
INFISICAL_TOKEN="$(infisical_login_token)"

SECRET_ARGS="$(infisical_secret_args)"
mkdir -p "$OUTPUT_DIR"

echo "fetching secrets from Infisical into $OUTPUT_DIR..."
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|'#'*) continue ;;
  esac

  SECRET_NAME="${line%%=*}"
  OUTPUT_FILE="${line#*=}"

  if [ -z "$SECRET_NAME" ] || [ -z "$OUTPUT_FILE" ] || [ "$SECRET_NAME" = "$line" ]; then
    echo "error: invalid mapping line: $line" >&2
    exit 1
  fi

  DEST="$OUTPUT_DIR/$OUTPUT_FILE"
  # shellcheck disable=SC2086
  "$CLI" secrets get "$SECRET_NAME" $SECRET_ARGS --plain --silent > "$DEST"

  case "$OUTPUT_FILE" in
    *.key) chmod 600 "$DEST" ;;
  esac
done < "$MAP_FILE"

echo "fetch-secrets complete: wrote secrets to $OUTPUT_DIR"
