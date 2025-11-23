#!/bin/bash
# Test différentes configurations de l'entrée php83 pour trouver ce qui plante

echo "=== Test des champs PluginPackage.json pour php83 ==="
echo ""
echo "Ce script va tester différentes configurations pour identifier"
echo "quel champ fait planter Web Station."
echo ""
echo "Pour chaque test:"
echo "1. On modifie PluginPackage.json"
echo "2. On redémarre Web Station"
echo "3. VOUS testez l'interface et notez si ça marche ou plante"
echo ""
read -p "Appuyez sur Entrée pour commencer..."

# Backup initial
PLUGIN_FILE="/usr/syno/etc/packages/WebStation/PluginPackage.json"
BACKUP_CLEAN="${PLUGIN_FILE}.backup-clean"
sudo cp "$PLUGIN_FILE" "$BACKUP_CLEAN"
echo "✓ Backup clean créé: $BACKUP_CLEAN"
echo ""

# TEST 1: Copier exactement PHP8.2 mais changer l'ID
echo "=== TEST 1: Copie exacte de PHP8.2 avec ID 'php83' ==="
sudo python3 << 'TEST1'
import json
with open("/usr/syno/etc/packages/WebStation/PluginPackage.json", 'r') as f:
    data = json.load(f)

# Trouver PHP8.2
php82 = None
for pkg in data['packages']:
    if pkg.get('id') == 'PHP8.2':
        php82 = pkg.copy()
        break

if php82:
    # Créer une copie avec juste l'ID changé
    php83_test = {
        "id": "php83",
        "resource": php82['resource'].copy(),
        "type": php82['type'],
        "version": php82['version']
    }

    # Ajouter à la liste
    data['packages'].append(php83_test)

    with open("/usr/syno/etc/packages/WebStation/PluginPackage.json", 'w') as f:
        json.dump(data, f, indent=8)

    print("✓ Ajouté php83 (copie de PHP8.2 avec ID changé)")
    print(json.dumps(php83_test, indent=2))
TEST1

sudo synopkg restart WebStation
sleep 3
echo ""
echo "TEST 1: Vérifiez Web Station maintenant"
echo "  - Si ça PLANTE: le problème est l'ID en minuscules 'php83'"
echo "  - Si ça MARCHE: le problème est dans les chemins/valeurs resource"
read -p "Résultat (m=marche, p=plante): " result1

# Restaurer
sudo cp "$BACKUP_CLEAN" "$PLUGIN_FILE"
sudo synopkg restart WebStation
sleep 2

if [ "$result1" == "p" ]; then
    echo ""
    echo "=== TEST 2: ID en MAJUSCULES 'PHP8.3' ==="
    sudo python3 << 'TEST2'
import json
with open("/usr/syno/etc/packages/WebStation/PluginPackage.json", 'r') as f:
    data = json.load(f)

php82 = None
for pkg in data['packages']:
    if pkg.get('id') == 'PHP8.2':
        php82 = pkg.copy()
        break

if php82:
    php83_test = {
        "id": "PHP8.3",  # MAJUSCULES
        "resource": php82['resource'].copy(),
        "type": php82['type'],
        "version": php82['version']
    }

    data['packages'].append(php83_test)

    with open("/usr/syno/etc/packages/WebStation/PluginPackage.json", 'w') as f:
        json.dump(data, f, indent=8)

    print("✓ Ajouté PHP8.3 (majuscules)")
TEST2

    sudo synopkg restart WebStation
    sleep 3
    echo ""
    echo "TEST 2: Vérifiez Web Station"
    read -p "Résultat (m=marche, p=plante, s=supprimé): " result2

    # Restaurer
    sudo cp "$BACKUP_CLEAN" "$PLUGIN_FILE"
    sudo synopkg restart WebStation
fi

echo ""
echo "=== Résumé des tests ==="
echo "TEST 1 (id='php83' avec resource de PHP8.2): $result1"
[ -n "$result2" ] && echo "TEST 2 (id='PHP8.3' avec resource de PHP8.2): $result2"

echo ""
echo "Backup clean restauré. Web Station doit être fonctionnel."
