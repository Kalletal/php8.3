# Corrections finales pour le bouton "Ouvrir" et Web Station

## Date : 2025-11-20

---

## Problèmes identifiés

### 1. Fichier de configuration UI mal nommé
- ❌ **Ancien** : `spk/php83/src/ui/config`
- ✅ **Nouveau** : `spk/php83/src/ui/app.config`

**Raison** : DSM cherche spécifiquement un fichier nommé `app.config` pour configurer l'application.

### 2. Structure JSON incorrecte dans le fichier config

**Ancien format (incorrect)** :
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

**Nouveau format (correct)** :
```json
{
    "SYNO.SDS.PHP83.Instance": {
        "type": "url",
        "title": "PHP 8.3 Extensions",
        "allUsers": true,
        "allowMultiInstance": false,
        "url": "/webman/3rdparty/php83/index.html",
        "icon": "images/icon_72.png"
    }
}
```

**Changements clés** :
- Clé changée de `com.synocommunity.packages.php83` → `SYNO.SDS.PHP83.Instance`
- Ajout de `allowMultiInstance: false`
- Suppression de `desc` (non utilisé dans ce contexte)

### 3. Valeur incorrecte de dsmuidir dans INFO

**Ancien** :
```ini
dsmuidir="ui"
```

**Nouveau** :
```ini
dsmuidir="package/ui"
```

**Raison** : Dans notre structure de package.tgz, les fichiers UI sont dans `package/ui/`, pas directement dans `ui/`. Le chemin doit correspondre exactement à la structure dans package.tgz.

### 4. Valeur incorrecte de dsmappname dans INFO

**Ancien** :
```ini
dsmappname="com.synocommunity.packages.php83"
```

**Nouveau** :
```ini
dsmappname="SYNO.SDS.PHP83"
```

**Raison** : Le `dsmappname` doit correspondre au préfixe de la clé dans `app.config` (sans le `.Instance`).

---

## Structure du package corrigée

### Fichier INFO final (`spk/php83/INFO`)

```ini
package="php83"
version="8.3.8-0001"
description="PHP 8.3.8 with FPM, CLI, and comprehensive extension selection wizard. Supports MySQL/MariaDB, SQLite, GD (PNG/JPEG/WebP/FreeType), cURL, OpenSSL, and many more extensions organized by category."
arch="geminilake"
os_min_ver="7.2-64570"
maintainer="Gilles"
displayname="PHP 8.3"
startable="yes"
dsmuidir="package/ui"
dsmappname="SYNO.SDS.PHP83"
changelog="Initial release of PHP 8.3.8 for Synology DSM with categorized extension management"
```

### Fichier app.config final (`spk/php83/src/ui/app.config`)

```json
{
    "SYNO.SDS.PHP83.Instance": {
        "type": "url",
        "title": "PHP 8.3 Extensions",
        "allUsers": true,
        "allowMultiInstance": false,
        "url": "/webman/3rdparty/php83/index.html",
        "icon": "images/icon_72.png"
    }
}
```

### Structure de package.tgz

```
package.tgz
├── package/
│   ├── bin/
│   │   ├── php
│   │   ├── php-cgi
│   │   └── phpdbg
│   ├── sbin/
│   │   └── php-fpm
│   ├── lib/
│   │   └── php/extensions/no-debug-non-zts-20230831/
│   │       └── *.so
│   ├── etc/
│   │   ├── php.ini
│   │   └── php-fpm.conf
│   ├── conf/
│   │   ├── backend.json         # Configuration Web Station
│   │   ├── pkgctl-php83.sc
│   │   └── extensions.json
│   ├── scripts/
│   │   ├── apply_extensions.sh
│   │   ├── check-status.sh
│   │   └── extension_api.cgi
│   └── ui/                       # ← Dossier UI (dsmuidir pointe ici)
│       ├── app.config           # ← Fichier de configuration DSM
│       ├── index.html           # ← Interface de gestion
│       ├── extension-api.cgi    # ← API backend
│       └── images/
│           └── icon_72.png      # ← Icône de l'application
```

---

## Flux de fonctionnement après installation

### 1. Installation du package

```bash
# DSM copie les fichiers de package.tgz vers :
/var/packages/php83/target/

# Résultat :
/var/packages/php83/target/package/ui/
                           ├── app.config
                           ├── index.html
                           ├── extension-api.cgi
                           └── images/icon_72.png
```

### 2. Création du lien symbolique par DSM

Le script `postinst` crée un lien :

```bash
ln -sf /var/packages/php83/target/package/ui \
       /var/packages/php83/target/ui
```

DSM crée ensuite automatiquement :

```bash
/usr/syno/synoman/webman/3rdparty/php83/ → /var/packages/php83/target/package/ui/
```

### 3. Enregistrement de l'application

DSM lit :
- `INFO` : trouve `dsmuidir="package/ui"` et `dsmappname="SYNO.SDS.PHP83"`
- `package/ui/app.config` : configure l'application avec le titre, l'URL, l'icône

### 4. Affichage du bouton "Ouvrir"

Dans le Centre de paquets :
1. Le package "PHP 8.3" est listé
2. Un bouton **"Ouvrir"** apparaît à côté de "Arrêter"
3. Cliquer sur "Ouvrir" charge `/webman/3rdparty/php83/index.html`

### 5. Intégration Web Station

Le script `postinst` copie :

```bash
cp /var/packages/php83/target/conf/backend.json \
   /usr/syno/etc/www/app.d/backend-php83.json
```

Web Station détecte le nouveau fichier et ajoute "PHP 8.3" dans :
- **Paramètres généraux** → **Paramètres PHP**
- **Paquets dorsaux** (Backend Packages)

---

## Correspondance des noms

Pour éviter toute confusion, voici comment les différents identifiants sont liés :

| Emplacement | Valeur | Usage |
|-------------|--------|-------|
| `INFO` : `package` | `php83` | Nom interne du package |
| `INFO` : `displayname` | `PHP 8.3` | Nom affiché dans le Centre de paquets |
| `INFO` : `dsmappname` | `SYNO.SDS.PHP83` | Identifiant d'application DSM |
| `INFO` : `dsmuidir` | `package/ui` | Chemin vers le dossier UI dans package.tgz |
| `app.config` : clé | `SYNO.SDS.PHP83.Instance` | Identifiant complet de l'instance |
| `app.config` : `title` | `PHP 8.3 Extensions` | Titre de la fenêtre/onglet |
| `backend.json` : `service` | `php83` | Nom du service pour Web Station |
| `backend.json` : `display_name` | `PHP 8.3` | Nom affiché dans Web Station |

**Règle importante** :
```
dsmappname + ".Instance" = clé dans app.config
"SYNO.SDS.PHP83" + ".Instance" = "SYNO.SDS.PHP83.Instance" ✓
```

---

## Vérifications après installation

### 1. Vérifier que le bouton "Ouvrir" apparaît

```bash
# Sur le NAS, vérifier que le dossier UI existe
ls -la /var/packages/php83/target/package/ui/

# Doit afficher :
# app.config
# index.html
# extension-api.cgi
# images/
```

### 2. Vérifier le lien symbolique

```bash
# Vérifier le lien vers webman
ls -la /usr/syno/synoman/webman/3rdparty/ | grep php83

# Doit afficher un lien vers :
# php83 -> /var/packages/php83/target/package/ui/
```

### 3. Vérifier l'enregistrement Web Station

```bash
# Vérifier la présence de backend.json
cat /usr/syno/etc/www/app.d/backend-php83.json

# Doit afficher la configuration Web Station avec :
# "service": "php83"
# "display_name": "PHP 8.3"
# "type": "nginx_php"
```

### 4. Tester l'accès à l'interface

Ouvrir dans un navigateur :
```
http://[IP-NAS]/webman/3rdparty/php83/index.html
```

Doit afficher l'interface de gestion des extensions PHP.

---

## Différences entre les deux fonctionnalités

### Bouton "Ouvrir" (Centre de paquets)

**Fichiers utilisés** :
- `INFO` : `dsmuidir`, `dsmappname`
- `app.config` : configuration de l'application
- `index.html` : interface utilisateur

**Fonction** :
- Lance l'interface de gestion des extensions
- Accessible via le Centre de paquets
- URL : `/webman/3rdparty/php83/index.html`

### Intégration Web Station

**Fichiers utilisés** :
- `backend.json` : configuration du backend PHP
- `php-fpm.conf` : configuration FastCGI
- Socket : `/var/packages/php83/var/run/php-fpm.sock`

**Fonction** :
- Permet d'utiliser PHP 8.3 pour les sites web
- Accessible via Web Station → Paramètres PHP
- Sélectionnable comme version PHP pour les portails virtuels

---

## Fichiers créés/modifiés dans cette correction

### Créés :
1. ✅ `spk/php83/src/ui/app.config` - Configuration DSM
2. ✅ `spk/php83/conf/backend.json` - Configuration Web Station
3. ✅ `spk/php83/PACKAGE_ICON_256.PNG` - Icône haute résolution

### Supprimés :
1. ❌ `spk/php83/src/ui/config` - Ancien fichier mal nommé

### Modifiés :
1. 🔧 `spk/php83/INFO` :
   - `dsmuidir="ui"` → `dsmuidir="package/ui"`
   - `dsmappname="com.synocommunity.packages.php83"` → `dsmappname="SYNO.SDS.PHP83"`

2. 🔧 `spk/php83/src/scripts/postinst` :
   - Ajout de l'enregistrement Web Station

3. 🔧 `spk/php83/src/scripts/postuninst` :
   - Ajout du nettoyage Web Station

4. 🔧 `scripts/build-spk.sh` :
   - Copie de backend.json et PACKAGE_ICON_256.PNG

---

## Package final

**Nom** : `php83_8.3.8-0001_geminilake.spk`
**Taille** : 35 MiB (36 433 920 bytes)
**MD5** : `af553b23209bc045cfb4f59cd9a0d999`
**Emplacement** : `/home/gilles/ProjetSPK/php8.3/dist/php83_8.3.8-0001_geminilake.spk`

**Build date** : 2025-11-20 05:46:38 UTC

---

## Résultats attendus

Après l'installation de ce nouveau package :

### ✅ Bouton "Ouvrir" dans le Centre de paquets
- Visible à côté des boutons "Démarrer/Arrêter"
- Ouvre l'interface de gestion des extensions
- Permet d'activer/désactiver les extensions PHP

### ✅ Visibilité dans Web Station
- Apparaît dans "Paquets dorsaux" (Backend Packages)
- Sélectionnable dans "Paramètres PHP"
- Utilisable pour les portails virtuels
- Extensions pré-configurées

### ✅ Deux modes d'utilisation complémentaires
1. **Gestion des extensions** : via le bouton "Ouvrir"
2. **Utilisation pour sites web** : via Web Station

---

## Instructions de test

1. **Désinstaller l'ancienne version**
   ```
   Centre de paquets → PHP 8.3 → Désinstaller
   ```

2. **Installer la nouvelle version**
   ```
   Centre de paquets → Action → Installation manuelle
   Sélectionner : php83_8.3.8-0001_geminilake.spk
   ```

3. **Vérifier le bouton "Ouvrir"**
   ```
   Centre de paquets → Installés → PHP 8.3
   Le bouton "Ouvrir" doit être visible
   ```

4. **Tester l'interface**
   ```
   Cliquer sur "Ouvrir"
   L'interface de gestion des extensions doit s'ouvrir
   ```

5. **Vérifier Web Station**
   ```
   Web Station → Paramètres généraux → Paramètres PHP
   "PHP 8.3" doit apparaître dans la liste
   ```

---

## Conclusion

Les corrections apportées résolvent les deux problèmes principaux :

1. **Fichier app.config mal nommé et mal formaté** → Corrigé
2. **Valeur incorrecte de dsmuidir** → Corrigée pour correspondre à la structure réelle
3. **dsmappname non conforme** → Corrigé pour suivre la convention SYNO.SDS.*

Le package devrait maintenant fonctionner correctement avec :
- ✅ Bouton "Ouvrir" fonctionnel
- ✅ Interface de gestion accessible
- ✅ Intégration Web Station complète
- ✅ Sélection comme backend PHP pour les sites

---

**Auteur** : Gilles
**Date** : 2025-11-20
**Version** : 8.3.8-0001
**Architecture** : Geminilake
