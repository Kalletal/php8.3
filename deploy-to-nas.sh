#!/bin/bash
################################################################################
# Script de Déploiement PHP 8.3 sur Synology NAS
# NAS: ServeurNAS (192.168.1.47:44)
################################################################################

set -e

# Configuration
NAS_HOST="192.168.1.47"
NAS_PORT="44"
NAS_USER="${NAS_USER:-admin}"  # Définir via export NAS_USER=votre_user
SPK_FILE="dist/php83_8.3.8-0001_geminilake.spk"
TEST_SCRIPT="test-nas-complete.sh"

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

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

################################################################################
# Vérifications préliminaires
################################################################################

print_header "Vérifications Préliminaires"

# Vérifier que le SPK existe
if [ ! -f "$SPK_FILE" ]; then
    print_error "Fichier SPK introuvable: $SPK_FILE"
    echo ""
    echo "Veuillez d'abord construire le package avec:"
    echo "  bash scripts/build-spk.sh"
    exit 1
fi

print_success "Fichier SPK trouvé: $SPK_FILE"
ls -lh "$SPK_FILE"

# Vérifier que le script de test existe
if [ ! -f "$TEST_SCRIPT" ]; then
    print_error "Script de test introuvable: $TEST_SCRIPT"
    exit 1
fi

print_success "Script de test trouvé: $TEST_SCRIPT"

# Vérifier que l'utilisateur NAS est défini
if [ -z "$NAS_USER" ]; then
    print_error "Variable NAS_USER non définie"
    echo ""
    echo "Définissez l'utilisateur NAS avec:"
    echo "  export NAS_USER=votre_utilisateur"
    echo "  bash $0"
    exit 1
fi

print_success "Utilisateur NAS: $NAS_USER"

################################################################################
# Test de connectivité
################################################################################

print_header "Test de Connectivité"

print_info "Test de connexion SSH à ${NAS_HOST}:${NAS_PORT}..."

if ssh -p ${NAS_PORT} -o ConnectTimeout=5 ${NAS_USER}@${NAS_HOST} "echo 'Connection OK'" 2>/dev/null; then
    print_success "Connexion SSH réussie"
else
    print_error "Connexion SSH échouée"
    echo ""
    echo "Vérifiez:"
    echo "  1. L'adresse IP du NAS: $NAS_HOST"
    echo "  2. Le port SSH: $NAS_PORT"
    echo "  3. L'utilisateur: $NAS_USER"
    echo "  4. Que SSH est activé sur le NAS"
    echo ""
    echo "Test manuel:"
    echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST}"
    exit 1
fi

################################################################################
# Transfert des fichiers
################################################################################

print_header "Transfert des Fichiers"

# Créer un répertoire temporaire sur le NAS
NAS_TMP_DIR="/tmp/php83-deploy-$(date +%Y%m%d-%H%M%S)"
print_info "Création du répertoire temporaire: $NAS_TMP_DIR"

ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "mkdir -p $NAS_TMP_DIR"
print_success "Répertoire créé"

# Transférer le SPK
print_info "Transfert du SPK (35 MB, cela peut prendre quelques secondes)..."
if scp -P ${NAS_PORT} "$SPK_FILE" ${NAS_USER}@${NAS_HOST}:${NAS_TMP_DIR}/ 2>&1 | grep -v "post-quantum"; then
    print_success "SPK transféré"
else
    print_error "Échec du transfert du SPK"
    exit 1
fi

# Transférer le script de test
print_info "Transfert du script de test..."
if scp -P ${NAS_PORT} "$TEST_SCRIPT" ${NAS_USER}@${NAS_HOST}:${NAS_TMP_DIR}/ 2>&1 | grep -v "post-quantum"; then
    print_success "Script de test transféré"
else
    print_error "Échec du transfert du script de test"
    exit 1
fi

# Rendre le script exécutable
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "chmod +x ${NAS_TMP_DIR}/${TEST_SCRIPT}"

################################################################################
# Menu d'actions
################################################################################

print_header "Actions Disponibles"

echo ""
echo "Fichiers transférés dans: $NAS_TMP_DIR"
echo ""
echo "Que souhaitez-vous faire ?"
echo ""
echo "  1) Installer le package via DSM (recommandé)"
echo "  2) Exécuter le script de test complet"
echo "  3) Vérifier l'état du package actuel"
echo "  4) Afficher les commandes manuelles"
echo "  5) Quitter"
echo ""

read -p "Votre choix [1-5]: " choice

case $choice in
    1)
        print_header "Installation via DSM"
        echo ""
        echo "1. Ouvrez votre navigateur et connectez-vous à DSM:"
        echo "   http://192.168.1.47:5000"
        echo ""
        echo "2. Allez dans le Centre de paquets"
        echo ""
        echo "3. Si PHP 8.3 est déjà installé:"
        echo "   - Désinstallez-le d'abord"
        echo "   - Attendez que la désinstallation soit terminée"
        echo ""
        echo "4. Cliquez sur 'Installation manuelle' (bouton en haut à droite)"
        echo ""
        echo "5. Parcourir et sélectionner:"
        echo "   ${NAS_TMP_DIR}/$(basename $SPK_FILE)"
        echo ""
        echo "6. Suivez l'assistant d'installation:"
        echo "   - Sélectionnez les extensions PHP que vous souhaitez activer"
        echo "   - Cliquez sur Suivant et Appliquer"
        echo ""
        echo "7. Une fois installé, revenez à ce script et choisissez l'option 2"
        echo "   pour exécuter les tests"
        echo ""
        ;;

    2)
        print_header "Exécution du Script de Test"
        echo ""
        print_info "Exécution du script de test sur le NAS..."
        ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "bash ${NAS_TMP_DIR}/${TEST_SCRIPT}"
        ;;

    3)
        print_header "État du Package"
        echo ""
        print_info "Vérification de l'état actuel..."
        ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "
            if [ -d /var/packages/php83 ]; then
                echo 'Package php83 installé'
                echo ''
                echo 'Version PHP:'
                /var/packages/php83/target/bin/php -v 2>/dev/null || echo 'Binaire PHP non trouvé'
                echo ''
                echo 'État du service:'
                synoservicectl --status pkgctl-php83 2>/dev/null || echo 'Service non trouvé'
            else
                echo 'Package php83 NON installé'
            fi
        "
        ;;

    4)
        print_header "Commandes Manuelles"
        echo ""
        echo "Connexion SSH au NAS:"
        echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST}"
        echo ""
        echo "Fichiers transférés:"
        echo "  SPK: ${NAS_TMP_DIR}/$(basename $SPK_FILE)"
        echo "  Test: ${NAS_TMP_DIR}/${TEST_SCRIPT}"
        echo ""
        echo "Exécuter le script de test:"
        echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} 'bash ${NAS_TMP_DIR}/${TEST_SCRIPT}'"
        echo ""
        echo "Vérifier les logs:"
        echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} 'tail -50 /var/log/packages/php83.log'"
        echo ""
        echo "Démarrer le service:"
        echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} 'sudo synoservicectl --start pkgctl-php83'"
        echo ""
        echo "Nettoyer les fichiers temporaires:"
        echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} 'rm -rf ${NAS_TMP_DIR}'"
        echo ""
        ;;

    5)
        print_info "Au revoir!"
        exit 0
        ;;

    *)
        print_error "Choix invalide"
        exit 1
        ;;
esac

echo ""
print_header "Terminé"
echo ""
print_info "Pour nettoyer les fichiers temporaires:"
echo "  ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} 'rm -rf ${NAS_TMP_DIR}'"
echo ""
