#!/bin/bash
# Comprehensive fix for Web Station PHP 8.3 integration
set -e

echo "=== Web Station PHP 8.3 Comprehensive Fix ==="
echo ""

# Step 1: Fix the broken systemd service file
echo "[1/4] Fixing systemd service file..."
SERVICE_FILE="/usr/local/lib/systemd/system/pkg-WebStation-php83@.service"

sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=WebStation PHP 8.3 fpm process
After=pkgctl-php83.service pkgctl-WebStation.service
PartOf=pkgctl-php83.service pkgctl-WebStation.service
ConditionPathExists=/var/packages/WebStation/enabled
ConditionPathExists=/var/packages/php83/enabled
IgnoreOnIsolate=true
DefaultDependencies=no

[Service]
Type=simple
PIDFile=/run/php-fpm/php-%i.pid
Environment=PHP_INI_SCAN_DIR=/usr/syno/etc/packages/WebStation/php_profile/%i/conf.d:/run/php-fpm/conf.d
ExecStartPre=/var/packages/WebStation/target/tools/webstation_systemd_service_tool.sh pkg-WebStation-php ExecStartPre
ExecStart=/var/packages/php83/target/package/sbin/php-fpm \
            -c /var/packages/php83/target/package/etc/php.ini \
            --fpm-config /usr/syno/etc/packages/WebStation/php_profile/%i/fpm.conf \
            --allow-to-run-as-root \
            --nodaemonize \
            --pid /run/php-fpm/php-%i.pid
ExecReload=/bin/kill -USR2 $MAINPID
Restart=on-failure
Slice=syno_dsm_internal.slice

[Install]
WantedBy=pkgctl-php83.service pkgctl-WebStation.service

[X-Synology]
Name=WebStation PHP 8.3 fpm process
EOF

echo "✓ Service file corrected"
echo ""

# Step 2: Check and fix PluginPackage.json ordering
echo "[2/4] Checking PluginPackage.json structure..."
PLUGIN_JSON="/usr/syno/etc/packages/WebStation/PluginPackage.json"

# Backup current file
BACKUP="${PLUGIN_JSON}.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp "$PLUGIN_JSON" "$BACKUP"
echo "   Backup created: $BACKUP"

# Analyze and potentially reorder
python3 << 'PYTHON_FIX'
import json
import sys

plugin_file = "/usr/syno/etc/packages/WebStation/PluginPackage.json"

try:
    with open(plugin_file, 'r') as f:
        data = json.load(f)

    packages = data.get('packages', [])

    # Find php83 and check its position
    php83_index = None
    for i, pkg in enumerate(packages):
        if pkg.get('id') == 'php83':
            php83_index = i
            break

    if php83_index is None:
        print("ERROR: php83 not found in PluginPackage.json!")
        sys.exit(1)

    # Check if php83 is after non-PHP packages
    php_packages_indices = []
    for i, pkg in enumerate(packages):
        if pkg.get('id', '').startswith('php') or pkg.get('id', '').startswith('PHP'):
            php_packages_indices.append(i)

    print(f"   php83 is at position {php83_index}")
    print(f"   PHP packages at positions: {php_packages_indices}")

    # Check if there are non-PHP packages between PHP packages
    non_php_between = []
    if php_packages_indices:
        first_php = min(php_packages_indices)
        last_php = max(php_packages_indices)
        for i in range(first_php, last_php + 1):
            pkg_id = packages[i].get('id', '')
            if not (pkg_id.startswith('php') or pkg_id.startswith('PHP')):
                non_php_between.append((i, pkg_id))

    if non_php_between:
        print(f"   ⚠ WARNING: Found non-PHP packages between PHP packages:")
        for idx, pkg_id in non_php_between:
            print(f"      Position {idx}: {pkg_id}")
        print("   This might cause Web Station UI to crash!")
        print("   Reordering packages...")

        # Extract php83
        php83_entry = packages[php83_index]

        # Remove php83 from current position
        packages.pop(php83_index)

        # Find the last official PHP package (php82, php81, php80, etc.)
        last_official_php_index = -1
        for i, pkg in enumerate(packages):
            pkg_id = pkg.get('id', '')
            if pkg_id in ['PHP8.2', 'php82', 'PHP8.1', 'php81', 'PHP8.0', 'php80', 'PHP7.4', 'php74']:
                last_official_php_index = i

        if last_official_php_index >= 0:
            # Insert php83 right after the last official PHP
            packages.insert(last_official_php_index + 1, php83_entry)
            print(f"   ✓ Moved php83 to position {last_official_php_index + 1} (after last official PHP)")

            # Save reordered file
            data['packages'] = packages
            with open(plugin_file, 'w') as f:
                json.dump(data, f, indent=8)

            print("   ✓ PluginPackage.json reordered and saved")
        else:
            print("   Could not find official PHP packages to order after")
    else:
        print("   ✓ Package ordering looks correct")

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTHON_FIX

if [ $? -ne 0 ]; then
    echo "Failed to fix PluginPackage.json"
    exit 1
fi
echo ""

# Step 3: Reload systemd and restart services
echo "[3/4] Reloading systemd and services..."
sudo systemctl daemon-reload
sudo systemctl enable pkg-WebStation-php83@.service
sudo synoservicectl --reload nginx
echo "✓ Systemd reloaded"
echo ""

# Step 4: Restart Web Station
echo "[4/4] Restarting Web Station..."
sudo synopkg restart WebStation
sleep 3
echo "✓ Web Station restarted"
echo ""

# Verification
echo "=== Verification ==="
if [ -f "$SERVICE_FILE" ]; then
    echo "✓ Service file exists"
fi

if sudo synoservicectl --status pkgctl-php83 | grep -q "running"; then
    echo "✓ PHP 8.3 FPM is running"
fi

if sudo synoservicectl --status pkgctl-WebStation | grep -q "running"; then
    echo "✓ Web Station is running"
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Next steps:"
echo "1. Open DSM → Web Station"
echo "2. Check if general view now displays PHP, Python, Apache correctly"
echo "3. Go to Script Language Settings → PHP"
echo "4. Look for 'PHP 8.3' in the dropdown"
echo ""
