#!/usr/bin/env bash
set -euo pipefail

# Usage: ./install-wizard.sh /path/to/php83-arch.spk
PKG="$1"
TMP_JSON=$(mktemp)
cat <<JSON > "$TMP_JSON"
{
  "selected": ["curl", "pdo_mysql"],
  "pending": []
}
JSON

scp "$PKG" admin@nas:/tmp/php83.spk
ssh admin@nas "wizard_php83_extensions='$(cat "$TMP_JSON")' synopkg install /tmp/php83.spk"
ssh admin@nas "php -m | grep -E 'curl|pdo_mysql'"
