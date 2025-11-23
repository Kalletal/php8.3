#!/usr/bin/env python3
"""
Script pour enregistrer PHP 8.3 dans PluginPackage.json de Web Station
"""
import json
import sys
import os
from datetime import datetime

PLUGIN_FILE = "/usr/syno/etc/packages/WebStation/PluginPackage.json"

def register_php83():
    """Ajoute PHP 8.3 dans PluginPackage.json"""

    # Vérifier que le fichier existe
    if not os.path.exists(PLUGIN_FILE):
        print(f"ERREUR: {PLUGIN_FILE} non trouvé")
        return False

    # Backup
    backup_file = f"{PLUGIN_FILE}.backup.{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    os.system(f"cp {PLUGIN_FILE} {backup_file}")
    print(f"Backup créé: {backup_file}")

    # Lire le fichier actuel
    try:
        with open(PLUGIN_FILE, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Erreur lecture JSON: {e}")
        return False

    # Vérifier si php83 existe déjà
    for pkg in data.get("packages", []):
        if pkg.get("id") == "php83":
            print("php83 déjà présent dans PluginPackage.json")
            return True

    # Créer l'entrée php83
    php83_entry = {
        "id": "php83",
        "resource": {
            "cgi_path": "/var/packages/php83/target/package/bin/php-cgi",
            "default_ini": "/var/packages/php83/target/package/etc/php.ini",
            "default_settings": "/var/packages/php83/target/package/conf/default_settings.json",
            "extension_list_path": "/var/packages/php83/target/package/conf/extension_list.json",
            "fpm_path": "/var/packages/php83/target/package/sbin/php-fpm",
            "fpm_syslog_ident": "php83-fpm",
            "id": 83,
            "prefix": "php83",
            "service_template_unit": "pkg-WebStation-php83@",
            "version": 1
        },
        "type": 1,
        "version": "8.3.8-0017"
    }

    # Ajouter php83 à la liste
    data["packages"].append(php83_entry)

    # Sauvegarder
    try:
        with open(PLUGIN_FILE, 'w') as f:
            json.dump(data, f, indent=8)
        print("✓ php83 ajouté avec succès à PluginPackage.json")
        return True
    except Exception as e:
        print(f"Erreur écriture JSON: {e}")
        # Restaurer le backup
        os.system(f"cp {backup_file} {PLUGIN_FILE}")
        print("Backup restauré")
        return False

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Ce script doit être exécuté en tant que root (sudo)")
        sys.exit(1)

    if register_php83():
        print("\nRedémarrage de Web Station...")
        os.system("/usr/syno/bin/synopkg restart WebStation")
        print("\n✓ Terminé! Vérifiez Web Station → Paramètres du langage de script → PHP")
        sys.exit(0)
    else:
        print("\n✗ Échec de l'enregistrement")
        sys.exit(1)
