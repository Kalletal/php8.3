#!/bin/bash
# Fix PHP 8.3 to use port 9083 instead of 9000
# Run this script on the NAS as root: sudo bash fix-port-9083.sh

set -e

echo "=== Fixing PHP 8.3 FPM port configuration ==="

# Fix backend-php83.json in Web Station app.d directory
echo "1. Updating /usr/syno/etc/www/app.d/backend-php83.json..."
sed -i 's/"fpm_addr": "127.0.0.1:9000"/"fpm_addr": "127.0.0.1:9083"/g' /usr/syno/etc/www/app.d/backend-php83.json

# Verify the change
if grep -q '"fpm_addr": "127.0.0.1:9083"' /usr/syno/etc/www/app.d/backend-php83.json; then
    echo "   ✓ backend-php83.json updated successfully"
else
    echo "   ✗ ERROR: Failed to update backend-php83.json"
    exit 1
fi

# Fix php-fpm.conf in package directory
echo "2. Updating /var/packages/php83/target/package/conf/php-fpm.conf..."
sed -i 's/listen = 127.0.0.1:9000/listen = 127.0.0.1:9083/g' /var/packages/php83/target/package/conf/php-fpm.conf

# Verify the change
if grep -q 'listen = 127.0.0.1:9083' /var/packages/php83/target/package/conf/php-fpm.conf; then
    echo "   ✓ php-fpm.conf updated successfully"
else
    echo "   ✗ ERROR: Failed to update php-fpm.conf"
    exit 1
fi

# Restart PHP 8.3 service
echo "3. Restarting PHP 8.3 service..."
synoservicectl --restart pkgctl-php83

# Wait a moment for service to start
sleep 2

# Check if PHP-FPM is running on the new port
echo "4. Verifying PHP-FPM is running on port 9083..."
if netstat -tln | grep -q '127.0.0.1:9083.*LISTEN'; then
    echo "   ✓ PHP-FPM is listening on port 9083"
else
    echo "   ⚠ WARNING: PHP-FPM may not be listening on port 9083"
    echo "   Current listening ports:"
    netstat -tln | grep '127.0.0.1:90' || echo "   No ports in 90xx range found"
fi

# Reload Web Station configuration
echo "5. Reloading Web Station configuration..."
if command -v synowebservice >/dev/null 2>&1; then
    synowebservice --reload-config 2>&1 || true
fi
synoservicectl --reload nginx 2>&1 || true

echo ""
echo "=== Fix completed! ==="
echo ""
echo "Next steps:"
echo "1. Open Web Station in DSM"
echo "2. Go to 'Script Language Settings'"
echo "3. Try creating a new PHP profile - PHP 8.3 should now appear in the dropdown"
echo ""
