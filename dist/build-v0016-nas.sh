#!/bin/bash
# Build script for v0016 - Déplace backend-php83.json à la racine aussi
set -e

echo "=== Build PHP 8.3 v0016 - Tous les JSON à la racine ==="

# Vérifier que v0015 existe
if [ ! -f "php83_8.3.8-0015_geminilake.spk" ]; then
    echo "ERREUR: php83_8.3.8-0015_geminilake.spk non trouvé"
    exit 1
fi

# Créer répertoire de travail
BUILD_DIR="build-v0016-$$"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/6] Extraction du SPK v0015..."
tar -xf ../php83_8.3.8-0015_geminilake.spk

echo "[2/6] Extraction de package.tgz..."
tar -xzf package.tgz

echo "[3/6] Déplacement de backend-php83.json..."
if [ -f "package/backend-php83.json" ]; then
    echo "   backend-php83.json trouvé dans package/"
    mv package/backend-php83.json backend-php83.json
    echo "   Déplacé vers la racine"
    ls -la backend-php83.json
else
    echo "   ERREUR: backend-php83.json non trouvé dans package/"
    exit 1
fi

echo "[4/6] Mise à jour du numéro de version..."
sed -i 's/8.3.8-0015/8.3.8-0016/g' INFO
sed -i 's/8.3.8-0015/8.3.8-0016/g' scripts/postinst
sed -i 's/8.3.8-0015/8.3.8-0016/g' PKG_PHP.json

echo "[5/6] Recréation de package.tgz..."
tar czf package.tgz package/
rm -rf package/

echo "[6/6] Création du SPK v0016 avec tous les JSON à la racine..."
# backend-php83.json et PKG_PHP.json sont à la racine du SPK
# Seront copiés vers /var/packages/php83/target/
tar --format=ustar -cf ../php83_8.3.8-0016_geminilake.spk INFO WIZARD_UIFILES conf backend-php83.json PKG_PHP.json package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build terminé ==="
SPK_SIZE=$(stat -c%s php83_8.3.8-0016_geminilake.spk)
SPK_MD5=$(md5sum php83_8.3.8-0016_geminilake.spk | awk '{print $1}')
echo "Fichier: php83_8.3.8-0016_geminilake.spk"
echo "Taille: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "$SPK_MD5  php83_8.3.8-0016_geminilake.spk" > php83_8.3.8-0016_geminilake.spk.md5
echo ""
echo "Modifications apportées:"
echo "  - backend-php83.json à la racine (sera à /var/packages/php83/target/)"
echo "  - PKG_PHP.json à la racine (sera à /var/packages/php83/target/)"
echo ""
echo "Structure du SPK:"
tar -tf php83_8.3.8-0016_geminilake.spk | head -20
