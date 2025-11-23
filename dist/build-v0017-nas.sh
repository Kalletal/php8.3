#!/bin/bash
# Build script for v0017 - JSON à la racine de package.tgz (pas du SPK)
set -e

echo "=== Build PHP 8.3 v0017 - JSON à la racine de package.tgz ==="

# Vérifier que v0016 existe
if [ ! -f "php83_8.3.8-0016_geminilake.spk" ]; then
    echo "ERREUR: php83_8.3.8-0016_geminilake.spk non trouvé"
    exit 1
fi

# Créer répertoire de travail
BUILD_DIR="build-v0017-$$"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/7] Extraction du SPK v0016..."
tar -xf ../php83_8.3.8-0016_geminilake.spk

echo "[2/7] Extraction de package.tgz..."
tar -xzf package.tgz

echo "[3/7] Structure actuelle:"
ls -la
echo "Contenu de package/:"
ls -la package/ | head -10

echo "[4/7] Vérification des fichiers JSON..."
if [ ! -f "backend-php83.json" ]; then
    echo "   ERREUR: backend-php83.json non trouvé à la racine"
    exit 1
fi

if [ ! -f "PKG_PHP.json" ]; then
    echo "   ERREUR: PKG_PHP.json non trouvé à la racine"
    exit 1
fi

echo "   backend-php83.json: OK"
echo "   PKG_PHP.json: OK"

echo "[5/7] Nouvelle structure:"
ls -la
echo "   backend-php83.json et PKG_PHP.json sont maintenant à la racine"

echo "[6/7] Mise à jour du numéro de version..."
sed -i 's/8.3.8-0016/8.3.8-0017/g' INFO
sed -i 's/8.3.8-0016/8.3.8-0017/g' scripts/postinst
sed -i 's/8.3.8-0016/8.3.8-0017/g' PKG_PHP.json

echo "[7/7] Recréation de package.tgz avec JSON à la racine..."
# Créer package.tgz avec backend-php83.json et PKG_PHP.json à la racine
tar czf package.tgz backend-php83.json PKG_PHP.json package/
rm -rf backend-php83.json PKG_PHP.json package/

echo "[8/8] Création du SPK v0017..."
tar --format=ustar -cf ../php83_8.3.8-0017_geminilake.spk INFO WIZARD_UIFILES conf package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build terminé ==="
SPK_SIZE=$(stat -c%s php83_8.3.8-0017_geminilake.spk)
SPK_MD5=$(md5sum php83_8.3.8-0017_geminilake.spk | awk '{print $1}')
echo "Fichier: php83_8.3.8-0017_geminilake.spk"
echo "Taille: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "$SPK_MD5  php83_8.3.8-0017_geminilake.spk" > php83_8.3.8-0017_geminilake.spk.md5
echo ""
echo "Modifications apportées:"
echo "  - backend-php83.json et PKG_PHP.json à la RACINE de package.tgz"
echo "  - Seront extraits à /var/packages/php83/target/backend-php83.json"
echo "  - Seront extraits à /var/packages/php83/target/PKG_PHP.json"
echo ""
echo "Vérification de la structure de package.tgz:"
tar -tzf php83_8.3.8-0017_geminilake.spk | tar -xzf - package.tgz -O | tar -tz | head -20
