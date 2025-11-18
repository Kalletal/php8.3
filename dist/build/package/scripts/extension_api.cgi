#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/extension_config.sh"
MANIFEST_PATH="/var/packages/php83/conf/extension_options.json"
APPLY_SCRIPT="$SCRIPT_DIR/apply_extensions.sh"
CONTENT_TYPE="Content-Type: application/json"

respond() {
    echo "$CONTENT_TYPE"
    echo
    echo "$1"
}

case "${PATH_INFO:-/options}" in
    /options)
        respond "$(cat "$MANIFEST_PATH")"
        ;;
    /profile)
        profile=$(load_profile)
        summary=$(selection_summary)
        respond "$(jq -n --argjson profile "$profile" --argjson summary "$summary" '$profile + {summary: $summary}')"
        ;;
    /apply)
        body=$(cat)
        echo "$body" | save_profile
        "$APPLY_SCRIPT"
        respond "$(jq -n --argjson summary "$(selection_summary)" '{summary: $summary}')"
        ;;
    *)
        echo "Status: 404"
        respond '{"error":"Unknown endpoint"}'
        ;;
 esac
