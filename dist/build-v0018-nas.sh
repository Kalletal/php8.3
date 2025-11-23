#!/bin/bash
# Build script for v0018 - Restaure l'enregistrement manuel dans PluginPackage.json
set -e

echo "=== Build PHP 8.3 v0018 - Enregistrement manuel PluginPackage.json ==="

# Vérifier que v0017 existe
if [ ! -f "php83_8.3.8-0017_geminilake.spk" ]; then
    echo "ERREUR: php83_8.3.8-0017_geminilake.spk non trouvé"
    exit 1
fi

# Vérifier que le nouveau postinst existe
if [ ! -f "postinst-v0018" ]; then
    echo "ERREUR: postinst-v0018 non trouvé"
    exit 1
fi

# Créer répertoire de travail
BUILD_DIR="build-v0018-$$"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/6] Extraction du SPK v0017..."
tar -xf ../php83_8.3.8-0017_geminilake.spk

echo "[2/6] Remplacement du script postinst..."
cp ../postinst-v0018 scripts/postinst
chmod +x scripts/postinst
echo "   Nouveau postinst copié"

echo "[3/6] Mise à jour du numéro de version..."
sed -i 's/8.3.8-0017/8.3.8-0018/g' INFO

echo "[4/6] Mise à jour de package.tgz (backend et PKG_PHP.json)..."
# Extraire package.tgz
tar -xzf package.tgz

# Mettre à jour les versions dans les JSON
if [ -f "backend-php83.json" ]; then
    sed -i 's/8.3.8-0017/8.3.8-0018/g' backend-php83.json
fi
if [ -f "PKG_PHP.json" ]; then
    sed -i 's/8.3.8-0017/8.3.8-0018/g' PKG_PHP.json
fi

# Recréer package.tgz
tar czf package.tgz backend-php83.json PKG_PHP.json package/
rm -rf backend-php83.json PKG_PHP.json package/

echo "[5/6] Création du SPK v0018..."
tar --format=ustar -cf ../php83_8.3.8-0018_geminilake.spk INFO WIZARD_UIFILES conf package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build terminé ==="
SPK_SIZE=$(stat -c%s php83_8.3.8-0018_geminilake.spk)
SPK_MD5=$(md5sum php83_8.3.8-0018_geminilake.spk | awk '{print $1}')
echo "Fichier: php83_8.3.8-0018_geminilake.spk"
echo "Taille: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "$SPK_MD5  php83_8.3.8-0018_geminilake.spk" > php83_8.3.8-0018_geminilake.spk.md5
echo ""
echo "Modifications apportées:"
echo "  - Script postinst restauré avec enregistrement manuel PluginPackage.json"
echo "  - Copie backend-php83.json vers /usr/syno/etc/www/app.d/backend-php83.json"
echo "  - Injection manuelle dans /usr/syno/etc/packages/WebStation/PluginPackage.json"
echo "  - Redémarrage nginx après enregistrement"
echo ""
