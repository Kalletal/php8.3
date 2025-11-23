#!/bin/bash
# Convertit la structure pkgsrc vers la structure officielle Synology
# SANS recompiler PHP - utilise des symlinks

set -e

echo "=== Conversion vers structure Synology officielle ==="

BUILD_DIR="build-synology-$$"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Extraire le SPK actuel
echo "[1/5] Extraction du SPK..."
tar -xf ../php83_8.3.8-0018_geminilake.spk

# Extraire package.tgz
echo "[2/5] Extraction de package.tgz..."
tar -xzf package.tgz

# Créer la nouvelle structure
echo "[3/5] Création de la structure Synology..."
mkdir -p synology-package/usr/local/bin
mkdir -p synology-package/misc
mkdir -p synology-package/lib

# Copier et créer symlinks pour les binaires
cp package/sbin/php-fpm synology-package/usr/local/bin/php83-fpm
cp package/bin/php-cgi synology-package/usr/local/bin/php83-cgi
cp package/bin/php synology-package/usr/local/bin/php83

# Copier les libs (avec la structure complète pour les extensions)
cp -r package/lib/* synology-package/lib/

# Adapter les configs
cp package/etc/php.ini synology-package/misc/php-fpm.ini
cp package/conf/default_settings.json synology-package/misc/
cp package/conf/extension_list.json synology-package/misc/

# Mettre à jour extension_dir dans default_settings.json
sed -i 's|/var/packages/php83/target/package/lib|/var/packages/PHP8.3/target/lib|g' \
    synology-package/misc/default_settings.json

# Mettre à jour include_path
sed -i 's|/var/packages/php83/target/package/lib|/var/packages/PHP8.3/target/lib|g' \
    synology-package/misc/default_settings.json

echo "[4/5] Mise à jour des fichiers de config..."

# Mettre à jour INFO
sed -i 's/package="php83"/package="PHP8.3"/g' INFO
sed -i 's/8.3.8-0018/8.3.8-0019/g' INFO

# Recréer package.tgz avec la nouvelle structure
echo "[5/5] Création du nouveau SPK..."
cd synology-package
tar czf ../package.tgz *
cd ..
rm -rf synology-package package

# Mettre à jour les JSONs
if [ -f "backend-php83.json" ]; then
    sed -i 's|/var/packages/php83/target/package|/var/packages/PHP8.3/target|g' backend-php83.json
    sed -i 's/8.3.8-0018/8.3.8-0019/g' backend-php83.json
fi

if [ -f "PKG_PHP.json" ]; then
    sed -i 's/8.3.8-0018/8.3.8-0019/g' PKG_PHP.json
fi

# Créer le SPK final
tar --format=ustar -cf ../PHP8.3_8.3.8-0019_geminilake.spk INFO WIZARD_UIFILES conf package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Conversion terminée ==="
SPK_FILE="PHP8.3_8.3.8-0019_geminilake.spk"
if [ -f "$SPK_FILE" ]; then
    SPK_SIZE=$(stat -c%s "$SPK_FILE" 2>/dev/null || stat -f%z "$SPK_FILE")
    SPK_MD5=$(md5sum "$SPK_FILE" 2>/dev/null | awk '{print $1}' || md5 -q "$SPK_FILE")
    echo "Fichier: $SPK_FILE"
    echo "Taille: $SPK_SIZE bytes"
    echo "MD5: $SPK_MD5"
    echo "$SPK_MD5  $SPK_FILE" > "${SPK_FILE}.md5"
    echo ""
    echo "Structure: Synology officielle (usr/local + misc)"
    echo "Nom: PHP8.3 (majuscules)"
    echo "Binaires: php83-fpm, php83-cgi (symlinks)"
fi
