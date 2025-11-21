#!/bin/bash
# Diagnostic script for PHP 8.3 package
# Run this on your Synology NAS

echo "=========================================="
echo "PHP 8.3 Package Diagnostic"
echo "=========================================="
echo ""

echo "1. Package INFO file:"
echo "---"
cat /var/packages/php83/INFO 2>/dev/null || echo "ERROR: INFO file not found!"
echo ""

echo "2. Package status:"
echo "---"
synopkg status php83
echo ""

echo "3. Admin settings from INFO:"
echo "---"
grep -E "startable|admin_port|admin_protocol|admin_url" /var/packages/php83/INFO 2>/dev/null || echo "No admin settings found"
echo ""

echo "4. Web server configuration:"
echo "---"
echo "Port file: $(cat /var/packages/php83/target/etc/webserver.port 2>/dev/null || echo 'NOT FOUND')"
echo "PID file: $(cat /var/packages/php83/var/webserver.pid 2>/dev/null || echo 'NOT FOUND')"
echo ""

echo "5. Web server process:"
echo "---"
ps aux | grep -E "php.*8380|web-server" | grep -v grep || echo "No web server process found"
echo ""

echo "6. Port 8380 listening:"
echo "---"
netstat -tlnp 2>/dev/null | grep 8380 || echo "Port 8380 not in use"
echo ""

echo "7. Web server script exists:"
echo "---"
ls -la /var/packages/php83/target/scripts/web-server.sh 2>/dev/null || echo "web-server.sh NOT FOUND!"
echo ""

echo "8. Web server logs (last 10 lines):"
echo "---"
tail -10 /var/packages/php83/var/log/webserver.log 2>/dev/null || echo "No logs found"
echo ""

echo "9. Try to start web server manually:"
echo "---"
if [ -f /var/packages/php83/target/scripts/web-server.sh ]; then
    /var/packages/php83/target/scripts/web-server.sh start
else
    echo "web-server.sh not found!"
fi
echo ""

echo "10. Check if port is now listening:"
echo "---"
sleep 2
netstat -tlnp 2>/dev/null | grep 8380 || echo "Port 8380 still not in use"
echo ""

echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="
