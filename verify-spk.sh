#!/bin/bash
# Script de vérification détaillée du package SPK

SPK_FILE="${1:-dist/php83_8.3.8-0001_geminilake.spk}"

if [ ! -f "$SPK_FILE" ]; then
    echo "Erreur: Fichier $SPK_FILE introuvable"
    exit 1
fi

echo "=========================================="
echo "Vérification du package: $SPK_FILE"
echo "=========================================="
echo

# 1. Type de fichier
echo "1. Type de fichier:"
file "$SPK_FILE"
echo

# 2. Taille
echo "2. Taille du package:"
ls -lh "$SPK_FILE"
echo

# 3. Contenu du tar
echo "3. Liste des fichiers dans le SPK:"
tar -tvf "$SPK_FILE" 2>&1 | head -30
echo

# 4. Extraction temporaire
TEMP_DIR=$(mktemp -d)
echo "4. Extraction dans $TEMP_DIR"
cd "$TEMP_DIR"
tar -xf "$SPK_FILE" 2>&1

# 5. Vérification INFO
echo
echo "5. Contenu du fichier INFO:"
cat INFO
echo

# 6. Vérification des champs obligatoires
echo "6. Vérification des champs obligatoires dans INFO:"
for field in package version description arch os_min_ver maintainer; do
    if grep -q "^${field}=" INFO; then
        echo "  ✓ $field présent"
    else
        echo "  ✗ $field MANQUANT"
    fi
done
echo

# 7. Vérification privilege
echo "7. Contenu de conf/privilege:"
if [ -f conf/privilege ]; then
    cat conf/privilege
    echo
    # Vérifier que c'est un JSON valide
    if command -v jq &> /dev/null; then
        if jq empty conf/privilege 2>/dev/null; then
            echo "  ✓ JSON valide"
        else
            echo "  ✗ JSON invalide"
        fi
    fi
else
    echo "  ✗ Fichier conf/privilege manquant"
fi
echo

# 8. Vérification des scripts
echo "8. Scripts présents:"
if [ -d scripts ]; then
    ls -lh scripts/
else
    echo "  ✗ Répertoire scripts manquant"
fi
echo

# 9. Vérification des icônes
echo "9. Icônes présentes:"
ls -lh PACKAGE_ICON*.PNG 2>/dev/null || echo "  ✗ Aucune icône trouvée"
echo

# 10. Vérification du package.tgz
echo "10. Vérification de package.tgz:"
if [ -f package.tgz ]; then
    echo "  Taille: $(ls -lh package.tgz | awk '{print $5}')"
    echo "  Type: $(file -b package.tgz)"
    echo "  Contenu (premiers fichiers):"
    tar -tzf package.tgz 2>&1 | head -20
else
    echo "  ✗ package.tgz manquant"
fi
echo

# 11. Vérification WIZARD_UIFILES
echo "11. Assistant d'installation:"
if [ -d WIZARD_UIFILES ]; then
    ls -lh WIZARD_UIFILES/
else
    echo "  Pas d'assistant d'installation"
fi
echo

# 12. Vérification des permissions
echo "12. Permissions des fichiers racine:"
ls -la | grep -v "^d" | grep -v "^total"
echo

# 13. Ordre des fichiers dans le tar
echo "13. Ordre des fichiers dans le SPK (premiers 10):"
tar -tf "$SPK_FILE" 2>&1 | head -10
echo

# Nettoyage
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "=========================================="
echo "Vérification terminée"
echo "=========================================="
