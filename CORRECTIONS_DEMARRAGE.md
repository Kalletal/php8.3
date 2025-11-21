# Corrections du problème de démarrage PHP 8.3

## Problèmes identifiés

### 1. Chemins incorrects dans start-stop-status
**Symptôme** : Le script cherchait les fichiers dans `/var/packages/php83/target/package/` alors que la structure réelle est `/var/packages/php83/target/`

**Erreur dans les logs** :
```
/var/packages/php83/target/package/sbin/php-fpm: No such file or directory
```

**Correction** : Modifié `spk/php83/src/scripts/start-stop-status` lignes 4-7
```bash
# Avant
PHP_FPM="${SYNOPKG_PKGDEST}/package/sbin/php-fpm"
PHP_FPM_CONF="${SYNOPKG_PKGDEST}/package/conf/php-fpm.conf"
WEB_SERVER="${SYNOPKG_PKGDEST}/package/scripts/web-server.sh"

# Après
PHP_FPM="${SYNOPKG_PKGDEST}/sbin/php-fpm"
PHP_FPM_CONF="${SYNOPKG_PKGDEST}/conf/php-fpm.conf"
WEB_SERVER="${SYNOPKG_PKGDEST}/scripts/web-server.sh"
```

### 2. Dépendances avec chemins absolus de compilation
**Symptôme** : Les binaires PHP contenaient des références codées en dur vers les bibliothèques de compilation

**Erreur dans les logs** :
```
error while loading shared libraries: /home/gilles/spksrc/cross/zlib/work-geminilake-7.2/install/usr/local/zlib/lib/libz.so: cannot open shared object file
```

**Cause** : Les binaires compilés avec spksrc avaient des chemins absolus au lieu de chemins relatifs ($ORIGIN)

**Correction** : Créé `scripts/fix-binaries-rpath.sh` qui :
1. Crée le lien symbolique `libz.so` manquant
2. Utilise `patchelf` pour définir RPATH à `$ORIGIN/../lib` sur tous les binaires PHP
3. Intégré automatiquement dans le processus de build

## Corrections appliquées

### Fichiers modifiés
1. **spk/php83/src/scripts/start-stop-status**
   - Correction des chemins (lignes 4-7)
   - Ajout de logs de débogage détaillés dans `/var/log/php83-startup.log`
   - Vérifications explicites de l'existence des fichiers

2. **scripts/build-spk.sh**
   - Ajout de l'appel à `fix-binaries-rpath.sh` après la copie des binaires PHP
   - Vérification et correction automatique des RPATH

3. **scripts/fix-binaries-rpath.sh** (nouveau)
   - Correction automatique des RPATH pour tous les binaires PHP
   - Création des liens symboliques manquants
   - Vérification post-correction

## Package reconstruit

**Fichier** : `dist/php83_8.3.8-0001_geminilake.spk`
**Taille** : 35 MiB (36,444,160 bytes)
**MD5** : `08cb5f6e8c20f7252f199ef5b1e22b76`
**Date** : 2025-11-21 09:58:13 UTC

**Vérification RPATH** :
```
php-fpm:  RUNPATH: [$ORIGIN/../lib]
php:      RUNPATH: [$ORIGIN/../lib]
php-cgi:  RUNPATH: [$ORIGIN/../lib]
phpdbg:   RUNPATH: [$ORIGIN/../lib]
```

## Instructions de test

### 1. Désinstaller l'ancienne version
```bash
# Sur le NAS
sudo synopkg uninstall php83
```

### 2. Transférer le nouveau package
```bash
# Depuis votre machine de compilation
scp dist/php83_8.3.8-0001_geminilake.spk admin@<IP_NAS>:/tmp/
```

### 3. Installer via le Centre de paquets DSM
- Ouvrir le Centre de paquets
- Installation manuelle
- Sélectionner `/tmp/php83_8.3.8-0001_geminilake.spk`

### 4. Vérifier le démarrage
```bash
# Sur le NAS
sudo synopkg status php83

# Vérifier les logs de démarrage
sudo cat /var/log/php83-startup.log

# Vérifier que PHP-FPM tourne
ps aux | grep php-fpm

# Tester PHP en ligne de commande
/var/packages/php83/target/bin/php -v
/var/packages/php83/target/bin/php -m
```

### 5. Vérifier Web Station (optionnel)
- Ouvrir Web Station
- Vérifier que PHP 8.3 apparaît dans les versions disponibles
- Créer un VirtualHost de test avec PHP 8.3
- Créer un fichier `info.php` avec `<?php phpinfo();`

## Logs de diagnostic

Si le problème persiste, consulter :
- `/var/log/php83-startup.log` - Logs de démarrage détaillés
- `/var/packages/php83/var/log/php-fpm.log` - Logs PHP-FPM
- `/var/log/synopkg.log` - Logs d'installation DSM

## Tests de vérification

Une fois le service démarré avec succès :

```bash
# Test 1 : PHP CLI
/var/packages/php83/target/bin/php -r "echo 'PHP works: ' . PHP_VERSION . PHP_EOL;"

# Test 2 : Extensions disponibles
/var/packages/php83/target/bin/php -m

# Test 3 : PHP-FPM status
sudo /var/packages/php83/scripts/start-stop-status status

# Test 4 : Socket PHP-FPM
ls -la /var/packages/php83/var/run/php-fpm.sock
```

## Structure du package déployé

```
/var/packages/php83/
├── target → /volume1/@appstore/php83/
├── var/
│   ├── run/
│   │   ├── php-fpm.pid
│   │   └── php-fpm.sock
│   ├── log/
│   │   ├── php-fpm.log
│   │   └── php-fpm-www-error.log
│   ├── sessions/
│   └── tmp/
├── scripts/
│   ├── start-stop-status
│   ├── postinst
│   ├── preinst
│   └── ...
└── conf/
    └── privilege

/volume1/@appstore/php83/
├── bin/
│   ├── php
│   ├── php-cgi
│   └── phpdbg
├── sbin/
│   └── php-fpm
├── lib/
│   ├── libxml2.so.2
│   ├── libz.so → libz.so.1
│   ├── libz.so.1 → libz.so.1.3.1
│   ├── libz.so.1.3.1
│   └── php/extensions/no-debug-non-zts-20230831/
│       ├── opcache.so
│       ├── mysqli.so
│       └── ... (36 extensions)
├── conf/
│   ├── php-fpm.conf
│   ├── php.ini
│   ├── backend.json
│   └── extensions.json
├── etc/
│   └── php.ini
├── scripts/
│   ├── apply_extensions.sh
│   ├── check-status.sh
│   └── web-server.sh
└── ui/
    ├── index.html
    ├── extension-api.cgi
    └── ...
```

## Prochaines étapes après validation

Une fois le démarrage confirmé fonctionnel :
1. Tester l'interface web de gestion des extensions (port 8380)
2. Tester l'intégration Web Station
3. Tester l'activation/désactivation d'extensions via l'UI
4. Valider les performances PHP-FPM
5. Tester quelques applications PHP réelles (WordPress, etc.)
