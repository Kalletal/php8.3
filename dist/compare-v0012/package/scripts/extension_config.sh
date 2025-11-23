#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="/var/packages/php83/conf/extension_selection.json"
MANIFEST_PATH="/var/packages/php83/conf/extension_options.json"
BACKUP_SUFFIX=".bak"

log() {
    echo "[extension-config] $*" >&2
}

require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        log "jq is required but not installed"
        exit 1
    fi
}

load_profile() {
    require_jq
    if [ ! -f "$CONFIG_PATH" ]; then
        log "Config missing, seeding from sample"
        cp "/var/packages/php83/conf/extension_selection.json.sample" "$CONFIG_PATH"
    fi
    cat "$CONFIG_PATH"
}

save_profile() {
    require_jq
    local tmp
    tmp=$(mktemp)
    cat >"$tmp"
    cp "$CONFIG_PATH" "${CONFIG_PATH}${BACKUP_SUFFIX}"
    mv "$tmp" "$CONFIG_PATH"
}

get_dependencies() {
    local extension_manifest="$1"
    local extension_id="$2"
    require_jq
    jq -r --arg id "$extension_id" '.[] | select(.id == $id) | .dependencies[]?' "$extension_manifest"
}

get_conflicts() {
    local extension_manifest="$1"
    local extension_id="$2"
    require_jq
    jq -r --arg id "$extension_id" '.[] | select(.id == $id) | .conflicts[]?' "$extension_manifest"
}

selection_summary() {
    require_jq
    local selected_json
    selected_json=$(load_profile)
    local selected
    selected=$(echo "$selected_json" | jq -c '.selected')

    local footprint warnings
    footprint=$(jq --argjson sel "$selected" 'map(select(.id as $id | $sel | index($id))) | map(.diskFootprintMb) | add' "$MANIFEST_PATH")

    warnings=$(jq --argjson sel "$selected" '[
        .[] | select(.id as $id | $sel | index($id)) |
        select((.conflicts | map(. as $c | $sel | index($c)) | any) or (.compatible == false)) |
        {id: .id, message: (if .compatible == false then "Not supported on this hardware" else "Conflicts detected" end)}
    ]' "$MANIFEST_PATH")

    jq -n --argjson footprint "$footprint" --argjson warnings "$warnings" '{footprintMb: $footprint, warnings: $warnings}'
}
