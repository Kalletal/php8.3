#!/bin/bash
#
# Script de diagnostic pour identifier pourquoi PHP 8.3 ne démarre pas
#

echo "=========================================="
echo "DIAGNOSTIC PHP 8.3 - Problème de démarrage"
echo "=========================================="
echo ""

# 1. Vérifier les permissions des fichiers
echo "1. PERMISSIONS DES FICHIERS CRITIQUES"
echo "--------------------------------------"
ssh admin@$1 "sudo ls -la /var/packages/php83/scripts/ 2>/dev/null"
echo ""
ssh admin@$1 "sudo ls -la /volume1/@appstore/php83/scripts/ 2>/dev/null"
echo ""

# 2. Tester le script start-stop-status manuellement
echo "2. TEST DU SCRIPT START-STOP-STATUS"
echo "------------------------------------"
ssh admin@$1 "sudo /var/packages/php83/scripts/start-stop-status start 2>&1"
echo "Code retour: $?"
echo ""

# 3. Vérifier les dépendances
echo "3. VÉRIFICATION DES DÉPENDANCES"
echo "--------------------------------"
ssh admin@$1 "which pkgctl 2>&1"
ssh admin@$1 "ls -la /volume1/@appstore/php83/sbin/php-fpm 2>/dev/null"
ssh admin@$1 "ls -la /volume1/@appstore/php83/bin/php 2>/dev/null"
echo ""

# 4. Vérifier la configuration PHP-FPM
echo "4. CONFIGURATION PHP-FPM"
echo "------------------------"
ssh admin@$1 "sudo cat /volume1/@appstore/php83/etc/php-fpm.conf 2>/dev/null | head -30"
echo ""

# 5. Vérifier les logs système
echo "5. LOGS SYSTÈME (dernières lignes)"
echo "-----------------------------------"
ssh admin@$1 "sudo tail -20 /var/log/messages | grep -i php"
echo ""

# 6. Vérifier le status systemd
echo "6. STATUS SYSTEMD"
echo "-----------------"
ssh admin@$1 "sudo systemctl status pkgctl-php83 2>&1 | head -20"
echo ""

# 7. Tester PHP manuellement
echo "7. TEST BINAIRE PHP"
echo "-------------------"
ssh admin@$1 "/volume1/@appstore/php83/bin/php -v 2>&1"
echo ""

# 8. Tester PHP-FPM manuellement
echo "8. TEST PHP-FPM EN LIGNE DE COMMANDE"
echo "-------------------------------------"
ssh admin@$1 "sudo /volume1/@appstore/php83/sbin/php-fpm -t 2>&1"
echo ""

echo "=========================================="
echo "FIN DU DIAGNOSTIC"
echo "=========================================="
