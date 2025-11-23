#!/bin/bash
# Web Station Package Worker Registration Script
# This script registers PHP 8.3 with Web Station

SYNOPKG_PKGNAME="php83"
SYNOPKG_PKGDEST="/var/packages/${SYNOPKG_PKGNAME}/target"
PKG_PHP_JSON="${SYNOPKG_PKGDEST}/conf/PKG_PHP.json"

echo "[$(date)] Registering PHP 8.3 with Web Station Package Worker..."

if [ ! -f "$PKG_PHP_JSON" ]; then
    echo "[$(date)] ERROR: PKG_PHP.json not found at $PKG_PHP_JSON"
    exit 1
fi

# Call Web Station Package Worker API to register the package
# The package worker monitors /var/packages/*/conf/PKG_PHP.json files
# and automatically registers them when the package is installed

# Trigger Web Station to reload plugin packages
if command -v synowebapi >/dev/null 2>&1; then
    echo "[$(date)] Calling Web Station API to reload plugins..."
    synowebapi --exec api=SYNO.WebStation.WebService.Package method=reload version=1 2>&1 || true
fi

# Alternative: directly modify PluginPackage.json (backup approach)
PLUGIN_PKG_JSON="/usr/syno/etc/packages/WebStation/PluginPackage.json"

if [ -f "$PLUGIN_PKG_JSON" ]; then
    echo "[$(date)] Manually registering in PluginPackage.json..."

    # Create backup
    cp "$PLUGIN_PKG_JSON" "${PLUGIN_PKG_JSON}.backup"

    # Read PKG_PHP.json content
    PKG_RESOURCE=$(cat "$PKG_PHP_JSON")

    # Check if php83 is already registered
    if grep -q '"id" : "php83"' "$PLUGIN_PKG_JSON"; then
        echo "[$(date)] php83 already registered in PluginPackage.json"
    else
        echo "[$(date)] Adding php83 to PluginPackage.json..."

        # Use Python to properly update the JSON
        python3 << PYTHON_SCRIPT
import json

# Read current PluginPackage.json
with open('$PLUGIN_PKG_JSON', 'r') as f:
    plugin_data = json.load(f)

# Read PKG_PHP.json
with open('$PKG_PHP_JSON', 'r') as f:
    pkg_php = json.load(f)

# Create new package entry
new_package = {
    "id": "php83",
    "resource": pkg_php,
    "type": 1,  # 1 = PHP package
    "version": "8.3.8-0010"
}

# Add to packages array
plugin_data['packages'].append(new_package)

# Write back
with open('$PLUGIN_PKG_JSON', 'w') as f:
    json.dump(plugin_data, f, indent=4)

print("[$(date)] Successfully added php83 to PluginPackage.json")
PYTHON_SCRIPT

        if [ $? -eq 0 ]; then
            echo "[$(date)] Successfully registered php83"
        else
            echo "[$(date)] Failed to update PluginPackage.json, restoring backup"
            mv "${PLUGIN_PKG_JSON}.backup" "$PLUGIN_PKG_JSON"
            exit 1
        fi
    fi
fi

# Reload Web Station configuration
if command -v systemctl >/dev/null 2>&1; then
    echo "[$(date)] Reloading Web Station..."
    systemctl restart pkg-WebStation 2>&1 || true
fi

echo "[$(date)] Registration complete"
exit 0
