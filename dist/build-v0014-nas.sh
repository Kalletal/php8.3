#!/bin/bash
# Build script for v0014 - Supprime modification manuelle PluginPackage.json
set -e

echo "=== Build PHP 8.3 v0014 - Package Worker seul ==="

# Vérifier que v0013 existe
if [ ! -f "php83_8.3.8-0013_geminilake.spk" ]; then
    echo "ERREUR: php83_8.3.8-0013_geminilake.spk non trouvé"
    exit 1
fi

# Créer répertoire de travail
BUILD_DIR="build-v0014-$$"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/5] Extraction du SPK v0013..."
tar -xf ../php83_8.3.8-0013_geminilake.spk

echo "[2/5] Mise à jour du postinst - Suppression modification manuelle..."
# Créer nouveau postinst sans modification PluginPackage.json
cat > scripts/postinst <<'POSTINST_EOF'
#!/bin/bash
# postinst script for php83

# Log everything for debugging
exec >> /var/log/php83-install.log 2>&1
echo "[$(date)] === Starting postinst ==="

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

# Fix binary permissions (needed when building on Windows/Git Bash where execute bits may not be preserved)
echo "[$(date)] Fixing binary permissions..."
chmod 755 "${SYNOPKG_PKGDEST}"/package/bin/* 2>/dev/null || true
chmod 755 "${SYNOPKG_PKGDEST}"/package/sbin/* 2>/dev/null || true
find "${SYNOPKG_PKGDEST}/package/lib" -name "*.so*" -exec chmod 755 {} \; 2>/dev/null || true
echo "[$(date)] Binary permissions fixed"

# Register with Web Station - place backend-php83.json in target directory
# According to Synology docs, JSON files in target/ are auto-copied to /usr/syno/etc/www/app.d/
BACKEND_JSON="${SYNOPKG_PKGDEST}/backend-php83.json"
echo "[$(date)] Looking for backend-php83.json at: ${BACKEND_JSON}"

if [ -f "${BACKEND_JSON}" ]; then
    echo "[$(date)] backend-php83.json found in target, Web Station should auto-detect it"
    ls -la "${BACKEND_JSON}"

    # Manually copy to ensure it's in the right place
    mkdir -p /usr/syno/etc/www/app.d
    cp -f "${BACKEND_JSON}" /usr/syno/etc/www/app.d/backend-php83.json
    chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
    echo "[$(date)] Copied to /usr/syno/etc/www/app.d/backend-php83.json"
    ls -la /usr/syno/etc/www/app.d/backend-php83.json

    # Reload Web Station configuration using systemctl (DSM 7.x uses systemctl)
    if command -v systemctl >/dev/null 2>&1; then
        echo "[$(date)] Reloading nginx with systemctl"
        systemctl reload nginx 2>&1 || true
    elif command -v synoservicectl >/dev/null 2>&1; then
        echo "[$(date)] Reloading nginx with synoservicectl (legacy)"
        synoservicectl --reload nginx 2>&1 || true
    fi

    # Try synowebservice as alternative
    if command -v synowebservice >/dev/null 2>&1; then
        echo "[$(date)] Notifying Web Station to reload config"
        synowebservice --reload-config 2>&1 || true
    fi

    echo "[$(date)] Web Station backend registered"
else
    echo "[$(date)] ERROR: backend-php83.json not found at ${BACKEND_JSON}"
    echo "[$(date)] Contents of ${SYNOPKG_PKGDEST}:"
    ls -la "${SYNOPKG_PKGDEST}/" || echo "Directory does not exist"
fi

# Package Worker will handle PluginPackage.json registration via PKG_PHP.json
echo "[$(date)] Package Worker will register PHP 8.3 via PKG_PHP.json"
PKG_PHP="${SYNOPKG_PKGDEST}/package/PKG_PHP.json"
if [ -f "${PKG_PHP}" ]; then
    echo "[$(date)] PKG_PHP.json found at ${PKG_PHP}"
    ls -la "${PKG_PHP}"
else
    echo "[$(date)] WARNING: PKG_PHP.json not found at ${PKG_PHP}"
fi

echo "[$(date)] PHP 8.3 installation completed"
echo "[$(date)] === Ending postinst ==="

exit 0
POSTINST_EOF

chmod +x scripts/postinst
echo "   postinst simplifié créé"

echo "[3/5] Mise à jour du numéro de version..."
sed -i 's/8.3.8-0013/8.3.8-0014/g' INFO
sed -i 's/8.3.8-0013/8.3.8-0014/g' scripts/postinst

# Extraction et mise à jour de package.tgz pour la version
echo "[4/5] Mise à jour version dans PKG_PHP.json..."
tar -xzf package.tgz
sed -i 's/8.3.8-0013/8.3.8-0014/g' package/PKG_PHP.json
tar czf package.tgz package/
rm -rf package/

echo "[5/5] Création du SPK v0014..."
tar --format=ustar -cf ../php83_8.3.8-0014_geminilake.spk INFO WIZARD_UIFILES conf package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build terminé ==="
SPK_SIZE=$(stat -c%s php83_8.3.8-0014_geminilake.spk)
SPK_MD5=$(md5sum php83_8.3.8-0014_geminilake.spk | awk '{print $1}')
echo "Fichier: php83_8.3.8-0014_geminilake.spk"
echo "Taille: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "$SPK_MD5  php83_8.3.8-0014_geminilake.spk" > php83_8.3.8-0014_geminilake.spk.md5
echo ""
echo "Modification apportée:"
echo "  - Suppression modification manuelle PluginPackage.json du postinst"
echo "  - Package Worker gérera l'enregistrement via PKG_PHP.json"
echo ""
echo "Vérification:"
tar -tf php83_8.3.8-0014_geminilake.spk | head -15
