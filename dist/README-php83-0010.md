# PHP 8.3 pour Synology DSM 7.x - Package Final

## Informations du Package

- **Nom:** php83_8.3.8-0010_geminilake.spk
- **Version:** 8.3.8-0010
- **Architecture:** Geminilake (DS920+, DS1520+, DS720+, DS420+, etc.)
- **Taille:** 35 MiB
- **MD5:** 82ff9de82078918d70cf51e5b4bd6613

## Fonctionnalités

✅ **PHP 8.3.8 complet** avec PHP-FPM et CLI
✅ **Intégration Web Station** via Package Worker
✅ **Gestion des extensions** via l'interface Web Station
✅ **Port FPM dédié:** 9083 (évite les conflits)
✅ **Support systemctl** pour DSM 7.x
✅ **Auto-registration** avec Web Station à l'installation
✅ **Extensions incluses:**
  - opcache, curl, mysqli, pdo_mysql, pdo_sqlite
  - sqlite3, gd, openssl, xml, dom, simplexml
  - xmlreader, xmlwriter, zlib, fileinfo, exif
  - session, filter, ctype, tokenizer, soap
  - sockets, ftp, gettext, calendar, bcmath
  - posix, pcntl

## Installation

### Méthode 1: Via l'interface DSM (Recommandée)

1. Ouvrez **Centre de paquets** dans DSM
2. Cliquez sur **Installation manuelle** (bouton en haut à droite)
3. Sélectionnez le fichier `php83_8.3.8-0010_geminilake.spk`
4. Suivez l'assistant d'installation
5. Le package s'enregistrera automatiquement avec Web Station

### Méthode 2: Via SSH

```bash
# Copier le fichier sur le NAS
scp -P 44 php83_8.3.8-0010_geminilake.spk gilles@192.168.1.47:/tmp/

# Se connecter au NAS
ssh -p 44 gilles@192.168.1.47

# Installer le package
sudo synopkg install /tmp/php83_8.3.8-0010_geminilake.spk

# Démarrer le package
sudo synopkg start php83
```

## Utilisation avec Web Station

### Créer un profil PHP 8.3

1. Ouvrez **Web Station**
2. Allez dans **Paramètres du langage de script**
3. Cliquez sur **Créer** pour créer un nouveau profil PHP
4. Sélectionnez **PHP 8.3** dans la liste déroulante
5. Configurez les extensions et paramètres souhaités
6. Cliquez sur **OK**

### Assigner PHP 8.3 à un site web

1. Dans Web Station, allez dans **Portail Web**
2. Créez ou modifiez un site web
3. Dans les paramètres, sélectionnez le profil PHP 8.3 que vous avez créé
4. Appliquez les changements

## Configuration

### Fichiers de configuration

- **PHP-FPM:** `/var/packages/php83/target/package/conf/php-fpm.conf`
- **PHP.ini:** `/var/packages/php83/target/package/etc/php.ini`
- **Extensions:** `/var/packages/php83/target/package/conf/extension_list.json`

### Port d'écoute

PHP-FPM écoute sur `127.0.0.1:9083`

### Logs

- **PHP-FPM:** `/var/packages/php83/var/log/php-fpm.log`
- **Installation:** `/var/log/php83-install.log`

## Désinstallation

### Via DSM

1. Centre de paquets → php83 → Désinstaller

### Via SSH

```bash
sudo synopkg stop php83
sudo synopkg uninstall php83
```

## Notes importantes

- Ce package est conçu spécifiquement pour les NAS Synology avec architecture Geminilake
- DSM 7.0 ou supérieur est requis
- Le package s'auto-enregistre avec Web Station lors de l'installation
- Les répertoires runtime sont créés automatiquement dans `/var/packages/php83/var/`

## Support et Dépannage

### Vérifier l'état du service

```bash
systemctl status pkgctl-php83
```

### Vérifier que PHP-FPM écoute

```bash
netstat -tln | grep 9083
```

### Vérifier l'enregistrement Web Station

```bash
cat /usr/syno/etc/packages/WebStation/PluginPackage.json | grep php83
```

### Relancer l'enregistrement Web Station (si nécessaire)

```bash
sudo systemctl restart pkg-WebStation
```

## Historique des versions

### Version 8.3.8-0010 (22 Nov 2025)
- ✅ Ajout de l'intégration Web Station via Package Worker
- ✅ Auto-registration avec Web Station
- ✅ Changement du port FPM vers 9083 (évite les conflits)
- ✅ Support systemctl pour DSM 7.x
- ✅ Ajout de PKG_PHP.json, default_settings.json, extension_list.json
- ✅ Amélioration du script postinst

### Version 8.3.8-0009
- Première version fonctionnelle avec backend Web Station manuel

### Version 8.3.8-0007
- Version de base fonctionnelle sans intégration Web Station

## Développement

Ce package a été construit avec:
- Binaires PHP compilés depuis les sources officielles
- Scripts d'installation personnalisés pour DSM 7.x
- Intégration Web Station selon la documentation Synology Developer Guide

**Construit le:** 22 Novembre 2025
**Construit sur:** DS920+ (Geminilake)
