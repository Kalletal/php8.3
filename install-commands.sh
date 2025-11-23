#!/bin/bash
# Script d'installation automatique - Les commandes seront exécutées une par une
# Vous devrez entrer votre mot de passe SSH à chaque fois

set -e

NAS_HOST="192.168.1.47"
NAS_PORT="44"
NAS_USER="gilles"
NAS_TMP="/tmp/php83-install"

echo "════════════════════════════════════════════════════════════════"
echo "Installation PHP 8.3 sur NAS - Étape par Étape"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Vous devrez entrer votre mot de passe SSH plusieurs fois."
echo "C'est normal et sécurisé."
echo ""

# Étape 1: Créer le répertoire temporaire sur le NAS
echo "▶ Étape 1: Création du répertoire temporaire sur le NAS..."
ssh -p $NAS_PORT $NAS_USER@$NAS_HOST "mkdir -p $NAS_TMP && echo 'Répertoire créé: $NAS_TMP'"

# Étape 2: Transférer le SPK
echo ""
echo "▶ Étape 2: Transfert du SPK (35 MB, ~30 secondes)..."
scp -P $NAS_PORT dist/php83_8.3.8-0001_geminilake.spk $NAS_USER@$NAS_HOST:$NAS_TMP/

# Étape 3: Transférer le script de test
echo ""
echo "▶ Étape 3: Transfert du script de test..."
scp -P $NAS_PORT test-nas-complete.sh $NAS_USER@$NAS_HOST:$NAS_TMP/
ssh -p $NAS_PORT $NAS_USER@$NAS_HOST "chmod +x $NAS_TMP/test-nas-complete.sh"

# Étape 4: Vérifier l'état actuel
echo ""
echo "▶ Étape 4: Vérification de l'état actuel du NAS..."
ssh -p $NAS_PORT $NAS_USER@$NAS_HOST "
echo '════════════════════════════════════════════════════════════════'
echo 'INFORMATIONS SYSTÈME'
echo '════════════════════════════════════════════════════════════════'
echo ''
echo 'Hostname:' \$(hostname)
echo 'Kernel:' \$(uname -r)
echo 'Architecture:' \$(uname -m)
echo ''
echo 'Version DSM:'
cat /etc.defaults/VERSION 2>/dev/null | grep -E 'productversion|buildnumber' || echo 'Non trouvé'
echo ''
echo '════════════════════════════════════════════════════════════════'
echo 'VÉRIFICATION PHP 8.3 EXISTANT'
echo '════════════════════════════════════════════════════════════════'
echo ''
if [ -d /var/packages/php83 ]; then
    echo '⚠ PHP 8.3 EST DÉJÀ INSTALLÉ'
    echo ''
    echo 'Version actuelle:'
    /var/packages/php83/target/bin/php -v 2>/dev/null | head -1 || echo '  (binaire non trouvé)'
    echo ''
    echo 'État du service:'
    sudo synoservicectl --status pkgctl-php83 2>/dev/null || echo '  (service non trouvé)'
    echo ''
    echo '⚠ VOUS DEVEZ DÉSINSTALLER L ANCIENNE VERSION AVANT !'
    echo ''
    echo 'Pour désinstaller:'
    echo '  1. Ouvrir DSM: http://192.168.1.47:5000'
    echo '  2. Centre de paquets → PHP 8.3 → Désinstaller'
    echo '  3. Attendre la fin de la désinstallation'
    echo '  4. Revenir ici et continuer'
    echo ''
    exit 1
else
    echo '✓ PHP 8.3 n est pas encore installé'
    echo '✓ Vous pouvez continuer avec l installation'
fi
echo ''
echo '════════════════════════════════════════════════════════════════'
echo 'FICHIERS PRÊTS POUR L INSTALLATION'
echo '════════════════════════════════════════════════════════════════'
echo ''
ls -lh $NAS_TMP/
echo ''
"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✓ Transferts terminés !"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Fichiers transférés dans: $NAS_TMP/"
echo ""
echo "PROCHAINES ÉTAPES:"
echo ""
echo "1. Installer le package via DSM:"
echo "   http://192.168.1.47:5000"
echo "   Centre de paquets → Installation manuelle"
echo "   Sélectionner: $NAS_TMP/php83_8.3.8-0001_geminilake.spk"
echo ""
echo "2. Une fois installé, exécuter les tests:"
echo "   ssh -p $NAS_PORT $NAS_USER@$NAS_HOST"
echo "   bash $NAS_TMP/test-nas-complete.sh"
echo ""
