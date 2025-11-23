#!/bin/bash
################################################################################
# Script de Vérification Pré-Déploiement
# Vérifie que le package SPK est correct avant le transfert sur le NAS
################################################################################

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SPK_FILE="${1:-dist/php83_8.3.8-0001_geminilake.spk}"
ERRORS=0

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

################################################################################
# Vérification 1: Existence du fichier SPK
################################################################################

print_header "Vérification 1: Fichier SPK"

if [ ! -f "$SPK_FILE" ]; then
    print_error "Fichier SPK introuvable: $SPK_FILE"
    echo ""
    echo "Construisez d'abord le package avec:"
    echo "  bash scripts/build-spk.sh"
    exit 1
fi

print_success "Fichier SPK trouvé"
ls -lh "$SPK_FILE"

# Vérifier la taille
SPK_SIZE=$(stat -c%s "$SPK_FILE" 2>/dev/null || stat -f%z "$SPK_FILE" 2>/dev/null || echo 0)
SPK_SIZE_MB=$((SPK_SIZE / 1024 / 1024))

if [ $SPK_SIZE_MB -lt 5 ]; then
    print_warning "Taille du SPK suspecte: ${SPK_SIZE_MB} MB (attendu: ~35 MB)"
    print_warning "Le package ne contient peut-être pas les binaires PHP"
elif [ $SPK_SIZE_MB -gt 100 ]; then
    print_warning "Taille du SPK très grande: ${SPK_SIZE_MB} MB"
else
    print_success "Taille du SPK correcte: ${SPK_SIZE_MB} MB"
fi

################################################################################
# Vérification 2: Structure du SPK
################################################################################

print_header "Vérification 2: Structure du SPK"

# Vérifier que c'est un tar
if file "$SPK_FILE" | grep -q "tar archive"; then
    print_success "Format tar valide"
else
    print_error "Format invalide (attendu: tar archive)"
fi

# Vérifier les fichiers essentiels
print_info "Vérification des fichiers essentiels..."

REQUIRED_FILES=(
    "INFO"
    "PACKAGE_ICON.PNG"
    "PACKAGE_ICON_256.PNG"
    "package.tgz"
    "scripts/preinst"
    "scripts/postinst"
    "scripts/preuninst"
    "scripts/postuninst"
    "scripts/service-setup"
    "scripts/start-stop-status"
    "conf/privilege"
    "conf/resource.conf"
    "WIZARD_UIFILES/install_uifile"
)

for file in "${REQUIRED_FILES[@]}"; do
    if tar -tf "$SPK_FILE" 2>/dev/null | grep -q "^${file}$"; then
        print_success "$file présent"
    else
        print_error "$file manquant"
    fi
done

################################################################################
# Vérification 3: Fichier INFO
################################################################################

print_header "Vérification 3: Fichier INFO"

INFO_CONTENT=$(tar -xOf "$SPK_FILE" INFO 2>/dev/null)

if [ -z "$INFO_CONTENT" ]; then
    print_error "Impossible de lire le fichier INFO"
else
    print_success "Fichier INFO lisible"
    echo ""
    echo "$INFO_CONTENT"
    echo ""

    # Vérifier les champs obligatoires
    REQUIRED_FIELDS=("package" "version" "description" "arch" "os_min_ver" "maintainer")

    for field in "${REQUIRED_FIELDS[@]}"; do
        if echo "$INFO_CONTENT" | grep -q "^${field}="; then
            VALUE=$(echo "$INFO_CONTENT" | grep "^${field}=" | cut -d'=' -f2- | tr -d '"')
            print_success "$field = $VALUE"
        else
            print_error "Champ manquant: $field"
        fi
    done
fi

################################################################################
# Vérification 4: Contenu de package.tgz
################################################################################

print_header "Vérification 4: Contenu de package.tgz"

print_info "Extraction de package.tgz pour vérification..."

PACKAGE_CONTENT=$(tar -xOf "$SPK_FILE" package.tgz 2>/dev/null | tar -tz 2>/dev/null)

if [ -z "$PACKAGE_CONTENT" ]; then
    print_error "Impossible de lire package.tgz"
else
    print_success "package.tgz lisible"

    # Compter les fichiers
    FILE_COUNT=$(echo "$PACKAGE_CONTENT" | wc -l)
    print_info "Nombre de fichiers dans package.tgz: $FILE_COUNT"

    # Vérifier les binaires PHP
    echo ""
    print_info "Vérification des binaires PHP..."

    if echo "$PACKAGE_CONTENT" | grep -q "package/bin/php$"; then
        print_success "Binaire php présent"
    else
        print_error "Binaire php manquant"
    fi

    if echo "$PACKAGE_CONTENT" | grep -q "package/sbin/php-fpm$"; then
        print_success "Binaire php-fpm présent"
    else
        print_error "Binaire php-fpm manquant"
    fi

    if echo "$PACKAGE_CONTENT" | grep -q "package/bin/php-cgi$"; then
        print_success "Binaire php-cgi présent"
    else
        print_warning "Binaire php-cgi manquant (optionnel)"
    fi

    # Vérifier les extensions
    echo ""
    print_info "Vérification des extensions PHP..."

    EXT_COUNT=$(echo "$PACKAGE_CONTENT" | grep -c "\.so$" || echo 0)

    if [ $EXT_COUNT -ge 30 ]; then
        print_success "Extensions PHP trouvées: $EXT_COUNT"
    elif [ $EXT_COUNT -gt 0 ]; then
        print_warning "Nombre d'extensions faible: $EXT_COUNT (attendu: 36)"
    else
        print_error "Aucune extension PHP trouvée"
    fi

    # Lister quelques extensions essentielles
    CRITICAL_EXTENSIONS=("opcache.so" "curl.so" "mysqli.so" "pdo_mysql.so" "gd.so" "mbstring.so")

    for ext in "${CRITICAL_EXTENSIONS[@]}"; do
        if echo "$PACKAGE_CONTENT" | grep -q "$ext$"; then
            print_success "Extension critique $ext présente"
        else
            print_warning "Extension critique $ext manquante"
        fi
    done

    # Vérifier les bibliothèques
    echo ""
    print_info "Vérification des bibliothèques partagées..."

    LIB_COUNT=$(echo "$PACKAGE_CONTENT" | grep "package/lib/.*\.so" | wc -l)

    if [ $LIB_COUNT -ge 10 ]; then
        print_success "Bibliothèques trouvées: $LIB_COUNT"
    else
        print_warning "Nombre de bibliothèques faible: $LIB_COUNT"
    fi

    # Vérifier les fichiers de configuration
    echo ""
    print_info "Vérification des fichiers de configuration..."

    CONFIG_FILES=(
        "package/conf/php.ini"
        "package/conf/php-fpm.conf"
        "package/conf/pkgctl-php83.sc"
        "package/conf/backend.json"
        "package/conf/extension_options.json"
    )

    for conf in "${CONFIG_FILES[@]}"; do
        if echo "$PACKAGE_CONTENT" | grep -q "^${conf}$"; then
            print_success "$(basename $conf) présent"
        else
            print_warning "$(basename $conf) manquant"
        fi
    done

    # Vérifier l'interface DSM
    echo ""
    print_info "Vérification de l'interface DSM..."

    if echo "$PACKAGE_CONTENT" | grep -q "package/ui/app.config$"; then
        print_success "app.config présent"
    else
        print_warning "app.config manquant"
    fi

    if echo "$PACKAGE_CONTENT" | grep -q "package/ui/index.html$"; then
        print_success "index.html présent"
    else
        print_warning "index.html manquant"
    fi
fi

################################################################################
# Vérification 5: Assistant d'installation
################################################################################

print_header "Vérification 5: Assistant d'installation"

WIZARD_CONTENT=$(tar -xOf "$SPK_FILE" WIZARD_UIFILES/install_uifile 2>/dev/null)

if [ -z "$WIZARD_CONTENT" ]; then
    print_error "Impossible de lire install_uifile"
else
    print_success "install_uifile lisible"

    # Vérifier que c'est du JSON
    if echo "$WIZARD_CONTENT" | grep -q "custom_render_fn"; then
        print_success "Format JSON détecté"
    else
        print_warning "Format inattendu"
    fi

    # Vérifier les langues
    if echo "$WIZARD_CONTENT" | grep -q '"en":'; then
        print_success "Traduction anglaise présente"
    fi

    if echo "$WIZARD_CONTENT" | grep -q '"fre":'; then
        print_success "Traduction française présente"
    fi

    # Compter les extensions dans le wizard
    WIZARD_EXT_COUNT=$(echo "$WIZARD_CONTENT" | grep -o "pkgwizard_ext_" | wc -l)
    print_info "Extensions dans le wizard: $WIZARD_EXT_COUNT"
fi

################################################################################
# Vérification 6: Permissions et privilèges
################################################################################

print_header "Vérification 6: Permissions et privilèges"

PRIVILEGE_CONTENT=$(tar -xOf "$SPK_FILE" conf/privilege 2>/dev/null)

if [ -z "$PRIVILEGE_CONTENT" ]; then
    print_error "Impossible de lire conf/privilege"
else
    print_success "conf/privilege lisible"
    echo ""
    echo "$PRIVILEGE_CONTENT"

    # Vérifier que c'est du JSON valide
    if echo "$PRIVILEGE_CONTENT" | grep -q "run-as"; then
        print_success "Format JSON détecté"
    fi
fi

################################################################################
# Vérification 7: Resource configuration
################################################################################

print_header "Vérification 7: Configuration des ressources"

RESOURCE_CONTENT=$(tar -xOf "$SPK_FILE" conf/resource.conf 2>/dev/null)

if [ -z "$RESOURCE_CONTENT" ]; then
    print_error "Impossible de lire conf/resource.conf"
else
    print_success "conf/resource.conf lisible"
    echo ""
    echo "$RESOURCE_CONTENT"
fi

################################################################################
# RÉSUMÉ
################################################################################

print_header "RÉSUMÉ DE LA VÉRIFICATION"

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les tests ont réussi !${NC}"
    echo ""
    echo "Le package est prêt pour le déploiement sur le NAS."
    echo ""
    echo "Prochaines étapes:"
    echo "  1. Transférer le SPK sur le NAS:"
    echo "     bash deploy-to-nas.sh"
    echo ""
    echo "  2. Ou suivre le guide complet:"
    echo "     cat GUIDE_TESTS_NAS.md"
    echo ""
    exit 0
else
    echo -e "${RED}✗ $ERRORS erreur(s) détectée(s)${NC}"
    echo ""
    echo "Veuillez corriger les erreurs avant de déployer sur le NAS."
    echo ""
    echo "Actions possibles:"
    echo "  - Reconstruire le package: bash scripts/build-spk.sh"
    echo "  - Vérifier les binaires PHP dans spk/php83/files/php/"
    echo "  - Consulter la documentation: cat README.md"
    echo ""
    exit 1
fi
