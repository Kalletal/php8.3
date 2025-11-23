#!/bin/bash
# Build script for v0013 - Ajoute PKG_PHP.json à v0012
set -e

echo "=== Build PHP 8.3 v0013 avec Package Worker ==="

# Vérifier que v0012 existe
if [ ! -f "php83_8.3.8-0012_geminilake.spk" ]; then
    echo "ERREUR: php83_8.3.8-0012_geminilake.spk non trouvé"
    exit 1
fi

# Créer répertoire de travail
BUILD_DIR="build-v0013-$$"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/6] Extraction du SPK v0012..."
tar -xf ../php83_8.3.8-0012_geminilake.spk

echo "[2/6] Extraction de package.tgz..."
tar -xzf package.tgz

echo "[3/6] Création de PKG_PHP.json..."
cat > package/PKG_PHP.json <<'EOF'
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
	"version": "8.3.8-0013"
}
EOF

echo "   PKG_PHP.json créé:"
ls -la package/PKG_PHP.json

echo "[4/6] Mise à jour du numéro de version..."
sed -i 's/8.3.8-0012/8.3.8-0013/g' INFO
sed -i 's/8.3.8-0012/8.3.8-0013/g' scripts/postinst

echo "[5/6] Recréation de package.tgz..."
tar czf package.tgz package/
rm -rf package/

echo "[6/6] Création du SPK v0013..."
tar --format=ustar -cf ../php83_8.3.8-0013_geminilake.spk INFO WIZARD_UIFILES conf package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build terminé ==="
SPK_SIZE=$(stat -c%s php83_8.3.8-0013_geminilake.spk)
SPK_MD5=$(md5sum php83_8.3.8-0013_geminilake.spk | awk '{print $1}')
echo "Fichier: php83_8.3.8-0013_geminilake.spk"
echo "Taille: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "$SPK_MD5  php83_8.3.8-0013_geminilake.spk" > php83_8.3.8-0013_geminilake.spk.md5
echo ""
echo "Modification apportée:"
echo "  + Ajout de package/PKG_PHP.json pour Package Worker"
echo ""
echo "Vérification:"
tar -tf php83_8.3.8-0013_geminilake.spk | head -20
