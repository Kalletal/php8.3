#!/bin/bash
################################################################################
# Script de Test Complet PHP 8.3 pour Synology NAS
# NAS: ServeurNAS (192.168.1.47)
# Usage: Copier ce script sur le NAS et l'exécuter
################################################################################

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PACKAGE_NAME="php83"
VERSION="8.3.8-0009"
PKG_DIR="/var/packages/${PACKAGE_NAME}"
TARGET_DIR="${PKG_DIR}/target"
VAR_DIR="${PKG_DIR}/var"
CONF_DIR="${PKG_DIR}/conf"

################################################################################
# Fonctions utilitaires
################################################################################

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
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_command() {
    local cmd=$1
    local desc=$2

    if command -v "$cmd" &> /dev/null; then
        print_success "$desc trouvé: $(command -v $cmd)"
        return 0
    else
        print_error "$desc introuvable"
        return 1
    fi
}

check_file() {
    local file=$1
    local desc=$2

    if [ -f "$file" ]; then
        print_success "$desc existe"
        ls -lh "$file"
        return 0
    else
        print_error "$desc introuvable: $file"
        return 1
    fi
}

check_directory() {
    local dir=$1
    local desc=$2

    if [ -d "$dir" ]; then
        print_success "$desc existe"
        ls -ld "$dir"
        return 0
    else
        print_error "$desc introuvable: $dir"
        return 1
    fi
}

################################################################################
# PHASE 1: Informations système
################################################################################

print_header "PHASE 1: Informations Système"

echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "DSM Version:"
cat /etc.defaults/VERSION 2>/dev/null || cat /etc/synoinfo.conf | grep productversion
echo ""

print_info "Utilisateur actuel: $(whoami)"
print_info "Groupes: $(groups)"

################################################################################
# PHASE 2: Vérification de l'installation du package
################################################################################

print_header "PHASE 2: Vérification de l'installation du package"

# Vérifier que le package est installé
if [ -d "$PKG_DIR" ]; then
    print_success "Package ${PACKAGE_NAME} installé"
    ls -la "$PKG_DIR"
else
    print_error "Package ${PACKAGE_NAME} NON installé"
    echo ""
    echo "Pour installer le package:"
    echo "1. Connectez-vous à DSM"
    echo "2. Ouvrez le Centre de paquets"
    echo "3. Cliquez sur 'Installation manuelle'"
    echo "4. Sélectionnez le fichier php83_8.3.8-0009_geminilake.spk"
    exit 1
fi

# Vérifier la structure des répertoires
echo ""
check_directory "$TARGET_DIR" "Répertoire target"
check_directory "$VAR_DIR" "Répertoire var"
check_directory "$CONF_DIR" "Répertoire conf"

################################################################################
# PHASE 3: Vérification des binaires PHP
################################################################################

print_header "PHASE 3: Vérification des binaires PHP"

# Vérifier php CLI
if check_file "${TARGET_DIR}/bin/php" "Binaire PHP CLI"; then
    echo ""
    print_info "Version PHP:"
    ${TARGET_DIR}/bin/php -v
    echo ""
fi

# Vérifier php-fpm
if check_file "${TARGET_DIR}/sbin/php-fpm" "Binaire PHP-FPM"; then
    echo ""
    print_info "Version PHP-FPM:"
    ${TARGET_DIR}/sbin/php-fpm -v
    echo ""
fi

# Vérifier php-cgi
check_file "${TARGET_DIR}/bin/php-cgi" "Binaire PHP-CGI"

# Vérifier phpdbg
check_file "${TARGET_DIR}/bin/phpdbg" "Binaire PHPdbg"

################################################################################
# PHASE 4: Vérification des extensions PHP
################################################################################

print_header "PHASE 4: Vérification des extensions PHP"

print_info "Extensions compilées:"
${TARGET_DIR}/bin/php -m

echo ""
print_info "Extensions chargées:"
LOADED_EXTENSIONS=$(${TARGET_DIR}/bin/php -r 'echo implode("\n", get_loaded_extensions());')
EXTENSION_COUNT=$(echo "$LOADED_EXTENSIONS" | wc -l)
print_success "$EXTENSION_COUNT extensions chargées"

echo ""
print_info "Vérification des extensions critiques:"
for ext in opcache curl mysqli pdo_mysql gd mbstring openssl; do
    if echo "$LOADED_EXTENSIONS" | grep -qi "^${ext}$"; then
        print_success "Extension $ext chargée"
    else
        print_warning "Extension $ext NON chargée"
    fi
done

################################################################################
# PHASE 5: Vérification des fichiers de configuration
################################################################################

print_header "PHASE 5: Vérification des fichiers de configuration"

# php.ini
if check_file "${TARGET_DIR}/conf/php.ini" "Fichier php.ini"; then
    echo ""
    print_info "Paramètres php.ini importants:"
    grep -E "^(memory_limit|upload_max_filesize|post_max_size|max_execution_time|display_errors|error_reporting)" \
        ${TARGET_DIR}/conf/php.ini || echo "Aucun paramètre trouvé"
    echo ""
fi

# php-fpm.conf
check_file "${TARGET_DIR}/conf/php-fpm.conf" "Fichier php-fpm.conf"

# Test de configuration PHP-FPM
echo ""
print_info "Test de la configuration PHP-FPM:"
if ${TARGET_DIR}/sbin/php-fpm --fpm-config ${TARGET_DIR}/conf/php-fpm.conf --test 2>&1; then
    print_success "Configuration PHP-FPM valide"
else
    print_error "Configuration PHP-FPM invalide"
fi

################################################################################
# PHASE 6: Vérification du service
################################################################################

print_header "PHASE 6: Vérification du service"

# Vérifier l'état du service avec synoservicectl
print_info "État du service pkgctl-${PACKAGE_NAME}:"
if synoservicectl --status pkgctl-${PACKAGE_NAME} 2>/dev/null; then
    print_success "Service pkgctl-${PACKAGE_NAME} en cours d'exécution"
else
    print_warning "Service pkgctl-${PACKAGE_NAME} arrêté ou non trouvé"
    echo ""
    echo "Pour démarrer le service:"
    echo "  sudo synoservicectl --start pkgctl-${PACKAGE_NAME}"
fi

# Vérifier le socket PHP-FPM
echo ""
if [ -S "${VAR_DIR}/run/php-fpm.sock" ]; then
    print_success "Socket PHP-FPM existe"
    ls -lh "${VAR_DIR}/run/php-fpm.sock"
else
    print_warning "Socket PHP-FPM introuvable: ${VAR_DIR}/run/php-fpm.sock"
fi

# Vérifier le processus PHP-FPM
echo ""
print_info "Processus PHP-FPM:"
if ps aux | grep -v grep | grep php-fpm | grep ${PACKAGE_NAME}; then
    print_success "Processus PHP-FPM en cours d'exécution"
else
    print_warning "Aucun processus PHP-FPM trouvé"
fi

################################################################################
# PHASE 7: Vérification des logs
################################################################################

print_header "PHASE 7: Vérification des logs"

# Logs PHP-FPM
if [ -f "${VAR_DIR}/log/php-fpm.log" ]; then
    print_success "Log PHP-FPM trouvé"
    echo ""
    print_info "Dernières lignes du log PHP-FPM:"
    tail -20 "${VAR_DIR}/log/php-fpm.log" 2>/dev/null || echo "Log vide"
else
    print_warning "Log PHP-FPM introuvable"
fi

echo ""

# Logs d'erreurs PHP
if [ -f "${VAR_DIR}/log/php_errors.log" ]; then
    print_success "Log des erreurs PHP trouvé"
    echo ""
    print_info "Dernières erreurs PHP:"
    tail -20 "${VAR_DIR}/log/php_errors.log" 2>/dev/null || echo "Aucune erreur"
else
    print_info "Log des erreurs PHP introuvable (normal si aucune erreur)"
fi

echo ""

# Log du package
if [ -f "/var/log/packages/${PACKAGE_NAME}.log" ]; then
    print_success "Log du package trouvé"
    echo ""
    print_info "Dernières lignes du log package:"
    tail -20 "/var/log/packages/${PACKAGE_NAME}.log" 2>/dev/null || echo "Log vide"
else
    print_warning "Log du package introuvable"
fi

################################################################################
# PHASE 8: Test fonctionnel PHP
################################################################################

print_header "PHASE 8: Test fonctionnel PHP"

# Créer un script de test PHP
TEST_FILE="${VAR_DIR}/tmp/test.php"
mkdir -p "${VAR_DIR}/tmp"
cat > "$TEST_FILE" <<'EOPHP'
<?php
echo "PHP Test Script\n";
echo "================\n\n";
echo "PHP Version: " . PHP_VERSION . "\n";
echo "Zend Version: " . zend_version() . "\n";
echo "Server API: " . php_sapi_name() . "\n\n";

echo "Extensions loaded: " . count(get_loaded_extensions()) . "\n\n";

// Test de base de données
if (extension_loaded('pdo_mysql')) {
    echo "✓ PDO MySQL disponible\n";
}
if (extension_loaded('mysqli')) {
    echo "✓ MySQLi disponible\n";
}

// Test cURL
if (extension_loaded('curl')) {
    echo "✓ cURL disponible\n";
}

// Test GD
if (extension_loaded('gd')) {
    echo "✓ GD disponible\n";
    $gdinfo = gd_info();
    echo "  - FreeType: " . ($gdinfo['FreeType Support'] ? 'Yes' : 'No') . "\n";
    echo "  - PNG: " . ($gdinfo['PNG Support'] ? 'Yes' : 'No') . "\n";
    echo "  - JPEG: " . ($gdinfo['JPEG Support'] ? 'Yes' : 'No') . "\n";
}

// Test mbstring
if (extension_loaded('mbstring')) {
    echo "✓ Mbstring disponible\n";
}

// Test OpenSSL
if (extension_loaded('openssl')) {
    echo "✓ OpenSSL disponible\n";
    echo "  - Version: " . OPENSSL_VERSION_TEXT . "\n";
}

echo "\nTest terminé avec succès!\n";
EOPHP

print_info "Exécution du script de test PHP:"
if ${TARGET_DIR}/bin/php "$TEST_FILE"; then
    print_success "Test PHP réussi"
else
    print_error "Test PHP échoué"
fi

rm -f "$TEST_FILE"

################################################################################
# PHASE 9: Vérification Web Station (si disponible)
################################################################################

print_header "PHASE 9: Vérification Web Station"

# Vérifier si Web Station est installé
if [ -d "/var/packages/WebStation" ]; then
    print_success "Web Station installé"

    # Vérifier le fichier backend.json
    if [ -f "${TARGET_DIR}/conf/backend.json" ]; then
        print_success "Fichier backend.json trouvé"
        echo ""
        print_info "Contenu de backend.json:"
        cat "${TARGET_DIR}/conf/backend.json"
        echo ""
    else
        print_warning "Fichier backend.json introuvable"
    fi

    # Vérifier l'enregistrement dans Web Station
    WS_BACKEND_DIR="/usr/syno/etc/packages/WebStation/backends"
    if [ -f "${WS_BACKEND_DIR}/backend-${PACKAGE_NAME}.json" ]; then
        print_success "Backend ${PACKAGE_NAME} enregistré dans Web Station"
        cat "${WS_BACKEND_DIR}/backend-${PACKAGE_NAME}.json"
    else
        print_warning "Backend ${PACKAGE_NAME} NON enregistré dans Web Station"
        echo ""
        echo "Pour enregistrer manuellement:"
        echo "  sudo cp ${TARGET_DIR}/conf/backend.json ${WS_BACKEND_DIR}/backend-${PACKAGE_NAME}.json"
        echo "  sudo synoservicectl --reload nginx"
    fi
else
    print_info "Web Station non installé (optionnel)"
fi

################################################################################
# PHASE 10: Interface DSM
################################################################################

print_header "PHASE 10: Interface DSM"

# Vérifier app.config
if [ -f "${TARGET_DIR}/ui/app.config" ]; then
    print_success "Fichier app.config trouvé"
    echo ""
    print_info "Contenu de app.config:"
    cat "${TARGET_DIR}/ui/app.config"
    echo ""
else
    print_warning "Fichier app.config introuvable"
fi

# Vérifier index.html
if [ -f "${TARGET_DIR}/ui/index.html" ]; then
    print_success "Interface index.html trouvée"
else
    print_warning "Interface index.html introuvable"
fi

################################################################################
# RÉSUMÉ
################################################################################

print_header "RÉSUMÉ DES TESTS"

echo ""
echo -e "${BLUE}Package:${NC} ${PACKAGE_NAME} ${VERSION}"
echo -e "${BLUE}Installation:${NC} $PKG_DIR"
echo -e "${BLUE}PHP Version:${NC}"
${TARGET_DIR}/bin/php -v | head -1
echo -e "${BLUE}Extensions:${NC} ${EXTENSION_COUNT} chargées"
echo ""

# Compter les succès/échecs
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Vérifications critiques
CRITICAL_CHECKS=(
    "${TARGET_DIR}/bin/php"
    "${TARGET_DIR}/sbin/php-fpm"
    "${TARGET_DIR}/conf/php.ini"
    "${TARGET_DIR}/conf/php-fpm.conf"
)

for check in "${CRITICAL_CHECKS[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -e "$check" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
done

echo -e "${GREEN}Tests réussis:${NC} $PASSED_CHECKS/$TOTAL_CHECKS"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}Tests échoués:${NC} $FAILED_CHECKS/$TOTAL_CHECKS"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Test terminé!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Recommandations
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${YELLOW}Recommandations:${NC}"
    echo "- Vérifiez les logs pour plus de détails"
    echo "- Assurez-vous que le service est démarré"
    echo "- Vérifiez les permissions des fichiers"
    echo ""
fi

exit 0
