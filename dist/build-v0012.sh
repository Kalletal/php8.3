#!/bin/bash
# Build script for PHP 8.3 v0012 with Package Worker integration
# To be run on NAS

set -e

echo "=== Building PHP 8.3 v0012 with Package Worker ==="
echo ""

# Configuration
BUILD_DIR="/tmp/php83-v0012-build"
WORKING_PKG="/var/packages/php83/target"

# Clean previous build
echo "[1/8] Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_DIR/package"
mkdir -p "$BUILD_DIR/scripts"
mkdir -p "$BUILD_DIR/conf"

# Copy from working package
echo "[2/8] Copying files from working package..."
if [ ! -d "$WORKING_PKG/package" ]; then
    echo "ERROR: Working package not found at $WORKING_PKG"
    exit 1
fi

# Copy package files (binaries, libs, conf, etc.)
cp -a "$WORKING_PKG/package" "$BUILD_DIR/"

echo "[3/8] Creating v0012 configuration files..."

# Create PKG_PHP.json for Package Worker
cat > "$BUILD_DIR/package/PKG_PHP.json" <<'EOF'
{
	"id": "php83",
	"resource": {
		"id": 83,
		"prefix": "php83",
		"version": 1,
		"fpm_path": "/var/packages/php83/target/package/sbin/php-fpm",
		"cgi_path": "/var/packages/php83/target/package/bin/php-cgi",
		"fpm_syslog_ident": "php83-fpm",
		"service_template_unit": "pkg-WebStation-php83@",
		"default_ini": "/var/packages/php83/target/package/etc/php.ini",
		"default_settings": "/var/packages/php83/target/package/conf/default_settings.json",
		"extension_list_path": "/var/packages/php83/target/package/conf/extension_list.json"
	},
	"type": 1,
	"version": "8.3.8-0012"
}
EOF

echo "   Created PKG_PHP.json for Package Worker"

# Update backend-php83.json if it exists
if [ -f "$BUILD_DIR/package/backend-php83.json" ]; then
    echo "   backend-php83.json already exists"
else
    echo "   Creating backend-php83.json..."
    cat > "$BUILD_DIR/package/backend-php83.json" <<'EOF'
{
  "service": "php83",
  "display_name": "PHP 8.3",
  "support_alias": true,
  "support_server": true,
  "type": "nginx_php",
  "root": "/var/packages/php83/target/package",
  "icon": "PACKAGE_ICON_256.PNG",
  "php": {
    "profile_name": "PHP 8.3",
    "profile_desc": "PHP 8.3.8 with comprehensive extension support",
    "backend": 83,
    "fpm_addr": "127.0.0.1:9083",
    "open_basedir": "/home:/tmp:/var/services/web:/var/services/homes",
    "extensions": [
      "opcache", "curl", "mysqli", "pdo_mysql", "pdo_sqlite",
      "sqlite3", "gd", "openssl", "xml", "dom", "simplexml",
      "xmlreader", "xmlwriter", "zlib", "fileinfo", "exif",
      "session", "filter", "ctype", "tokenizer", "soap",
      "sockets", "ftp", "gettext", "calendar", "bcmath",
      "posix", "pcntl"
    ],
    "php_settings": {
      "memory_limit": "256M",
      "max_execution_time": "300",
      "display_errors": "off",
      "error_reporting": "E_ALL & ~E_DEPRECATED & ~E_STRICT",
      "upload_max_filesize": "100M",
      "post_max_size": "100M",
      "max_input_time": "300",
      "date.timezone": "Europe/Paris"
    }
  }
}
EOF
fi

echo "[4/8] Creating v0012 installation scripts..."

# Create simplified postinst without manual PluginPackage.json modification
cat > "$BUILD_DIR/scripts/postinst" <<'EOF'
#!/bin/bash
# postinst script for php83 v0012 - Package Worker integration

# Log everything for debugging
exec >> /var/log/php83-install.log 2>&1
echo "[$(date)] === Starting postinst v0012 ==="#

SYNOPKG_PKGNAME="php83"
SYNOPKG_PKGDEST="/var/packages/${SYNOPKG_PKGNAME}/target"

echo "[$(date)] SYNOPKG_PKGDEST: ${SYNOPKG_PKGDEST}"

# Create necessary directories
mkdir -p /var/packages/php83/var/sessions
mkdir -p /var/packages/php83/var/tmp
mkdir -p /var/packages/php83/var/log
mkdir -p /var/packages/php83/var/run

# Set permissions
chmod 1733 /var/packages/php83/var/sessions
chmod 1777 /var/packages/php83/var/tmp
chmod 755 /var/packages/php83/var/log
chmod 755 /var/packages/php83/var/run

# Set ownership to http user
chown -R http:http /var/packages/php83/var

echo "[$(date)] Directories and permissions set"

# Fix binary permissions
echo "[$(date)] Fixing binary permissions..."
chmod 755 "${SYNOPKG_PKGDEST}"/package/bin/* 2>/dev/null || true
chmod 755 "${SYNOPKG_PKGDEST}"/package/sbin/* 2>/dev/null || true
find "${SYNOPKG_PKGDEST}/package/lib" -name "*.so*" -exec chmod 755 {} \; 2>/dev/null || true
echo "[$(date)] Binary permissions fixed"

# Package Worker handles PluginPackage.json registration automatically
# The pkg_worker="WebStation" in INFO tells DSM to use Package Worker
# PKG_PHP.json in target/ will be synced to Web Station automatically
echo "[$(date)] Package Worker will handle Web Station registration automatically"
echo "[$(date)] PKG_PHP.json location: ${SYNOPKG_PKGDEST}/package/PKG_PHP.json"

# Reload Web Station to pick up new package
if command -v systemctl >/dev/null 2>&1; then
    echo "[$(date)] Reloading nginx with systemctl"
    systemctl reload nginx 2>&1 || true
fi

if command -v synowebservice >/dev/null 2>&1; then
    echo "[$(date)] Notifying Web Station to reload config"
    synowebservice --reload-config 2>&1 || true
fi

echo "[$(date)] PHP 8.3 v0012 installation completed"
echo "[$(date)] === Ending postinst ==="#

exit 0
EOF

# Create simplified postuninst
cat > "$BUILD_DIR/scripts/postuninst" <<'EOF'
#!/bin/bash
# postuninst script for php83 v0012

# Log everything
exec >> /var/log/php83-install.log 2>&1
echo "[$(date)] === Starting postuninst v0012 ==="

# Package Worker handles PluginPackage.json cleanup automatically
# We only clean up backend files manually
echo "[$(date)] Cleaning up Web Station backend files..."

# Remove from app.d
echo "[$(date)] Removing backend files..."
rm -f /usr/syno/etc/www/app.d/php83.json
rm -f /usr/syno/etc/www/app.d/backend-php83.json

# Remove from WebStation backends if it exists
if [ -f "/usr/syno/etc/packages/WebStation/backends/backend-php83.json" ]; then
    rm -f /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    echo "[$(date)] Removed from WebStation backends"
fi

# Reload Web Station configuration
echo "[$(date)] Reloading Web Station..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl reload nginx 2>&1 || true
elif command -v synoservicectl >/dev/null 2>&1; then
    synoservicectl --reload nginx 2>&1 || true
fi

if command -v synowebservice >/dev/null 2>&1; then
    synowebservice --reload-config 2>&1 || true
fi

# Clean up runtime files
echo "[$(date)] Cleaning up runtime files..."
rm -f /var/packages/php83/var/run/php-fpm.pid

echo "[$(date)] Cleanup completed"
echo "[$(date)] === Ending postuninst ==="

exit 0
EOF

# Make scripts executable
chmod +x "$BUILD_DIR/scripts/"*

echo "[5/8] Creating INFO file..."
cat > "$BUILD_DIR/INFO" <<'EOF'
package="php83"
version="8.3.8-0012"
description="PHP 8.3.8 with FPM and CLI"
arch="geminilake"
os_min_ver="7.0-40000"
maintainer="Gilles"
displayname="PHP 8.3"
startable="yes"
ctl_stop="yes"
install_provide_packages="PHP"
support_conf_folder="yes"
pkg_worker="WebStation"
EOF

echo "[6/8] Creating package.tgz..."
cd "$BUILD_DIR"
tar czf package.tgz package/
PACKAGE_SIZE=$(stat -c%s package.tgz)
echo "   Package size: $PACKAGE_SIZE bytes"

echo "[7/8] Creating SPK file..."
# Create conf directory with privilege file
mkdir -p "$BUILD_DIR/conf"
cat > "$BUILD_DIR/conf/privilege" <<'EOF'
{
    "defaults": {
        "run-as": "package"
    }
}
EOF

# Copy icons if they exist
cp /var/packages/php83/target/PACKAGE_ICON*.PNG "$BUILD_DIR/" 2>/dev/null || true

# Create SPK
SPK_NAME="php83_8.3.8-0012_geminilake.spk"
tar --format=ustar -cf "$SPK_NAME" \
    INFO \
    $([ -f PACKAGE_ICON.PNG ] && echo "PACKAGE_ICON.PNG") \
    $([ -f PACKAGE_ICON_256.PNG ] && echo "PACKAGE_ICON_256.PNG") \
    scripts \
    conf \
    package.tgz

SPK_SIZE=$(stat -c%s "$SPK_NAME")
SPK_MD5=$(md5sum "$SPK_NAME" | awk '{print $1}')

echo "[8/8] Build complete!"
echo ""
echo "==================================="
echo "Package: $SPK_NAME"
echo "Size: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "Location: $BUILD_DIR/$SPK_NAME"
echo "==================================="
echo ""
echo "MD5 checksum file:"
echo "$SPK_MD5  $SPK_NAME" > "${SPK_NAME}.md5"
cat "${SPK_NAME}.md5"
echo ""
echo "To transfer to Windows:"
echo "scp -P 44 $BUILD_DIR/$SPK_NAME gilles@192.168.1.1:/path/to/destination/"
