# Correction finale des chemins - Package PHP 8.3

## Problème identifié

Le package ne démarrait pas car **j'avais supprimé à tort le sous-répertoire `/package/` des chemins**.

### Structure réelle du package Synology

Quand DSM extrait `package.tgz` dans `/volume1/@appstore/php83/`, le contenu est :

```
/volume1/@appstore/php83/
└── package/              ← Ce répertoire EST dans package.tgz !
    ├── bin/
    │   ├── php
    │   ├── php-cgi
    │   └── phpdbg
    ├── sbin/
    │   └── php-fpm
    ├── lib/
    │   ├── libz.so
    │   └── php/extensions/...
    ├── conf/
    │   ├── php-fpm.conf
    │   ├── backend.json
    │   └── extensions.json
    ├── etc/
    │   └── php.ini
    ├── scripts/
    │   ├── apply_extensions.sh
    │   └── web-server.sh
    └── ui/
        └── ...
```

### Le lien symbolique `target`

```bash
/var/packages/php83/target → /volume1/@appstore/php83
```

Donc pour accéder à PHP-FPM :
```bash
/var/packages/php83/target/package/sbin/php-fpm  ✓ CORRECT
/var/packages/php83/target/sbin/php-fpm          ✗ FAUX (ce que j'avais mis)
```

## Fichiers corrigés

Tous les scripts ont été mis à jour pour utiliser les chemins corrects avec `/package/` :

### 1. start-stop-status (lignes 4-7)
```bash
PHP_FPM="${SYNOPKG_PKGDEST}/package/sbin/php-fpm"
PHP_FPM_CONF="${SYNOPKG_PKGDEST}/package/conf/php-fpm.conf"
WEB_SERVER="${SYNOPKG_PKGDEST}/package/scripts/web-server.sh"
```

### 2. postinst (lignes 6-7, 15, 42, 51, 56)
```bash
EXT_DIR="${SYNOPKG_PKGDEST}/package/lib/php/extensions/no-debug-non-zts-20230831"
PHP_INI="${SYNOPKG_PKGDEST}/package/etc/php.ini"
mkdir -p "${SYNOPKG_PKGDEST}/package/etc"
cp "${SYNOPKG_PKGDEST}/package/conf/backend.json" /usr/syno/etc/www/app.d/backend-php83.json
echo "$WEB_PORT" > "${SYNOPKG_PKGDEST}/package/etc/webserver.port"
ext_config="${SYNOPKG_PKGDEST}/package/etc/php-extensions-enabled.ini"
```

### 3. apply_extensions.sh (lignes 7-8, 10)
```bash
PHP_INI_DIR="/var/packages/php83/target/package/etc/conf.d"
PHP_BIN="/var/packages/php83/target/package/bin/php"
EXTENSIONS_JSON="/var/packages/php83/target/package/conf/extensions.json"
```

### 4. postuninst (ligne 5)
```bash
WEB_SERVER="/var/packages/php83/target/package/scripts/web-server.sh"
```

### 5. pre-start.sh (ligne 17)
```bash
/var/packages/php83/target/package/scripts/apply_extensions.sh
```

### 6. web-server.sh (lignes 7, 10)
```bash
PHP_BIN="/var/packages/php83/target/package/bin/php"
PORT_FILE="/var/packages/php83/target/package/etc/webserver.port"
```

## Package reconstruit

**Fichier** : `dist/php83_8.3.8-0001_geminilake.spk`
- **Taille** : 35 MiB (36,444,160 bytes)
- **MD5** : `1fb3d99a9e490090021246f568f6ab67`
- **SHA256** : `f13716b52c8a9799a69f3101d4e2a4cf1b12310dfd788d364cd303d89d7a69a7`
- **Date** : 2025-11-21 10:12:40 UTC

## Vérification de la structure

Pour vérifier que `package.tgz` contient bien le répertoire `package/` :

```bash
tar -tzf dist/build/package.tgz | head -10
```

Résultat attendu :
```
package/
package/bin/
package/bin/log-extension-event.sh
package/bin/phpdbg
package/bin/php-cgi
package/bin/php
package/lib/
...
```

## Test d'installation

```bash
# 1. Sur votre NAS, désinstaller l'ancienne version
sudo synopkg uninstall php83

# 2. Transférer le nouveau package
scp dist/php83_8.3.8-0001_geminilake.spk admin@<IP_NAS>:/tmp/

# 3. Installer via le Centre de paquets DSM

# 4. Vérifier le démarrage
sudo synopkg status php83

# 5. Vérifier les fichiers
ls -la /var/packages/php83/target/package/bin/php
ls -la /var/packages/php83/target/package/sbin/php-fpm

# 6. Tester PHP
/var/packages/php83/target/package/bin/php -v

# 7. Vérifier les logs
sudo cat /var/log/php83-startup.log
```

## Pourquoi cette erreur ?

1. J'avais déduit que les chemins avec `/package/` étaient faux en voyant l'erreur
2. Je n'avais PAS vérifié la structure réelle de `package.tgz`
3. J'avais supposé que DSM extrait le contenu de `package.tgz` directement à la racine
4. En réalité, **`package.tgz` contient un répertoire `package/` et DSM le préserve**

## Leçon apprise

Toujours vérifier la structure réelle du package avant de modifier les chemins :
```bash
tar -tzf dist/build/package.tgz | head -20
```

Et sur le NAS après installation :
```bash
ls -la /volume1/@appstore/php83/
```

Cette vérification aurait immédiatement révélé que le répertoire `package/` existe vraiment.
