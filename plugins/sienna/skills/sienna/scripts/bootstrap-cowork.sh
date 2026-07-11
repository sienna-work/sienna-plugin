#!/usr/bin/env bash
set -euo pipefail

if command -v sienna >/dev/null 2>&1; then
  command -v sienna
  exit 0
fi

plugin_root="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$plugin_root" ]; then
  echo "sienna is not on PATH; obtain approval before running the official checksum-verifying installer" >&2
  exit 127
fi

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) asset="sienna-x86_64-linux" ;;
  Linux-aarch64|Linux-arm64) asset="sienna-aarch64-linux" ;;
  *)
    echo "Sienna supports only Linux amd64 and arm64 Cowork runtimes" >&2
    exit 1
    ;;
esac

runtime_root="${plugin_root}/runtime"
version_file="${runtime_root}/VERSION"
checksums="${runtime_root}/SHA256SUMS"
if [ ! -f "$version_file" ] || [ ! -f "$checksums" ]; then
  echo "the installed Sienna Plugin is missing public runtime metadata; update or reinstall the Plugin" >&2
  exit 1
fi

version="$(tr -d '[:space:]' < "$version_file")"
case "$version" in
  ''|*[!0-9.]*)
    echo "the installed Sienna Plugin has an invalid runtime version" >&2
    exit 1
    ;;
esac

checksum_line="$(grep -E "^[0-9a-fA-F]{64}  ${asset}$" "$checksums" || true)"
if [ -z "$checksum_line" ]; then
  echo "the installed Sienna Plugin has no checksum for ${asset}" >&2
  exit 1
fi
expected_checksum="${checksum_line%% *}"

verify_checksum() {
  local file="$1"
  local expected="$2"
  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    echo "no SHA-256 verifier is available" >&2
    return 1
  fi
  [ "$actual" = "$expected" ]
}

if [ -n "${CLAUDE_PLUGIN_DATA:-}" ]; then
  data_root="$CLAUDE_PLUGIN_DATA"
else
  data_root="${XDG_DATA_HOME:-$HOME/.local/share}/sienna-plugin"
fi
bin_dir="${data_root}/bin"
destination="${bin_dir}/sienna"
mkdir -p "$bin_dir"
chmod 0700 "$data_root" "$bin_dir"

if [ ! -f "$destination" ] || ! verify_checksum "$destination" "$expected_checksum"; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install the Sienna Cowork runtime" >&2
    exit 1
  fi
  temporary="$(mktemp "${destination}.tmp.XXXXXX")"
  trap 'rm -f "${temporary:-}"' EXIT
  base_url="${SIENNA_DIST_URL:-https://get.sienna.work}"
  base_url="${base_url%/}"
  if ! curl -fsSL "${base_url}/v${version}/${asset}" -o "$temporary"; then
    echo "could not download the Sienna Cowork runtime; allow egress to get.sienna.work and retry" >&2
    exit 1
  fi
  if ! verify_checksum "$temporary" "$expected_checksum"; then
    echo "the downloaded Sienna Cowork runtime checksum does not match the public Plugin metadata" >&2
    exit 1
  fi
  chmod 0700 "$temporary"
  mv -f "$temporary" "$destination"
  trap - EXIT
fi

if ! "$destination" --version >/dev/null 2>&1; then
  echo "the installed Sienna Cowork runtime failed its version check" >&2
  exit 1
fi

printf '%s\n' "$destination"
