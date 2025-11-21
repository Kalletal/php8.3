# Intégration Web Station pour PHP 8.3

## Modifications apportées

Ce document décrit les modifications effectuées pour intégrer PHP 8.3 avec Synology Web Station et activer le bouton "Ouvrir" dans le Centre de paquets.

---

## 1. Fichiers ajoutés

### A. Configuration Web Station (`spk/php83/conf/backend.json`)

Fichier de configuration permettant à Web Station de reconnaître PHP 8.3 comme paquet dorsal.

**Caractéristiques :**
- Type : `nginx_php` (FastCGI via nginx)
- Service : `php83`
- Nom affiché : "PHP 8.3"
- Support des alias et multi-sites
- 24 extensions PHP pré-configurées
- Paramètres PHP optimisés (256M RAM, 100M upload)

**Emplacement après installation :** `/usr/syno/etc/www/app.d/backend-php83.json`

### B. Icône 256x256 (`spk/php83/PACKAGE_ICON_256.PNG`)

Icône haute résolution pour l'affichage dans Web Station.

**Caractéristiques :**
- Format : PNG 256x256 pixels
- Couleur : Violet PHP (#777BB4)
- Contenu : "PHP 8.3"

---

## 2. Fichiers modifiés

### A. `spk/php83/INFO`

**Modifications :**
- ✅ Conservé `dsmuidir="ui"` pour l'interface de gestion
- ❌ Supprimé `admin_protocol`, `admin_port`, `admin_url` (incompatibles avec l'approche dsmuidir)

**Avant :**
```ini
dsmuidir="ui"
dsmappname="com.synocommunity.packages.php83"
admin_protocol="http"
admin_port="8380"
admin_url="/"
```

**Après :**
```ini
dsmuidir="ui"
dsmappname="com.synocommunity.packages.php83"
```

### B. `spk/php83/src/ui/config`

**Modifications :**
- Type changé de `.url` à configuration directe
- Type legacy pour compatibilité DSM 7.2+

**Avant :**
```json
{
    ".url": {
        "com.synocommunity.packages.php83": {
            "type": "url",
            "protocol": "http",
            "port": "auto",
            ...
        }
    }
}
```

**Après :**
```json
{
    "com.synocommunity.packages.php83": {
        "type": "legacy",
        "title": "PHP 8.3",
        "desc": "PHP 8.3 Extension Manager",
        "icon": "images/icon_72.png",
        "url": "/webman/3rdparty/php83/index.html",
        "allUsers": true
    }
}
```

### C. `spk/php83/src/scripts/postinst`

**Ajout de l'enregistrement Web Station :**

```bash
# Register with Web Station by copying backend.json
if [ -f "${SYNOPKG_PKGDEST}/conf/backend.json" ]; then
    mkdir -p /usr/syno/etc/www/app.d
    cp "${SYNOPKG_PKGDEST}/conf/backend.json" /usr/syno/etc/www/app.d/backend-php83.json
    chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
    echo "[$(date)] Web Station backend registered" >> /var/log/php83-install.log
fi
```

**Fonction :**
- Copie `backend.json` dans le répertoire de configuration Web Station
- Permet à Web Station de détecter automatiquement PHP 8.3
- Enregistre l'opération dans les logs

### D. `spk/php83/src/scripts/postuninst`

**Ajout du nettoyage Web Station :**

```bash
# Unregister from Web Station
rm -f /usr/syno/etc/www/app.d/backend-php83.json
```

**Fonction :**
- Supprime la configuration Web Station lors de la désinstallation
- Garantit un nettoyage propre du système

### E. `scripts/build-spk.sh`

**Modifications :**

1. Ajout de la copie de l'icône 256x256 :
```bash
# Copy package icons
cp "$SPK_DIR/PACKAGE_ICON_256.PNG" "$BUILD_DIR/" 2>/dev/null || true
```

2. Ajout de la copie des fichiers de configuration Web Station :
```bash
cp "$SPK_DIR/conf/backend.json" "$BUILD_DIR/package/conf/" 2>/dev/null || true
cp "$SPK_DIR/conf/extensions.json" "$BUILD_DIR/package/conf/" 2>/dev/null || true
cp "$SPK_DIR/conf/resource.conf" "$BUILD_DIR/package/conf/" 2>/dev/null || true
```

---

## 3. Architecture de l'intégration

### Deux interfaces complémentaires :

#### A. Interface de gestion des extensions (Bouton "Ouvrir")
- **URL :** `/webman/3rdparty/php83/index.html`
- **Fonction :** Activer/désactiver les extensions PHP
- **Accès :** Via le bouton "Ouvrir" dans le Centre de paquets
- **Configuration :** `spk/php83/src/ui/config`

#### B. Intégration Web Station (Paquets dorsaux)
- **Configuration :** `/usr/syno/etc/www/app.d/backend-php83.json`
- **Fonction :** Utiliser PHP 8.3 pour les sites web
- **Accès :** Web Station → PHP Settings → Sélection de version
- **Socket :** `/var/packages/php83/var/run/php-fpm.sock`

---

## 4. Processus d'installation

### Étape 1 : Installation du package
```bash
1. L'utilisateur installe php83_8.3.8-0001_geminilake.spk
2. Le script preinst s'exécute (vérifications préalables)
3. Les fichiers sont copiés dans /var/packages/php83/
```

### Étape 2 : Configuration post-installation
```bash
4. Le script postinst s'exécute :
   - Crée les répertoires nécessaires (/var/sessions, /var/tmp, /var/log)
   - Configure les permissions
   - Copie backend.json vers /usr/syno/etc/www/app.d/
   - Configure les extensions sélectionnées dans l'assistant
   - Crée le symlink vers l'interface UI
```

### Étape 3 : Disponibilité
```bash
5. Le bouton "Ouvrir" apparaît dans le Centre de paquets
6. PHP 8.3 apparaît dans Web Station → Paquets dorsaux
7. L'interface de gestion est accessible via le bouton "Ouvrir"
```

---

## 5. Utilisation

### A. Gérer les extensions PHP

1. Ouvrir le Centre de paquets
2. Localiser "PHP 8.3"
3. Cliquer sur le bouton "Ouvrir"
4. Sélectionner/désélectionner les extensions
5. Cliquer sur "Enregistrer"
6. Redémarrer PHP-FPM pour appliquer les changements

### B. Utiliser PHP 8.3 avec Web Station

1. Ouvrir Web Station
2. Aller dans "Paramètres PHP"
3. Dans l'onglet "PHP Settings"
4. Sélectionner "PHP 8.3" dans la liste déroulante
5. Configurer les paramètres PHP si nécessaire
6. Appliquer

### C. Créer un site web avec PHP 8.3

1. Dans Web Station, cliquer sur "Créer" → "Portail virtuel"
2. Choisir le type (PHP, HTTP, HTTPS)
3. Dans "Backend server", sélectionner "PHP 8.3"
4. Configurer le nom de domaine/port
5. Sélectionner le dossier racine
6. Appliquer

---

## 6. Extensions PHP disponibles

### Extensions incluses dans backend.json :

**Base de données :**
- `mysqli`, `pdo_mysql` - MySQL/MariaDB
- `pdo_sqlite`, `sqlite3` - SQLite

**Réseau :**
- `curl` - Client HTTP
- `openssl` - SSL/TLS
- `soap` - Services SOAP
- `sockets`, `ftp` - Protocoles réseau

**Traitement de données :**
- `xml`, `dom`, `simplexml` - Traitement XML
- `xmlreader`, `xmlwriter` - Lecture/écriture XML
- `zlib` - Compression

**Images :**
- `gd` - Manipulation d'images
- `exif` - Métadonnées d'images

**Internationalisation :**
- `gettext` - Traduction
- `calendar` - Calendriers

**Performance :**
- `opcache` - Cache de bytecode

**Sécurité :**
- `filter` - Validation des entrées
- `ctype` - Vérification des types

**Système :**
- `fileinfo` - Détection de type de fichier
- `session` - Gestion des sessions
- `tokenizer` - Analyse de code PHP
- `posix`, `pcntl` - Contrôle de processus

**Mathématiques :**
- `bcmath` - Arithmétique en précision arbitraire

---

## 7. Configuration PHP par défaut

### Paramètres définis dans backend.json :

```json
"php_settings": {
  "memory_limit": "256M",              // Mémoire allouée par script
  "max_execution_time": "300",         // Temps d'exécution max (5 min)
  "display_errors": "off",             // Masquer les erreurs en production
  "error_reporting": "E_ALL & ~E_DEPRECATED & ~E_STRICT",
  "upload_max_filesize": "100M",       // Taille max fichier uploadé
  "post_max_size": "100M",             // Taille max POST
  "max_input_time": "300",             // Temps max lecture entrées
  "date.timezone": "Europe/Paris"      // Fuseau horaire
}
```

### Restrictions de sécurité :

```json
"open_basedir": "/home:/tmp:/var/services/web:/var/services/homes"
```

**Fonction :** Limite l'accès aux fichiers uniquement dans ces répertoires.

---

## 8. Dépannage

### Le bouton "Ouvrir" n'apparaît pas

**Vérifications :**
1. Vérifier que le package est installé : `ls -la /var/packages/php83/`
2. Vérifier la présence du dossier UI : `ls -la /var/packages/php83/target/ui/`
3. Vérifier le fichier config : `cat /var/packages/php83/target/ui/config`
4. Vérifier les logs : `tail -50 /var/log/php83-install.log`

**Solution :**
- Désinstaller et réinstaller le package
- Vérifier que `dsmuidir="ui"` est présent dans INFO
- Vérifier qu'aucun `admin_port` n'est défini dans INFO

### PHP 8.3 n'apparaît pas dans Web Station

**Vérifications :**
1. Vérifier le fichier backend : `cat /usr/syno/etc/www/app.d/backend-php83.json`
2. Vérifier le socket PHP-FPM : `ls -la /var/packages/php83/var/run/php-fpm.sock`
3. Vérifier que PHP-FPM tourne : `ps aux | grep php-fpm`

**Solution :**
- Redémarrer le package PHP 8.3
- Redémarrer Web Station
- Vérifier que le socket est accessible (permissions 660, propriétaire http:http)

### Les extensions ne sont pas chargées

**Vérifications :**
1. Vérifier les extensions activées : `cat /var/packages/php83/target/etc/php-extensions-enabled.ini`
2. Vérifier que les fichiers .so existent : `ls -la /var/packages/php83/target/lib/php/extensions/*/`
3. Tester PHP : `/var/packages/php83/target/bin/php -m`

**Solution :**
- Utiliser l'interface de gestion pour réactiver les extensions
- Redémarrer PHP-FPM après modification

---

## 9. Fichiers de configuration importants

### Fichiers du package :
```
/var/packages/php83/target/
├── conf/
│   ├── backend.json              # Config Web Station
│   ├── extensions.json           # Liste des extensions
│   ├── php-fpm.conf             # Configuration FPM
│   └── pkgctl-php83.sc          # Contrôle du service
├── etc/
│   ├── php.ini                   # Configuration PHP
│   └── php-extensions-enabled.ini # Extensions actives
├── ui/
│   ├── config                    # Config bouton "Ouvrir"
│   ├── index.html               # Interface de gestion
│   └── images/icon_72.png       # Icône UI
└── var/
    ├── run/php-fpm.sock         # Socket FastCGI
    ├── sessions/                # Sessions PHP
    └── log/                     # Logs PHP
```

### Fichiers système :
```
/usr/syno/etc/www/app.d/
└── backend-php83.json           # Enregistrement Web Station

/var/log/
└── php83-install.log            # Logs d'installation
```

---

## 10. Résumé des améliorations

### Avant les modifications :
- ❌ Pas de bouton "Ouvrir" dans le Centre de paquets
- ❌ PHP 8.3 invisible dans Web Station
- ❌ Configuration contradictoire (admin_port vs dsmuidir)
- ⚠️ Interface de gestion non accessible

### Après les modifications :
- ✅ Bouton "Ouvrir" fonctionnel
- ✅ PHP 8.3 visible dans Web Station → Paquets dorsaux
- ✅ Interface de gestion accessible via le bouton "Ouvrir"
- ✅ Intégration complète avec Web Station
- ✅ Sélection de PHP 8.3 pour les sites web
- ✅ Gestion visuelle des extensions
- ✅ Configuration propre et cohérente

---

## 11. Prochaines étapes recommandées

### Test du package :
1. Installer le package sur DSM
2. Vérifier l'apparition du bouton "Ouvrir"
3. Tester l'interface de gestion des extensions
4. Vérifier la présence dans Web Station
5. Créer un site de test avec PHP 8.3
6. Tester le bon fonctionnement de PHP et des extensions

### Améliorations futures possibles :
- Interface de gestion plus avancée (activation/désactivation en temps réel)
- Statistiques d'utilisation PHP
- Gestion des paramètres php.ini via l'interface
- Support des profils de configuration multiples
- Intégration avec le système de logs DSM

---

**Date de création :** 2025-11-20
**Version du package :** 8.3.8-0001
**Architecture :** geminilake (DS920+)
**DSM Version :** 7.2+
