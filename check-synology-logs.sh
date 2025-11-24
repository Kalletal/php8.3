#!/bin/bash
# Script à exécuter sur le Synology pour trouver les logs

echo "=== Recherche des logs du Package Center ==="
echo

echo "1. Logs dans /var/log :"
sudo ls -la /var/log/ | grep -i "pkg\|package\|synopkg"
echo

echo "2. Contenu du répertoire /var/log/packages :"
sudo ls -la /var/log/packages/ 2>/dev/null || echo "Répertoire /var/log/packages/ n'existe pas"
echo

echo "3. Logs système récents contenant 'package' :"
sudo tail -50 /var/log/messages | grep -i package
echo

echo "4. Logs synolog :"
sudo tail -50 /var/log/synolog/*.log 2>/dev/null | grep -i package || echo "Pas de logs synolog"
echo

echo "5. Fichiers de log disponibles :"
sudo find /var/log -name "*pkg*" -o -name "*package*" 2>/dev/null
echo

echo "6. Dernières lignes de /var/log/messages :"
sudo tail -30 /var/log/messages
echo

echo "7. Informations système :"
uname -a
echo

echo "8. Version DSM :"
cat /etc.defaults/VERSION
echo

echo "9. Architecture du processeur :"
uname -m
echo

echo "10. Tenter d'installer et capturer l'erreur :"
echo "Copiez le fichier SPK sur le NAS et exécutez :"
echo "sudo synopkg install /chemin/vers/php83_8.3.28-0001_geminilake.spk"
