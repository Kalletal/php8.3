#!/bin/bash
# Diagnostic script for Web Station PHP 8.3 issue

echo "=== Web Station PHP 8.3 Diagnostic ==="
echo ""

echo "[1/6] Checking systemd service file..."
if [ -f "/usr/local/lib/systemd/system/pkg-WebStation-php83@.service" ]; then
    echo "✓ Service file exists"
    echo "Content:"
    cat /usr/local/lib/systemd/system/pkg-WebStation-php83@.service
else
    echo "✗ Service file NOT found at /usr/local/lib/systemd/system/pkg-WebStation-php83@.service"
fi
echo ""

echo "[2/6] Checking backend-php83.json location..."
if [ -f "/usr/syno/etc/www/app.d/backend-php83.json" ]; then
    echo "✓ /usr/syno/etc/www/app.d/backend-php83.json exists"
else
    echo "✗ backend-php83.json NOT in app.d/"
fi
echo ""

echo "[3/6] Checking PluginPackage.json structure..."
PLUGIN_JSON="/usr/syno/etc/packages/WebStation/PluginPackage.json"
if [ -f "$PLUGIN_JSON" ]; then
    echo "Packages in order:"
    python3 << 'PYTHON_CHECK'
import json
try:
    with open("/usr/syno/etc/packages/WebStation/PluginPackage.json", 'r') as f:
        data = json.load(f)

    print(f"Total packages: {len(data.get('packages', []))}")
    for i, pkg in enumerate(data.get('packages', [])):
        pkg_id = pkg.get('id', 'unknown')
        pkg_type = pkg.get('type', 'unknown')
        print(f"  [{i}] {pkg_id} (type={pkg_type})")

    # Find php83 position
    php83_index = None
    for i, pkg in enumerate(data.get('packages', [])):
        if pkg.get('id') == 'php83':
            php83_index = i
            break

    if php83_index is not None:
        print(f"\n⚠ php83 is at position {php83_index}")

        # Check what's before and after
        if php83_index > 0:
            prev_pkg = data['packages'][php83_index - 1].get('id')
            print(f"   Before: {prev_pkg}")
        if php83_index < len(data['packages']) - 1:
            next_pkg = data['packages'][php83_index + 1].get('id')
            print(f"   After: {next_pkg}")

        # Check if it's after non-PHP packages
        php_packages = [p for p in data['packages'] if p.get('id', '').startswith('php')]
        non_php_before = [p for p in data['packages'][:php83_index] if not p.get('id', '').startswith('php')]

        if non_php_before:
            print(f"\n⚠ WARNING: {len(non_php_before)} non-PHP packages BEFORE php83:")
            for p in non_php_before:
                print(f"      - {p.get('id')}")
            print("   This might cause Web Station UI to fail!")
except Exception as e:
    print(f"Error analyzing JSON: {e}")
PYTHON_CHECK
else
    echo "✗ PluginPackage.json NOT found"
fi
echo ""

echo "[4/6] Checking Web Station logs..."
WS_LOG="/var/packages/WebStation/var/webstation.log"
if [ -f "$WS_LOG" ]; then
    echo "Last 20 lines of webstation.log:"
    tail -20 "$WS_LOG"
else
    echo "webstation.log not found, checking other logs..."
    find /var/packages/WebStation/var/ -type f -name "*.log" 2>/dev/null | head -5
fi
echo ""

echo "[5/6] Checking systemd journal for Web Station..."
journalctl -u pkg-WebStation -n 20 --no-pager 2>/dev/null || echo "Cannot access journal"
echo ""

echo "[6/6] Checking Web Station process status..."
ps aux | grep -i webstation | grep -v grep
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "Recommendation:"
echo "If php83 is NOT grouped with other PHP packages (php80, php81, php82),"
echo "Web Station UI might fail to parse the list correctly."
echo "Solution: Reorder PluginPackage.json to place php83 after php82"
