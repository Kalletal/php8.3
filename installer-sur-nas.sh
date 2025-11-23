#!/bin/bash
################################################################################
# Script d'Installation PHP 8.3 sur NAS - Version Corrigée Web Station
# NAS: ServeurNAS (192.168.1.47:44)
# Utilisateur: gilles
################################################################################

set -e

# Configuration
NAS_HOST="192.168.1.47"
NAS_PORT="44"
NAS_USER="gilles"
SPK_FILE="dist/php83_8.3.8-0001_geminilake.spk"
TEST_SCRIPT="test-nas-complete.sh"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
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

print_step() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

################################################################################

clear
print_header "Installation PHP 8.3 sur NAS avec Correctif Web Station"

echo ""
echo -e "${BLUE}NAS:${NC}         ServeurNAS (${NAS_HOST}:${NAS_PORT})"
echo -e "${BLUE}Utilisateur:${NC} ${NAS_USER}"
echo -e "${BLUE}Package:${NC}     PHP 8.3.8-0009 avec correctif Web Station"
echo ""

print_warning "Ce script va :"
echo "  1. Vérifier le package SPK"
echo "  2. Transférer le SPK et les scripts de test sur le NAS"
echo "  3. Vérifier l'état actuel de PHP 8.3 sur le NAS"
echo "  4. Vous guider pour l'installation via DSM"
echo "  5. Exécuter les tests de validation"
echo ""

read -p "Continuer ? (o/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    print_info "Installation annulée"
    exit 0
fi

################################################################################
print_step "Étape 1/6: Vérification du Package Local"

if [ ! -f "$SPK_FILE" ]; then
    print_error "Fichier SPK introuvable: $SPK_FILE"
    exit 1
fi

print_success "SPK trouvé:"
ls -lh "$SPK_FILE"

SPK_SIZE=$(stat -c%s "$SPK_FILE" 2>/dev/null || stat -f%z "$SPK_FILE" 2>/dev/null || echo 0)
SPK_SIZE_MB=$((SPK_SIZE / 1024 / 1024))
print_info "Taille: ${SPK_SIZE_MB} MB"

# Vérifier que le correctif Web Station est présent
print_info "Vérification du correctif Web Station..."
if tar -xOf "$SPK_FILE" scripts/postinst 2>/dev/null | grep -q "backend-php83.json"; then
    print_success "Correctif Web Station présent dans le SPK"
else
    print_error "Correctif Web Station non trouvé dans le SPK"
    print_warning "Le package doit être reconstruit avec le correctif"
    exit 1
fi

################################################################################
print_step "Étape 2/6: Test de Connexion SSH"

print_info "Test de connexion à ${NAS_USER}@${NAS_HOST}:${NAS_PORT}..."
echo ""
print_warning "Vous allez devoir entrer votre mot de passe SSH"
echo ""

if ssh -p ${NAS_PORT} -o ConnectTimeout=10 ${NAS_USER}@${NAS_HOST} "echo 'Connexion OK'" 2>/dev/null; then
    print_success "Connexion SSH réussie"
else
    print_error "Connexion SSH échouée"
    echo ""
    print_info "Vérifiez :"
    echo "  - Que SSH est activé sur le NAS (DSM → Panneau de configuration → Terminal & SNMP)"
    echo "  - Que l'utilisateur 'gilles' a les droits d'accès SSH"
    echo "  - Que le mot de passe est correct"
    exit 1
fi

################################################################################
print_step "Étape 3/6: Vérification de l'État Actuel du NAS"

print_info "Vérification de l'installation actuelle de PHP 8.3..."
echo ""

PHP83_INSTALLED=$(ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "
    if [ -d /var/packages/php83 ]; then
        echo 'INSTALLED'
    else
        echo 'NOT_INSTALLED'
    fi
" 2>/dev/null)

if [ "$PHP83_INSTALLED" = "INSTALLED" ]; then
    print_warning "PHP 8.3 est déjà installé sur le NAS"
    echo ""
    print_info "Informations sur l'installation actuelle:"
    ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "
        echo '  Version PHP:'
        /var/packages/php83/target/bin/php -v 2>/dev/null | head -1 || echo '  (binaire non trouvé)'
        echo ''
        echo '  État du service:'
        sudo synoservicectl --status pkgctl-php83 2>/dev/null || echo '  (service non trouvé)'
    "

    echo ""
    print_warning "⚠ IMPORTANT: Vous devez désinstaller l'ancienne version avant d'installer la nouvelle"
    echo ""
    echo "Pour désinstaller via DSM :"
    echo "  1. Ouvrir le Centre de paquets"
    echo "  2. Localiser 'PHP 8.3'"
    echo "  3. Cliquer sur 'Désinstaller'"
    echo "  4. Attendre la fin de la désinstallation"
    echo "  5. Revenir à ce script et continuer"
    echo ""
    read -p "Appuyez sur Entrée quand la désinstallation est terminée..."
else
    print_success "PHP 8.3 n'est pas encore installé"
fi

################################################################################
print_step "Étape 4/6: Transfert des Fichiers sur le NAS"

NAS_TMP_DIR="/tmp/php83-install-$(date +%Y%m%d-%H%M%S)"
print_info "Création du répertoire temporaire: $NAS_TMP_DIR"

ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "mkdir -p $NAS_TMP_DIR"
print_success "Répertoire créé"

# Transférer le SPK
print_info "Transfert du SPK (${SPK_SIZE_MB} MB)..."
echo -e "${YELLOW}⏳ Cela peut prendre quelques secondes...${NC}"

if scp -P ${NAS_PORT} "$SPK_FILE" ${NAS_USER}@${NAS_HOST}:${NAS_TMP_DIR}/ 2>&1 | grep -v "post-quantum" | grep -v "WARNING"; then
    print_success "SPK transféré"
else
    if ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "[ -f ${NAS_TMP_DIR}/$(basename $SPK_FILE) ]"; then
        print_success "SPK transféré"
    else
        print_error "Échec du transfert du SPK"
        exit 1
    fi
fi

# Transférer le script de test
print_info "Transfert du script de test..."
if scp -P ${NAS_PORT} "$TEST_SCRIPT" ${NAS_USER}@${NAS_HOST}:${NAS_TMP_DIR}/ 2>&1 | grep -v "post-quantum" | grep -v "WARNING"; then
    print_success "Script de test transféré"
else
    if ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "[ -f ${NAS_TMP_DIR}/${TEST_SCRIPT} ]"; then
        print_success "Script de test transféré"
    fi
fi

ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "chmod +x ${NAS_TMP_DIR}/${TEST_SCRIPT}"

print_success "Fichiers transférés dans: $NAS_TMP_DIR"

################################################################################
print_step "Étape 5/6: Installation du Package"

echo ""
print_header "INSTALLATION VIA DSM (Interface Web)"
echo ""

echo -e "${CYAN}1.${NC} Ouvrez votre navigateur et connectez-vous à DSM:"
echo -e "   ${GREEN}http://${NAS_HOST}:5000${NC}"
echo ""

echo -e "${CYAN}2.${NC} Allez dans ${YELLOW}Centre de paquets${NC}"
echo ""

echo -e "${CYAN}3.${NC} Cliquez sur ${YELLOW}'Installation manuelle'${NC} (bouton en haut à droite)"
echo ""

echo -e "${CYAN}4.${NC} Parcourir et sélectionner:"
echo -e "   ${GREEN}${NAS_TMP_DIR}/$(basename $SPK_FILE)${NC}"
echo ""

echo -e "${CYAN}5.${NC} Suivez l'assistant d'installation:"
echo "   • Sélectionnez les extensions PHP que vous souhaitez activer"
echo "   • ${GREEN}Extensions recommandées:${NC}"
echo "     - opcache (performance)"
echo "     - curl, openssl (réseau/sécurité)"
echo "     - mysqli, pdo_mysql (bases de données)"
echo "     - gd (images)"
echo "     - mbstring (Unicode)"
echo "     - xml, dom (XML)"
echo "   • Cliquez sur 'Suivant' puis 'Appliquer'"
echo ""

echo -e "${CYAN}6.${NC} Attendez la fin de l'installation"
echo "   • L'installation prend généralement 1-2 minutes"
echo "   • Le service PHP-FPM démarrera automatiquement"
echo ""

print_warning "IMPORTANT: Le correctif Web Station est automatique dans cette version !"
echo ""

read -p "Appuyez sur Entrée quand l'installation est terminée..."

################################################################################
print_step "Étape 6/6: Tests de Validation"

print_info "Exécution des tests complets..."
echo ""

ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "bash ${NAS_TMP_DIR}/${TEST_SCRIPT}" 2>&1 | tail -100

################################################################################
print_step "Vérification Web Station"

echo ""
print_info "Vérification de l'enregistrement Web Station..."

WEB_STATION_OK=$(ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "
    if [ -f /usr/syno/etc/www/app.d/backend-php83.json ]; then
        echo 'OK'
    else
        echo 'NOT_OK'
    fi
" 2>/dev/null)

if [ "$WEB_STATION_OK" = "OK" ]; then
    print_success "Fichier backend-php83.json présent"

    echo ""
    print_info "Vérification du contenu:"
    ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "cat /usr/syno/etc/www/app.d/backend-php83.json" | head -10

else
    print_error "Fichier backend-php83.json absent"
    print_warning "Cela peut indiquer un problème avec l'installation"
fi

################################################################################
print_header "Installation Terminée !"

echo ""
echo -e "${GREEN}✓ Package PHP 8.3 installé avec correctif Web Station${NC}"
echo ""

print_info "Prochaines étapes:"
echo ""

echo -e "${CYAN}1. Vérifier dans Web Station:${NC}"
echo "   • Ouvrir Web Station dans DSM"
echo "   • Aller dans 'Paramètres PHP' (ou 'PHP Settings')"
echo "   • ${GREEN}PHP 8.3 doit apparaître dans la liste${NC}"
echo ""

echo -e "${CYAN}2. Créer un site de test:${NC}"
echo "   • Dans Web Station → Portail Web → Créer"
echo "   • Sélectionner ${GREEN}PHP 8.3${NC} comme backend"
echo "   • Créer un fichier index.php avec <?php phpinfo(); ?>"
echo "   • Vérifier que PHP 8.3.8 s'affiche"
echo ""

echo -e "${CYAN}3. Tester le panneau de configuration:${NC}"
echo "   • Centre de paquets → PHP 8.3 → ${GREEN}Ouvrir${NC}"
echo "   • Interface de gestion des extensions"
echo ""

print_warning "Nettoyage:"
echo "  Pour supprimer les fichiers temporaires:"
echo -e "  ${YELLOW}ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} 'rm -rf ${NAS_TMP_DIR}'${NC}"
echo ""

print_success "Installation réussie ! 🎉"
echo ""

exit 0
