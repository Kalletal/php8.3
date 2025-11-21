#!/bin/bash
# PHP 8.3 Extension Manager API
# Handles extension configuration via DSM web interface

SYNOPKG_PKGDEST="/var/packages/php83/target"
EXT_CONFIG="${SYNOPKG_PKGDEST}/etc/php-extensions-enabled.ini"
EXT_CONFIG_JSON="${SYNOPKG_PKGDEST}/etc/php-extensions.json"

# Parse query string
parse_query() {
    local query="${QUERY_STRING}"
    echo "$query" | tr '&' '\n' | while IFS='=' read -r key value; do
        printf '%s=%s\n' "$key" "$(printf '%b' "${value//%/\\x}")"
    done
}

# Read POST data
read_post_data() {
    read -r POST_DATA
    echo "$POST_DATA"
}

# Get current extension state
get_extensions() {
    local extensions='{}'

    if [ -f "$EXT_CONFIG_JSON" ]; then
        cat "$EXT_CONFIG_JSON"
    else
        # Read from ini file and convert to JSON
        echo '{'
        first=true
        while IFS= read -r line; do
            if [[ $line =~ ^(zend_)?extension=(.*)\.so$ ]]; then
                ext="${BASH_REMATCH[2]}"
                [ "$first" = true ] && first=false || echo ','
                echo -n "\"$ext\": true"
            fi
        done < "$EXT_CONFIG" 2>/dev/null
        echo '}'
    fi
}

# Set extension configuration
set_extensions() {
    local post_data="$1"
    local temp_config="/tmp/php-ext-config-$$.ini"

    # Parse JSON from POST data
    # For simplicity, we'll regenerate the config based on posted extensions
    > "$temp_config"

    # Add enabled extensions from POST data
    echo "$post_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    extensions = data.get('extensions', {})
    for ext, enabled in extensions.items():
        if enabled:
            if ext == 'opcache':
                print('zend_extension=opcache.so')
            else:
                print(f'extension={ext}.so')
except:
    pass
" >> "$temp_config"

    # Move to actual config
    mv "$temp_config" "$EXT_CONFIG"

    # Save JSON config
    echo "$post_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    with open('$EXT_CONFIG_JSON', 'w') as f:
        json.dump(data.get('extensions', {}), f)
except:
    pass
"

    echo '{"success": true, "data": null}'
}

# Main handler
main() {
    echo "Content-Type: application/json"
    echo ""

    # Parse API parameters
    eval $(parse_query)

    case "$method" in
        list)
            echo '{"success": true, "data": '
            get_extensions
            echo '}'
            ;;
        set)
            local post_data=$(read_post_data)
            set_extensions "$post_data"
            ;;
        *)
            echo '{"success": false, "error": {"code": 404, "mesg": "Unknown method"}}'
            ;;
    esac
}

main
