#!/bin/bash
#
# Script de diagnostic à exécuter DIRECTEMENT sur le NAS
# Usage: sudo bash diagnose-local.sh
#

echo "=========================================="
echo "DIAGNOSTIC PHP 8.3 - Problème de démarrage"
echo "=========================================="
echo ""

# 1. Vérifier les permissions des fichiers
echo "1. PERMISSIONS DES FICHIERS CRITIQUES"
echo "--------------------------------------"
ls -la /var/packages/php83/scripts/ 2>/dev/null || echo "Pas de /var/packages/php83/scripts/"
echo ""
ls -la /volume1/@appstore/php83/scripts/ 2>/dev/null || echo "Pas de /volume1/@appstore/php83/scripts/"
echo ""

# 2. Vérifier le lien symbolique target
echo "2. LIEN SYMBOLIQUE TARGET"
echo "-------------------------"
ls -la /var/packages/php83/target 2>/dev/null || echo "Pas de lien symbolique target"
echo ""

# 3. Vérifier les dépendances
echo "3. VÉRIFICATION DES DÉPENDANCES"
echo "--------------------------------"
ls -la /volume1/@appstore/php83/sbin/php-fpm 2>/dev/null || echo "PHP-FPM manquant!"
ls -la /volume1/@appstore/php83/bin/php 2>/dev/null || echo "PHP manquant!"
ls -la /volume1/@appstore/php83/conf/php-fpm.conf 2>/dev/null || echo "Config PHP-FPM manquante!"
echo ""

# 4. Test du binaire PHP-FPM
echo "4. TEST BINAIRE PHP-FPM"
echo "-----------------------"
if [ -f /volume1/@appstore/php83/sbin/php-fpm ]; then
    /volume1/@appstore/php83/sbin/php-fpm -v 2>&1
    echo ""
    echo "Test de la configuration:"
    /volume1/@appstore/php83/sbin/php-fpm --fpm-config /volume1/@appstore/php83/conf/php-fpm.conf --test 2>&1
else
    echo "PHP-FPM binaire introuvable!"
fi
echo ""

# 5. Vérifier les répertoires requis
echo "5. RÉPERTOIRES REQUIS"
echo "---------------------"
ls -la /var/packages/php83/var/run 2>/dev/null || echo "Pas de /var/packages/php83/var/run"
ls -la /var/packages/php83/var/log 2>/dev/null || echo "Pas de /var/packages/php83/var/log"
ls -la /var/packages/php83/var/sessions 2>/dev/null || echo "Pas de /var/packages/php83/var/sessions"
echo ""

# 6. Vérifier les logs
echo "6. LOGS DE DÉMARRAGE"
echo "--------------------"
if [ -f /var/log/php83-startup.log ]; then
    echo "=== Contenu de /var/log/php83-startup.log ==="
    cat /var/log/php83-startup.log
else
    echo "Pas de /var/log/php83-startup.log (normal si pas encore testé)"
fi
echo ""

if [ -f /var/packages/php83/var/log/php-fpm.log ]; then
    echo "=== Contenu de php-fpm.log ==="
    tail -50 /var/packages/php83/var/log/php-fpm.log
else
    echo "Pas de php-fpm.log"
fi
echo ""

# 7. Tester le script start-stop-status manuellement
echo "7. TEST MANUEL DU SCRIPT START-STOP-STATUS"
echo "-------------------------------------------"
if [ -f /var/packages/php83/scripts/start-stop-status ]; then
    echo "Script trouvé, tentative de démarrage..."
    /var/packages/php83/scripts/start-stop-status start
    EXIT_CODE=$?
    echo "Code de retour: $EXIT_CODE"
else
    echo "Script start-stop-status introuvable!"
fi
echo ""

# 8. Vérifier le status
echo "8. STATUS DU SERVICE"
echo "--------------------"
synopkg status php83
echo ""

# 9. Afficher les dernières lignes de synopkg.log
echo "9. DERNIÈRES LIGNES DE SYNOPKG.LOG"
echo "-----------------------------------"
tail -30 /var/log/synopkg.log | grep php83
echo ""

echo "=========================================="
echo "FIN DU DIAGNOSTIC"
echo "=========================================="
