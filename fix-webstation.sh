#!/bin/bash
################################################################################
# Correctif Web Station pour PHP 8.3
# À exécuter sur le NAS après installation du package
#
# Usage: bash fix-webstation.sh
################################################################################

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

################################################################################

print_header "Correctif Web Station PHP 8.3"

# Vérifier que le package est installé
if [ ! -d "/var/packages/php83" ]; then
    print_error "Package PHP 8.3 non installé"
    exit 1
fi

print_success "Package PHP 8.3 installé"

# Vérifier que backend.json existe
BACKEND_SRC="/var/packages/php83/target/package/conf/backend.json"

if [ ! -f "$BACKEND_SRC" ]; then
    print_error "Fichier backend.json introuvable: $BACKEND_SRC"
    exit 1
fi

print_success "Fichier backend.json trouvé"

################################################################################
print_header "Étape 1: Correction du nom de fichier"

# Vérifier si l'ancien fichier mal nommé existe
if [ -f "/usr/syno/etc/www/app.d/php83.json" ]; then
    print_warning "Fichier mal nommé détecté: php83.json"
    print_info "Renommage en backend-php83.json..."

    sudo mv /usr/syno/etc/www/app.d/php83.json \
            /usr/syno/etc/www/app.d/backend-php83.json 2>&1

    if [ $? -eq 0 ]; then
        print_success "Fichier renommé"
    else
        print_error "Échec du renommage"
    fi
fi

################################################################################
print_header "Étape 2: Copie dans app.d"

if [ ! -f "/usr/syno/etc/www/app.d/backend-php83.json" ]; then
    print_info "Copie vers /usr/syno/etc/www/app.d/backend-php83.json"

    sudo mkdir -p /usr/syno/etc/www/app.d
    sudo cp "$BACKEND_SRC" /usr/syno/etc/www/app.d/backend-php83.json
    sudo chmod 644 /usr/syno/etc/www/app.d/backend-php83.json

    if [ $? -eq 0 ]; then
        print_success "Fichier copié dans app.d"
    else
        print_error "Échec de la copie"
    fi
else
    print_success "Fichier backend-php83.json déjà présent dans app.d"
fi

# Afficher le contenu
echo ""
print_info "Vérification du contenu:"
ls -lh /usr/syno/etc/www/app.d/backend-php83.json

################################################################################
print_header "Étape 3: Copie dans WebStation backends"

if [ -d "/usr/syno/etc/packages/WebStation" ]; then
    print_info "Web Station détecté, copie du backend"

    sudo mkdir -p /usr/syno/etc/packages/WebStation/backends
    sudo cp "$BACKEND_SRC" /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    sudo chmod 644 /usr/syno/etc/packages/WebStation/backends/backend-php83.json

    if [ $? -eq 0 ]; then
        print_success "Fichier copié dans WebStation/backends"
        ls -lh /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    else
        print_error "Échec de la copie dans WebStation/backends"
    fi
else
    print_warning "Répertoire Web Station non trouvé (peut-être pas installé)"
fi

################################################################################
print_header "Étape 4: Vérification PHP-FPM"

# Vérifier que PHP-FPM écoute sur le port
print_info "Vérification du port 9000 (PHP-FPM)..."

if netstat -tlnp 2>/dev/null | grep -q ":9000 "; then
    print_success "PHP-FPM écoute sur le port 9000"
    netstat -tlnp 2>/dev/null | grep ":9000 " | head -1
elif ss -tlnp 2>/dev/null | grep -q ":9000 "; then
    print_success "PHP-FPM écoute sur le port 9000"
    ss -tlnp 2>/dev/null | grep ":9000 " | head -1
else
    print_warning "PHP-FPM ne semble pas écouter sur le port 9000"
    print_info "Vérification du processus PHP-FPM..."

    if ps aux | grep -v grep | grep php-fpm | grep php83 > /dev/null; then
        print_success "Processus PHP-FPM en cours d'exécution"
        ps aux | grep -v grep | grep php-fpm | grep php83 | head -3
    else
        print_error "Processus PHP-FPM introuvable"
        echo ""
        echo "Démarrez PHP-FPM avec:"
        echo "  sudo synoservicectl --start pkgctl-php83"
    fi
fi

################################################################################
print_header "Étape 5: Rechargement Web Station"

print_info "Rechargement de la configuration nginx..."
sudo synoservicectl --reload nginx 2>&1 || print_warning "Rechargement nginx échoué (commande peut ne pas exister)"

echo ""
print_info "Redémarrage de Web Station..."
sudo synopkg restart WebStation 2>&1

if [ $? -eq 0 ]; then
    print_success "Web Station redémarré"
else
    print_warning "Redémarrage automatique échoué, essayez manuellement"
fi

################################################################################
print_header "Résumé"

echo ""
print_success "Correctif appliqué avec succès !"
echo ""

echo -e "${BLUE}Fichiers créés/modifiés:${NC}"
echo "  /usr/syno/etc/www/app.d/backend-php83.json"
if [ -f "/usr/syno/etc/packages/WebStation/backends/backend-php83.json" ]; then
    echo "  /usr/syno/etc/packages/WebStation/backends/backend-php83.json"
fi

echo ""
echo -e "${BLUE}Vérifications à effectuer:${NC}"
echo ""
echo "1. Ouvrez Web Station dans DSM"
echo "2. Allez dans 'Paramètres PHP' (ou 'PHP Settings')"
echo "3. Vérifiez que 'PHP 8.3' apparaît dans la liste"
echo ""
echo "Si PHP 8.3 n'apparaît toujours pas:"
echo "  • Redémarrez Web Station manuellement:"
echo "    sudo synopkg stop WebStation"
echo "    sudo synopkg start WebStation"
echo ""
echo "  • Vérifiez les logs:"
echo "    tail -100 /var/log/nginx/error.log"
echo "    tail -50 /var/log/php83-install.log"
echo ""

################################################################################
print_header "Vérification Finale"

echo ""
print_info "Affichage du contenu de backend-php83.json:"
echo ""
cat /usr/syno/etc/www/app.d/backend-php83.json | head -20

echo ""
print_info "Fichiers backend présents dans app.d:"
ls -lh /usr/syno/etc/www/app.d/ | grep -E "backend|php" || echo "Aucun"

echo ""
print_header "Terminé !"
echo ""

exit 0
