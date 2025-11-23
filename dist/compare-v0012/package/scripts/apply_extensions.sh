#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
PHP_INI_DIR="/var/packages/php83/target/package/etc/conf.d"
PHP_BIN="/var/packages/php83/target/package/bin/php"
LOG_FILE="/var/log/php83-extension-selection.log"
EXTENSIONS_JSON="/var/packages/php83/target/package/conf/extensions.json"
USER_SELECTION="/var/packages/php83/var/extension_selection.conf"

# Create directories
mkdir -p "$PHP_INI_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$USER_SELECTION")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function to get all extensions from a category
get_extensions_from_category() {
    local category="$1"
    local extensions_json="$2"

    if command -v jq >/dev/null 2>&1; then
        jq -r ".categories.${category}.extensions | keys[]" "$extensions_json" 2>/dev/null || echo ""
    else
        # Fallback without jq
        grep -A 100 "\"$category\"" "$extensions_json" | \
            grep '"ext_' | \
            sed 's/.*"ext_\([^"]*\)".*/\1/' | \
            head -20
    fi
}

# Function to check if an extension is enabled by default
is_enabled_by_default() {
    local extension="$1"
    local category="$2"
    local extensions_json="$3"

    if command -v jq >/dev/null 2>&1; then
        local enabled=$(jq -r ".categories.${category}.extensions.${extension}.enabled_by_default // false" "$extensions_json" 2>/dev/null)
        [[ "$enabled" == "true" ]]
    else
        # Fallback: assume common extensions are enabled
        case "$extension" in
            opcache|tokenizer|filter|ctype|xml|dom|simplexml|xmlreader|xmlwriter|\
            pdo|mysqli|mysqlnd|pdo_mysql|sqlite3|pdo_sqlite|curl|openssl|\
            zlib|phar|gd|exif|fileinfo|session|posix)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
}

# Read user selections from wizard (if exists)
declare -A USER_EXTENSIONS
if [ -f "$USER_SELECTION" ]; then
    log "Loading user extension selections from wizard"
    while IFS='=' read -r key value; do
        if [[ $key == ext_* ]]; then
            ext_name="${key#ext_}"
            USER_EXTENSIONS[$ext_name]="$value"
        fi
    done < "$USER_SELECTION"
fi

# Generate extensions.ini based on default or user selection
log "Generating PHP extension configuration"
echo "; Auto-generated PHP extension configuration" > "$PHP_INI_DIR/extensions.ini"
echo "; Generated on $(date)" >> "$PHP_INI_DIR/extensions.ini"
echo "" >> "$PHP_INI_DIR/extensions.ini"

# Process all categories from extensions.json
for category in core math xml databases network compression images io system i18n; do
    if [ ! -f "$EXTENSIONS_JSON" ]; then
        log "WARNING: extensions.json not found at $EXTENSIONS_JSON"
        break
    fi

    extensions=$(get_extensions_from_category "$category" "$EXTENSIONS_JSON")

    if [ -n "$extensions" ]; then
        echo "; $category extensions" >> "$PHP_INI_DIR/extensions.ini"

        for ext in $extensions; do
            # Check if user made a selection
            if [ -n "${USER_EXTENSIONS[$ext]:-}" ]; then
                if [ "${USER_EXTENSIONS[$ext]}" == "true" ] || [ "${USER_EXTENSIONS[$ext]}" == "1" ]; then
                    echo "extension=${ext}.so" >> "$PHP_INI_DIR/extensions.ini"
                    log "Enabled extension: $ext (user selected)"
                fi
            else
                # Use default from extensions.json
                if is_enabled_by_default "$ext" "$category" "$EXTENSIONS_JSON"; then
                    echo "extension=${ext}.so" >> "$PHP_INI_DIR/extensions.ini"
                    log "Enabled extension: $ext (default)"
                fi
            fi
        done

        echo "" >> "$PHP_INI_DIR/extensions.ini"
    fi
done

# Validate PHP configuration
if [ -x "$PHP_BIN" ]; then
    log "Validating PHP configuration"
    if ! "$PHP_BIN" -v >/dev/null 2>&1; then
        log "ERROR: PHP binary validation failed"
        exit 1
    fi

    # List loaded modules
    log "Checking loaded modules:"
    "$PHP_BIN" -m 2>&1 | tee -a "$LOG_FILE" || log "WARNING: php -m failed"
else
    log "WARNING: PHP binary not found at $PHP_BIN"
fi

# Restart PHP services if available
if command -v synoservicectl >/dev/null 2>&1; then
    for svc in pkgctl-php83 php83-fpm; do
        if synoservicectl --status "$svc" >/dev/null 2>&1; then
            log "Restarting $svc to load new extensions"
            synoservicectl --restart "$svc" || log "WARNING: Failed to restart $svc"
        fi
    done
else
    log "INFO: synoservicectl not available; please restart PHP services manually"
fi

log "Extension application complete"
exit 0
