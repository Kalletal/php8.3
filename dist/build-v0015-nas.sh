#!/bin/bash
# Build script for v0015 - Déplace PKG_PHP.json à la racine de target
set -e

echo "=== Build PHP 8.3 v0015 - PKG_PHP.json à la racine ==="

# Vérifier que v0014 existe
if [ ! -f "php83_8.3.8-0014_geminilake.spk" ]; then
    echo "ERREUR: php83_8.3.8-0014_geminilake.spk non trouvé"
    exit 1
fi

# Créer répertoire de travail
BUILD_DIR="build-v0015-$$"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/6] Extraction du SPK v0014..."
tar -xf ../php83_8.3.8-0014_geminilake.spk

echo "[2/6] Extraction de package.tgz..."
tar -xzf package.tgz

echo "[3/6] Déplacement de PKG_PHP.json..."
if [ -f "package/PKG_PHP.json" ]; then
    echo "   PKG_PHP.json trouvé dans package/"
    mv package/PKG_PHP.json PKG_PHP.json
    echo "   Déplacé vers la racine"
    ls -la PKG_PHP.json
else
    echo "   ERREUR: PKG_PHP.json non trouvé dans package/"
    exit 1
fi

echo "[4/6] Mise à jour du numéro de version..."
sed -i 's/8.3.8-0014/8.3.8-0015/g' INFO
sed -i 's/8.3.8-0014/8.3.8-0015/g' scripts/postinst
sed -i 's/8.3.8-0014/8.3.8-0015/g' PKG_PHP.json

echo "[5/6] Recréation de package.tgz..."
tar czf package.tgz package/
rm -rf package/

echo "[6/6] Création du SPK v0015 avec PKG_PHP.json à la racine..."
# PKG_PHP.json est maintenant à la racine du SPK, sera copié vers /var/packages/php83/target/
tar --format=ustar -cf ../php83_8.3.8-0015_geminilake.spk INFO WIZARD_UIFILES conf PKG_PHP.json package.tgz scripts

cd ..
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build terminé ==="
SPK_SIZE=$(stat -c%s php83_8.3.8-0015_geminilake.spk)
SPK_MD5=$(md5sum php83_8.3.8-0015_geminilake.spk | awk '{print $1}')
echo "Fichier: php83_8.3.8-0015_geminilake.spk"
echo "Taille: $(numfmt --to=iec-i --suffix=B $SPK_SIZE)"
echo "MD5: $SPK_MD5"
echo "$SPK_MD5  php83_8.3.8-0015_geminilake.spk" > php83_8.3.8-0015_geminilake.spk.md5
echo ""
echo "Modification apportée:"
echo "  - PKG_PHP.json déplacé de package/ vers racine SPK"
echo "  - Sera installé à /var/packages/php83/target/PKG_PHP.json"
echo ""
echo "Structure du SPK:"
tar -tf php83_8.3.8-0015_geminilake.spk | head -20
