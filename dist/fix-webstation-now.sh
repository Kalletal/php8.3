#!/bin/bash
# Fix Web Station PHP 8.3 Detection - Immediate Fix

echo "=== Fixing Web Station PHP 8.3 Registration ==="

# Source files
BACKEND_SRC="/var/packages/php83/target/package/conf/backend.json"
PKG_PHP_SRC="/var/packages/php83/target/package/conf/PKG_PHP.json"

# Check if source files exist
if [ ! -f "$BACKEND_SRC" ]; then
    # Try alternate location (v0017)
    BACKEND_SRC="/var/packages/php83/target/backend-php83.json"
fi

if [ ! -f "$BACKEND_SRC" ]; then
    echo "ERROR: backend.json not found!"
    exit 1
fi

echo "[1/5] Copying backend.json to Web Station directory..."
sudo mkdir -p /usr/syno/etc/www/app.d
sudo cp -f "$BACKEND_SRC" /usr/syno/etc/www/app.d/backend-php83.json
sudo chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
ls -la /usr/syno/etc/www/app.d/backend-php83.json

echo "[2/5] Copying to secondary location (if exists)..."
if [ -d "/usr/syno/etc/packages/WebStation" ]; then
    sudo mkdir -p /usr/syno/etc/packages/WebStation/backends
    sudo cp -f "$BACKEND_SRC" /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    sudo chmod 644 /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    echo "   Copied to backends/"
fi

echo "[3/5] Reloading nginx..."
sudo synoservicectl --reload nginx

echo "[4/5] Restarting Web Station..."
sudo synopkg restart WebStation
sleep 3

echo "[5/5] Verification..."
if [ -f "/usr/syno/etc/www/app.d/backend-php83.json" ]; then
    echo "✓ backend-php83.json registered"
fi

if sudo synoservicectl --status pkgctl-php83 | grep -q "running"; then
    echo "✓ PHP 8.3 FPM is running"
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Vérifiez maintenant:"
echo "1. Web Station → Paramètres du langage de script → PHP"
echo "2. Cherchez 'PHP 8.3' dans la liste déroulante"
echo ""
