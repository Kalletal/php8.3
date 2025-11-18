#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/extension_config.sh"

PHP_INI_DIR="/var/packages/php83/target/conf.d"
PHP_BIN="/var/packages/php83/target/usr/local/bin/php"
LOG_FILE="/var/log/php83-extension-selection.log"
LOGGER="/var/packages/php83/target/bin/log-extension-event.sh"

mkdir -p "$PHP_INI_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

profile_json=$(load_profile)
selected_modules=$(echo "$profile_json" | jq -r '.selected[]')

echo "; Auto-generated extension list" > "$PHP_INI_DIR/extensions.ini"
for module in $selected_modules; do
    echo "extension=${module}.so" >> "$PHP_INI_DIR/extensions.ini"
    log "Queued module $module" | tee -a "$LOG_FILE" >/dev/null
    if [ -x "$LOGGER" ]; then
        "$LOGGER" "Queued module $module"
    fi
done

if [ -x "$PHP_BIN" ]; then
    if ! "$PHP_BIN" -m >/dev/null 2>&1; then
        log "php -m failed; check PHP installation" | tee -a "$LOG_FILE" >/dev/null
        exit 1
    fi
fi

if command -v synoservicectl >/dev/null 2>&1; then
    for svc in pkgctl-php83 php83-fpm; do
        log "Restarting $svc to load new extensions" | tee -a "$LOG_FILE" >/dev/null
        if [ -x "$LOGGER" ]; then
            "$LOGGER" "Restart triggered for $svc"
        fi
        synoservicectl --restart "$svc" || log "Failed to restart $svc; continue"
    done
else
    log "synoservicectl not available; please restart PHP services manually" | tee -a "$LOG_FILE" >/dev/null
    if [ -x "$LOGGER" ]; then
        "$LOGGER" "Manual restart required to load PHP extensions"
    fi
fi

log "Extension apply complete" | tee -a "$LOG_FILE" >/dev/null
if [ -x "$LOGGER" ]; then
    "$LOGGER" "Extension apply complete"
fi
