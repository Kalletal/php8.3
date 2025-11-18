#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-8.3.8}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_VENDOR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/vendor"
DEST_DIR="${2:-$DEFAULT_VENDOR_DIR}"
BASE_URL="https://www.php.net/distributions"
TARBALL="php-${VERSION}.tar.gz"
URL="${BASE_URL}/${TARBALL}"
SHA_URL="${URL}.sha256"

mkdir -p "$DEST_DIR"
OUTPUT_PATH="${DEST_DIR}/${TARBALL}"

printf '[download] Fetching %s\n' "$URL"
curl -L -o "$OUTPUT_PATH" "$URL"

EXPECTED=""
if command -v curl >/dev/null 2>&1; then
    EXPECTED=$(curl -fsSL "$SHA_URL" 2>/dev/null | awk '{print $1}' || true)
fi

if [ -z "$EXPECTED" ]; then
    case "$VERSION" in
        8.3.8) EXPECTED="0ebed9f1471871cf131e504629f3947f2acd38a655cc31b036f99efd0e3dbdeb" ;;
    esac
fi

if command -v sha256sum >/dev/null 2>&1 && [ -n "$EXPECTED" ]; then
    ACTUAL=$(sha256sum "$OUTPUT_PATH" | awk '{print $1}')
    if [ "$EXPECTED" != "$ACTUAL" ]; then
        echo "SHA256 mismatch: expected $EXPECTED but got $ACTUAL" >&2
        exit 1
    fi
    printf '[download] Verified sha256 %s\n' "$EXPECTED"
else
    echo "Skipping SHA256 verification (missing expectation or sha256sum)" >&2
fi

printf '[download] Saved to %s\n' "$OUTPUT_PATH"
