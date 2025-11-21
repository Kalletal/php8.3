#!/bin/bash
# Script de vérification du package PHP 8.3
# Vérifie que tous les fichiers nécessaires sont présents

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BUILD_DIR="dist/build"
SPK_FILE="dist/php83_8.3.8-0001_geminilake.spk"

echo "========================================="
echo "Vérification du package PHP 8.3"
echo "========================================="
echo ""

# Fonction de vérification
check_file() {
    local file=$1
    local desc=$2

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc"
        return 0
    else
        echo -e "${RED}✗${NC} $desc (MANQUANT)"
        return 1
    fi
}

check_content() {
    local file=$1
    local pattern=$2
    local desc=$3

    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $desc"
        return 0
    else
        echo -e "${RED}✗${NC} $desc (NON TROUVÉ)"
        return 1
    fi
}

ERRORS=0

echo "1. Vérification des fichiers de configuration"
echo "----------------------------------------------"

check_file "$BUILD_DIR/INFO" "Fichier INFO présent" || ((ERRORS++))
check_content "$BUILD_DIR/INFO" 'dsmuidir="package/ui"' "dsmuidir correctement défini" || ((ERRORS++))
check_content "$BUILD_DIR/INFO" 'dsmappname="SYNO.SDS.PHP83"' "dsmappname correctement défini" || ((ERRORS++))

echo ""
echo "2. Vérification des fichiers UI"
echo "--------------------------------"

check_file "$BUILD_DIR/package/ui/app.config" "Fichier app.config présent" || ((ERRORS++))
check_file "$BUILD_DIR/package/ui/index.html" "Interface index.html présente" || ((ERRORS++))
check_file "$BUILD_DIR/package/ui/images/icon_72.png" "Icône UI présente" || ((ERRORS++))
check_content "$BUILD_DIR/package/ui/app.config" "SYNO.SDS.PHP83.Instance" "app.config avec bon identifiant" || ((ERRORS++))

echo ""
echo "3. Vérification Web Station"
echo "----------------------------"

check_file "$BUILD_DIR/package/conf/backend.json" "Fichier backend.json présent" || ((ERRORS++))
check_content "$BUILD_DIR/package/conf/backend.json" '"service": "php83"' "Service php83 défini" || ((ERRORS++))
check_content "$BUILD_DIR/package/conf/backend.json" '"type": "nginx_php"' "Type nginx_php défini" || ((ERRORS++))

echo ""
echo "4. Vérification des icônes"
echo "--------------------------"

check_file "$BUILD_DIR/PACKAGE_ICON_256.PNG" "Icône 256x256 présente" || ((ERRORS++))
check_file "$BUILD_DIR/PACKAGE_ICON_72.PNG" "Icône 72x72 présente" || ((ERRORS++))

echo ""
echo "5. Vérification des scripts"
echo "----------------------------"

check_file "$BUILD_DIR/scripts/postinst" "Script postinst présent" || ((ERRORS++))
check_file "$BUILD_DIR/scripts/postuninst" "Script postuninst présent" || ((ERRORS++))
check_content "$BUILD_DIR/scripts/postinst" "backend-php83.json" "Enregistrement Web Station dans postinst" || ((ERRORS++))
check_content "$BUILD_DIR/scripts/postuninst" "backend-php83.json" "Nettoyage Web Station dans postuninst" || ((ERRORS++))

echo ""
echo "6. Vérification du package final"
echo "---------------------------------"

check_file "$SPK_FILE" "Package SPK généré" || ((ERRORS++))

if [ -f "$SPK_FILE" ]; then
    SIZE=$(du -h "$SPK_FILE" | cut -f1)
    echo -e "${GREEN}✓${NC} Taille du package: $SIZE"

    MD5=$(md5sum "$SPK_FILE" | cut -d' ' -f1)
    echo -e "${GREEN}✓${NC} MD5: $MD5"
fi

echo ""
echo "7. Vérification de la structure package.tgz"
echo "--------------------------------------------"

cd "$BUILD_DIR"
if tar -tzf package.tgz package/ui/app.config >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} app.config dans package.tgz"
else
    echo -e "${RED}✗${NC} app.config ABSENT de package.tgz"
    ((ERRORS++))
fi

if tar -tzf package.tgz package/conf/backend.json >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} backend.json dans package.tgz"
else
    echo -e "${RED}✗${NC} backend.json ABSENT de package.tgz"
    ((ERRORS++))
fi

cd - >/dev/null

echo ""
echo "========================================="
echo "Résumé de la vérification"
echo "========================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les tests ont réussi !${NC}"
    echo ""
    echo "Le package est prêt pour l'installation."
    echo ""
    echo "Prochaines étapes :"
    echo "  1. Désinstaller l'ancienne version de PHP 8.3"
    echo "  2. Installer le nouveau package: $SPK_FILE"
    echo "  3. Vérifier que le bouton 'Ouvrir' apparaît"
    echo "  4. Vérifier PHP 8.3 dans Web Station → Paquets dorsaux"
    echo ""
    exit 0
else
    echo -e "${RED}✗ $ERRORS erreur(s) détectée(s)${NC}"
    echo ""
    echo "Veuillez corriger les erreurs ci-dessus avant de tester le package."
    echo ""
    exit 1
fi
