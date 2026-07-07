#!/bin/sh
# Shared Infisical CLI bootstrap and auth for Komodo deploy scripts.
# Caller must set INFISICAL_STACK_ROOT to the service repo root before sourcing.

INFISICAL_CLI_VERSION="${INFISICAL_CLI_VERSION:-0.43.100}"
INFISICAL_API_URL_DEFAULT="http://infisical:8080"

if [ -z "${INFISICAL_STACK_ROOT:-}" ]; then
  echo "error: INFISICAL_STACK_ROOT must be set before sourcing infisical-lib.sh" >&2
  exit 1
fi

# Komodo writes stack environment to .env for compose --env-file; pre-deploy and
# compose wrappers do not inherit those vars unless we source the file explicitly.
komodo_load_stack_env() {
  ENV_FILE="${KOMODO_ENV_FILE:-${INFISICAL_STACK_ROOT}/.env}"
  if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
  fi
}

komodo_load_stack_env

infisical_resolve_api_url() {
  API_URL="${INFISICAL_API_URL:-$INFISICAL_API_URL_DEFAULT}"

  case "$API_URL" in
    https://*)
      echo "error: INFISICAL_API_URL must use the internal API ($INFISICAL_API_URL_DEFAULT), not the public HTTPS URL." >&2
      echo "       Traefik requires a client certificate; the Infisical CLI cannot present one during deploy." >&2
      exit 1
      ;;
  esac

  echo "$API_URL"
}

infisical_cli_path() {
  echo "${INFISICAL_STACK_ROOT}/bin/infisical"
}

infisical_ensure_cli() {
  CLI="$(infisical_cli_path)"
  if [ -x "$CLI" ]; then
    return 0
  fi

  ROOT="$INFISICAL_STACK_ROOT"
  BIN_DIR="$ROOT/bin"
  mkdir -p "$BIN_DIR"

  case "$(uname -m)" in
    x86_64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *)
      echo "error: unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac

  TARBALL="cli_${INFISICAL_CLI_VERSION}_linux_${ARCH}.tar.gz"
  URL="https://github.com/Infisical/cli/releases/download/v${INFISICAL_CLI_VERSION}/${TARBALL}"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT INT HUP TERM

  echo "downloading Infisical CLI v${INFISICAL_CLI_VERSION} (${ARCH})..."
  curl -fsSL "$URL" -o "$TMP/${TARBALL}"
  tar -xzf "$TMP/${TARBALL}" -C "$TMP"
  install -m 755 "$TMP/infisical" "$CLI"
}

infisical_login_token() {
  infisical_ensure_cli
  CLI="$(infisical_cli_path)"
  export INFISICAL_DISABLE_UPDATE_CHECK=true

  if [ -z "${INFISICAL_MACHINE_IDENTITY_CLIENT_ID:-}" ] || [ -z "${INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET:-}" ]; then
    echo "error: INFISICAL_MACHINE_IDENTITY_CLIENT_ID and INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET must be set" >&2
    exit 1
  fi

  API_URL="$(infisical_resolve_api_url)"

  "$CLI" login \
    --method=universal-auth \
    --client-id="$INFISICAL_MACHINE_IDENTITY_CLIENT_ID" \
    --client-secret="$INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET" \
    --domain="$API_URL" \
    --silent --plain
}

infisical_secret_args() {
  if [ -z "${INFISICAL_PROJECT_ID:-}" ]; then
    echo "error: INFISICAL_PROJECT_ID must be set" >&2
    exit 1
  fi
  echo "--projectId=${INFISICAL_PROJECT_ID} --env=${INFISICAL_ENVIRONMENT:-prod}"
}
