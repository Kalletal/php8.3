# PHP 8.3 pour Synology DSM 7.x - Package Final v0011

## Informations du Package

- **Nom:** php83_8.3.8-0011_geminilake.spk
- **Version:** 8.3.8-0011 ✅ **VERSION FINALE CORRIGÉE**
- **Architecture:** Geminilake (DS920+, DS1520+, DS720+, DS420+, etc.)
- **Taille:** 35 MiB (36,433,920 bytes)
- **MD5:** c5cc1821cc21f8ea2696efb94930d981
- **Date de build:** 22 Novembre 2025

## ⚠️ IMPORTANT - Nouveautés v0011

Cette version corrige les problèmes de la v0010:

✅ **Format correct de default_settings.json** (core/extensions au lieu de profile)
✅ **Enregistrement automatique** dans PluginPackage.json lors de l'installation
✅ **Nettoyage automatique** lors de la désinstallation
✅ **Compatible DSM 7.x** avec systemctl
✅ **Port FPM 9083** (évite les conflits avec PHP 8.0/8.1/8.2)

## Fonctionnalités

✅ **PHP 8.3.8 complet** avec PHP-FPM et CLI
✅ **Intégration Web Station automatique** - Apparaît dans le dropdown de création de profil
✅ **Gestion des extensions** via l'interface Web Station
✅ **Support JIT OPcache** pour meilleures performances
✅ **Extensions incluses:**
  - Core: opcache, openssl, zlib, fileinfo, ctype, filter, session
  - Bases de données: mysqli, pdo_mysql, pdo_sqlite, sqlite3
  - Web: curl, ftp, soap, sockets
  - Images: gd, exif
  - XML: xml, dom, simplexml, xmlreader, xmlwriter
  - Autres: gettext, calendar, bcmath, posix, pcntl, tokenizer

## Installation

### ⚠️ Si vous avez déjà php83 installé

**IMPORTANT:** Vous devez d'abord désinstaller la version actuelle:

```bash
# Via DSM
Centre de paquets → php83 → Désinstaller

# Via SSH
sudo synopkg stop php83
sudo synopkg uninstall php83
```

Le script `postuninst` nettoiera automatiquement:
- L'entrée dans PluginPackage.json
- Le fichier backend-php83.json
- Tous les fichiers de configuration Web Station

### Installation de la v0011

#### Méthode 1: Via DSM (Recommandée)

1. **Ouvrez le Centre de paquets**
2. Cliquez sur **Installation manuelle** (icône en haut à droite)
3. Sélectionnez `php83_8.3.8-0011_geminilake.spk`
4. Suivez l'assistant d'installation
5. **Le package s'enregistrera automatiquement** avec Web Station

#### Méthode 2: Via SSH

```bash
# Transférer le fichier
scp -P 44 php83_8.3.8-0011_geminilake.spk gilles@192.168.1.47:/tmp/

# Installer
ssh -p 44 gilles@192.168.1.47
sudo synopkg install /tmp/php83_8.3.8-0011_geminilake.spk
sudo synopkg start php83
```

### Vérification de l'installation

1. Vérifiez les logs d'installation:
```bash
cat /var/log/php83-install.log
```

2. Vérifiez que PHP 8.3 est enregistré:
```bash
cat /usr/syno/etc/packages/WebStation/PluginPackage.json | grep php83
```

3. Vérifiez que PHP-FPM écoute sur le bon port:
```bash
netstat -tln | grep 9083
# Devrait afficher: tcp 0 0 127.0.0.1:9083 ... LISTEN
```

## Utilisation avec Web Station

### Créer un profil PHP 8.3

1. Ouvrez **Web Station**
2. Allez dans **Paramètres du langage de script**
3. Cliquez sur **Créer**
4. **PHP 8.3 devrait maintenant apparaître** dans la liste déroulante des versions
5. Configurez le profil selon vos besoins:
   - Nom du profil (ex: "PHP 8.3 Production")
   - Extensions à activer
   - Paramètres PHP (memory_limit, etc.)
6. Cliquez sur **OK**

### Assigner à un site web

1. Dans Web Station → **Portail Web**
2. Créez ou éditez un site web
3. Dans **Backend**, sélectionnez le profil PHP 8.3 créé
4. Appliquez les changements

## Configuration

### Fichiers de configuration principaux

- **PHP-FPM:** `/var/packages/php83/target/package/conf/php-fpm.conf`
- **PHP.ini:** `/var/packages/php83/target/package/etc/php.ini`
- **Default settings:** `/var/packages/php83/target/package/conf/default_settings.json`
- **Extensions:** `/var/packages/php83/target/package/conf/extension_list.json`

### Paramètres par défaut

**PHP.ini:**
- memory_limit: 128M (modifiable via profil Web Station)
- max_execution_time: 240s
- upload_max_filesize: 32M
- post_max_size: 32M

**PHP-FPM:**
- Port d'écoute: 127.0.0.1:9083
- PM mode: dynamic
- Max children: 20
- Start servers: 2

### Logs

- **Installation:** `/var/log/php83-install.log`
- **PHP-FPM:** `/var/packages/php83/var/log/php-fpm.log`
- **PHP errors:** `/var/packages/php83/var/log/php-fpm-www-error.log`

## Dépannage

### PHP 8.3 n'apparaît pas dans Web Station

1. Vérifiez que le package est bien installé et démarré:
```bash
systemctl status pkgctl-php83
```

2. Vérifiez l'enregistrement dans PluginPackage.json:
```bash
sudo cat /usr/syno/etc/packages/WebStation/PluginPackage.json | grep -A 15 php83
```

3. Vérifiez les logs d'installation:
```bash
cat /var/log/php83-install.log | grep -E '(ERROR|WARNING|PluginPackage)'
```

4. Si nécessaire, redémarrez nginx:
```bash
sudo systemctl restart nginx
```

5. **Videz le cache de votre navigateur** ou utilisez une fenêtre de navigation privée

### Réenregistrer manuellement (si nécessaire)

Si l'enregistrement automatique échoue, vous pouvez utiliser le script manuel:

```bash
sudo bash /tmp/register-php83.sh
```

(Le script est créé lors de l'installation)

### Restaurer Web Station en cas de problème

Si Web Station cesse de fonctionner après l'installation:

```bash
# Restaurer le backup automatique
sudo cp /usr/syno/etc/packages/WebStation/PluginPackage.json.backup.* \
       /usr/syno/etc/packages/WebStation/PluginPackage.json
sudo systemctl restart nginx
```

## Désinstallation

### Via DSM
Centre de paquets → php83 → Désinstaller

### Via SSH
```bash
sudo synopkg stop php83
sudo synopkg uninstall php83
```

Le script `postuninst` nettoiera automatiquement toutes les configurations Web Station.

## Différences avec les versions précédentes

### v0011 vs v0010

| Aspect | v0010 (Cassée) | v0011 (Corrigée) |
|--------|----------------|------------------|
| default_settings.json | Format profil ❌ | Format core/extensions ✅ |
| Registration Web Station | Manuel ⚠️ | Automatique ✅ |
| Cleanup désinstallation | Partiel ⚠️ | Complet ✅ |
| Apparition dans dropdown | ❌ Non | ✅ Oui |

### v0011 vs v0009

- ✅ Format correct de tous les fichiers de configuration
- ✅ Enregistrement automatique (pas besoin de script manuel)
- ✅ Nettoyage complet lors de la désinstallation
- ✅ Logs détaillés pour le debug

## Support et Documentation

### Fichiers techniques

Pour les développeurs et administrateurs avancés:

- `postinst`: Script d'installation avec enregistrement automatique
- `postuninst`: Script de désinstallation avec nettoyage
- `PKG_PHP.json`: Configuration Package Worker (référence)
- `backend-php83.json`: Configuration backend Web Station

### Vérifications système

```bash
# Statut du service
systemctl status pkgctl-php83

# Processus PHP-FPM
ps aux | grep php-fpm | grep php83

# Port d'écoute
ss -tln | grep 9083

# Enregistrement Web Station
cat /usr/syno/etc/packages/WebStation/PluginPackage.json | python3 -m json.tool | grep -A 15 php83
```

## Notes Importantes

1. **Architecture:** Ce package est compilé pour Geminilake uniquement
2. **DSM Version:** Testé sur DSM 7.2.2, requis DSM 7.0+
3. **Web Station:** Doit être installé et démarré
4. **Permissions:** L'installation nécessite les droits administrateur
5. **Port 9083:** Assurez-vous qu'aucun autre service n'utilise ce port

## Historique des Versions

### v0011 (22 Nov 2025) - VERSION FINALE ✅
- ✅ Correction du format default_settings.json (core/extensions)
- ✅ Enregistrement automatique dans PluginPackage.json via postinst
- ✅ Nettoyage automatique via postuninst
- ✅ PHP 8.3 apparaît correctement dans le dropdown Web Station
- ✅ Support systemctl pour DSM 7.x
- ✅ Logs détaillés pour le débogage

### v0010 (22 Nov 2025) - ⚠️ Cassée (Ne pas utiliser)
- ❌ default_settings.json au mauvais format
- ❌ Casse l'interface Web Station
- ⚠️ À éviter

### v0009 (21 Nov 2025)
- Première version avec enregistrement Web Station (manuel)
- Backend fonctionnel mais nécessite scripts manuels

### v0007 (20 Nov 2025)
- Version de base fonctionnelle sans intégration Web Station

## Construit avec

- Binaires PHP 8.3.8 compilés depuis les sources officielles
- Configuration optimisée pour Synology DSM 7.x
- Scripts d'intégration Web Station selon documentation Synology
- Support systemctl natif

---

**Build Date:** 22 Novembre 2025
**Build Host:** DS920+ Geminilake
**Maintainer:** Gilles
**Support:** Vérifiez `/var/log/php83-install.log` pour les détails d'installation
