#!/bin/bash
# À exécuter sur le Synology pour voir les logs détaillés

echo "=== Logs synopkg récents ==="
sudo tail -200 /var/log/synopkg.log

echo -e "\n=== Logs synopkgmgr récents ==="
sudo tail -100 /var/log/synopkgmgr.log
