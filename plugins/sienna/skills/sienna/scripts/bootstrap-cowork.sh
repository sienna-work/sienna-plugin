#!/usr/bin/env bash
set -euo pipefail

plugin_root="${CLAUDE_PLUGIN_ROOT:-}"

find_host_sienna() {
  local plugin_bin=""
  local directory candidate
  if [ -n "$plugin_root" ]; then
    plugin_bin="${plugin_root}/bin"
  fi
  while IFS= read -r directory; do
    [ -n "$directory" ] || directory="."
    [ "$directory" = "$plugin_bin" ] && continue
    candidate="${directory}/sienna"
    if [ -x "$candidate" ] && [ ! -d "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(printf '%s\n' "${PATH:-}" | tr ':' '\n')
  return 1
}

if host_sienna="$(find_host_sienna)"; then
  printf '%s\n' "$host_sienna"
  exit 0
fi

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
runtime="${runtime_root}/${asset}"

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

if [ ! -x "$runtime" ]; then
  echo "the installed Sienna Plugin is missing its bundled ${asset} runtime; update or reinstall the Plugin" >&2
  exit 1
fi

if ! verify_checksum "$runtime" "$expected_checksum"; then
  echo "the bundled Sienna Cowork runtime checksum does not match the Plugin metadata" >&2
  exit 1
fi

if ! "$runtime" --version >/dev/null 2>&1; then
  echo "the bundled Sienna Cowork runtime failed its version check" >&2
  exit 1
fi

printf '%s\n' "$runtime"
