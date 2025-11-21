#!/bin/bash
# Script de diagnostic pour PHP 8.3 sur Synology
# À copier et exécuter sur le NAS

echo "========================================"
echo "Diagnostic PHP 8.3 - $(date)"
echo "========================================"
echo

echo "1. Vérification des répertoires et permissions"
echo "-----------------------------------------------"
ls -la /var/packages/php83/var/ 2>/dev/null || echo "ERREUR: /var/packages/php83/var n'existe pas"
echo
ls -la /var/packages/php83/var/run/ 2>/dev/null || echo "ERREUR: /var/packages/php83/var/run n'existe pas"
echo
ls -la /var/packages/php83/var/log/ 2>/dev/null || echo "ERREUR: /var/packages/php83/var/log n'existe pas"
echo

echo "2. Vérification des binaires PHP"
echo "---------------------------------"
ls -la /var/packages/php83/target/package/sbin/php-fpm 2>/dev/null || echo "ERREUR: php-fpm non trouvé"
ls -la /var/packages/php83/target/package/conf/php-fpm.conf 2>/dev/null || echo "ERREUR: php-fpm.conf non trouvé"
echo

echo "3. Contenu du fichier php-fpm.conf (10 premières lignes)"
echo "---------------------------------------------------------"
head -15 /var/packages/php83/target/package/conf/php-fpm.conf 2>/dev/null || echo "ERREUR: impossible de lire php-fpm.conf"
echo

echo "4. Test de démarrage manuel PHP-FPM"
echo "------------------------------------"
echo "Correction des permissions..."
sudo chmod 755 /var/packages/php83/var 2>/dev/null
sudo chmod 755 /var/packages/php83/var/run 2>/dev/null
sudo chmod 755 /var/packages/php83/var/log 2>/dev/null
sudo chown -R http:http /var/packages/php83/var 2>/dev/null

echo "Permissions après correction:"
ls -ld /var/packages/php83/var/run
echo

echo "Tentative de démarrage..."
sudo /var/packages/php83/target/package/sbin/php-fpm \
  --fpm-config /var/packages/php83/target/package/conf/php-fpm.conf \
  --pid /var/packages/php83/var/run/php-fpm.pid 2>&1

sleep 2
echo

echo "5. Vérification du processus"
echo "-----------------------------"
ps aux | grep php-fpm | grep php83 || echo "Aucun processus php83 trouvé"
echo

echo "6. Vérification des fichiers créés"
echo "-----------------------------------"
ls -la /var/packages/php83/var/run/
echo

echo "7. Logs PHP-FPM"
echo "---------------"
if [ -f /var/packages/php83/var/log/php-fpm.log ]; then
    echo "Contenu de php-fpm.log:"
    cat /var/packages/php83/var/log/php-fpm.log
else
    echo "Pas de fichier php-fpm.log"
fi
echo

echo "8. Logs système (synopkg.log - dernières 20 lignes)"
echo "----------------------------------------------------"
sudo tail -20 /var/log/synopkg.log | grep php83
echo

echo "9. Test du script start-stop-status"
echo "------------------------------------"
echo "Arrêt de PHP-FPM (si démarré)..."
sudo /var/packages/php83/scripts/start-stop-status stop
echo
echo "Démarrage via start-stop-status..."
sudo /var/packages/php83/scripts/start-stop-status start
echo
echo "Status via start-stop-status..."
sudo /var/packages/php83/scripts/start-stop-status status
echo

echo "========================================"
echo "Fin du diagnostic"
echo "========================================"
