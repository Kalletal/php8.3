# PHP 8.3 pour Synology DSM 7.x - Package v0012

## Informations du Package

- **Nom:** php83_8.3.8-0012_geminilake.spk
- **Version:** 8.3.8-0012 ✅ **VERSION AVEC PACKAGE WORKER**
- **Architecture:** Geminilake (DS920+, DS1520+, DS720+, DS420+, etc.)
- **Taille:** 53 MiB (55,050,240 bytes)
- **MD5:** 998f50813dec72b44d496e28ab1ca678
- **Date de build:** 22 Novembre 2025

## ⚠️ IMPORTANT - Nouveautés v0012

Cette version utilise l'approche correcte pour l'intégration avec Web Station:

✅ **Package Worker Integration** - Utilise l'API officielle WebStation
✅ **Pas de modification manuelle** de PluginPackage.json
✅ **Auto-registration** via PKG_PHP.json dans le répertoire target
✅ **Nettoyage automatique** lors de la désinstallation (géré par Package Worker)
✅ **Compatible DSM 7.x** avec systemctl
✅ **Port FPM 9083** (évite les conflits avec PHP 8.0/8.1/8.2)

## Différences avec la v0011

### v0011 vs v0012

| Aspect | v0011 (Manuelle) | v0012 (Package Worker) |
|--------|-----------------|------------------------|
| Méthode d'enregistrement | Modification manuelle PluginPackage.json via Python ❌ | Package Worker automatique ✅ |
| PKG_PHP.json | Absent ❌ | Présent dans /target/ ✅ |
| Script postinst | 157 lignes avec code Python complexe ⚠️ | 50 lignes, simple et propre ✅ |
| Script postuninst | Nettoyage manuel de PluginPackage.json ⚠️ | Géré par Package Worker ✅ |
| Stabilité Web Station | Risque de casser l'interface ⚠️ | Stable, approche officielle ✅ |

### Modifications techniques

**Fichiers ajoutés:**
- `package/PKG_PHP.json` - Configuration Package Worker pour auto-registration

**Scripts simplifiés:**
- `postinst` - Réduit de 157 à ~50 lignes
- `postuninst` - Réduit de 87 à ~40 lignes

**Supprimé:**
- Modification manuelle de PluginPackage.json via Python
- Code de backup/restore de PluginPackage.json
- Logique d'enregistrement manuel complexe

## Fonctionnalités

✅ **PHP 8.3.8 complet** avec PHP-FPM et CLI
✅ **Intégration Web Station automatique** via Package Worker
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

### ⚠️ Désinstaller les versions précédentes

**IMPORTANT:** Si vous avez php83 v0011 ou antérieure, désinstallez-la d'abord:

```bash
# Via DSM
Centre de paquets → php83 → Désinstaller

# Via SSH
sudo synopkg stop php83
sudo synopkg uninstall php83
```

Après la désinstallation de v0011, restaurez Web Station si nécessaire:

```bash
# Restaurer le backup (si Web Station est cassé)
sudo cp /usr/syno/etc/packages/WebStation/PluginPackage.json.backup.* \
       /usr/syno/etc/packages/WebStation/PluginPackage.json
sudo systemctl restart nginx
```

### Installation de la v0012

#### Méthode 1: Via DSM (Recommandée)

1. **Ouvrez le Centre de paquets**
2. Cliquez sur **Installation manuelle** (icône en haut à droite)
3. Sélectionnez `php83_8.3.8-0012_geminilake.spk`
4. Suivez l'assistant d'installation
5. **Package Worker enregistrera automatiquement** PHP 8.3 avec Web Station

#### Méthode 2: Via SSH

```bash
# Transférer le fichier
scp -P 44 php83_8.3.8-0012_geminilake.spk gilles@192.168.1.47:/tmp/

# Installer
ssh -p 44 gilles@192.168.1.47
sudo synopkg install /tmp/php83_8.3.8-0012_geminilake.spk
sudo synopkg start php83
```

### Vérification de l'installation

1. Vérifiez les logs d'installation:
```bash
cat /var/log/php83-install.log
```

2. Vérifiez que PHP-FPM écoute sur le bon port:
```bash
netstat -tln | grep 9083
# Devrait afficher: tcp 0 0 127.0.0.1:9083 ... LISTEN
```

3. Vérifiez le statut du service:
```bash
systemctl status pkgctl-php83
```

4. Vérifiez que PKG_PHP.json est présent:
```bash
ls -la /var/packages/php83/target/package/PKG_PHP.json
```

## Utilisation avec Web Station

### Créer un profil PHP 8.3

1. Ouvrez **Web Station**
2. Allez dans **Paramètres du langage de script**
3. Cliquez sur **Créer**
4. **PHP 8.3 devrait apparaître** dans la liste déroulante des versions
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
- **Extension list:** `/var/packages/php83/target/package/conf/extension_list.json`
- **Package Worker:** `/var/packages/php83/target/package/PKG_PHP.json` (nouveau!)

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

2. Vérifiez que PKG_PHP.json est présent:
```bash
cat /var/packages/php83/target/package/PKG_PHP.json
```

3. Vérifiez les logs d'installation:
```bash
cat /var/log/php83-install.log | grep -E '(ERROR|WARNING|Package Worker)'
```

4. Redémarrez Web Station:
```bash
sudo systemctl restart nginx
```

5. **Redémarrez le package php83** pour déclencher le Package Worker:
```bash
sudo synopkg stop php83
sudo synopkg start php83
```

6. **Videz le cache de votre navigateur** ou utilisez une fenêtre de navigation privée

### Vérifier l'enregistrement Package Worker

```bash
# Vérifier que Package Worker a enregistré PHP 8.3
cat /usr/syno/etc/packages/WebStation/PluginPackage.json | python3 -m json.tool | grep -A 15 php83
```

Si PHP 8.3 n'apparaît pas dans PluginPackage.json, cela signifie que Package Worker n'a pas encore synchronisé. Essayez de redémarrer le package.

## Désinstallation

### Via DSM
Centre de paquets → php83 → Désinstaller

### Via SSH
```bash
sudo synopkg stop php83
sudo synopkg uninstall php83
```

Le Package Worker nettoiera automatiquement l'enregistrement dans PluginPackage.json.

## Historique des Versions

### v0012 (22 Nov 2025) - VERSION PACKAGE WORKER ✅
- ✅ Utilise Package Worker pour auto-registration (approche officielle)
- ✅ PKG_PHP.json dans /target/ pour synchronisation automatique
- ✅ Scripts postinst/postuninst simplifiés (pas de modification manuelle)
- ✅ Plus stable, ne casse pas Web Station
- ✅ Suit les recommandations officielles Synology

### v0011 (22 Nov 2025) - ⚠️ Approche manuelle (obsolète)
- ⚠️ Modification manuelle de PluginPackage.json via Python
- ⚠️ Risque de casser Web Station
- ⚠️ Scripts complexes et fragiles
- ✅ Format correct de default_settings.json

### v0010 (22 Nov 2025) - ❌ Cassée (Ne pas utiliser)
- ❌ default_settings.json au mauvais format
- ❌ Casse l'interface Web Station

### v0009 (21 Nov 2025)
- Première version avec enregistrement Web Station (manuel)

### v0007 (20 Nov 2025)
- Version de base fonctionnelle sans intégration Web Station

## Support et Documentation

### Architecture Package Worker

Le Package Worker est le mécanisme officiel de Synology pour l'intégration avec Web Station:

1. **Déclaration:** `pkg_worker="WebStation"` dans le fichier INFO
2. **Configuration:** PKG_PHP.json dans `/var/packages/php83/target/package/`
3. **Synchronisation:** Web Station lit PKG_PHP.json pendant la phase Acquire()
4. **Registration:** Web Station met à jour PluginPackage.json automatiquement
5. **Cleanup:** Web Station nettoie lors de la désinstallation

Cette approche est plus robuste et suit les standards officiels Synology.

### Vérifications système

```bash
# Statut du service
systemctl status pkgctl-php83

# Processus PHP-FPM
ps aux | grep php-fpm | grep php83

# Port d'écoute
ss -tln | grep 9083

# Fichiers Package Worker
ls -la /var/packages/php83/target/package/PKG_PHP.json
ls -la /var/packages/php83/target/package/backend-php83.json

# Enregistrement Web Station
cat /usr/syno/etc/packages/WebStation/PluginPackage.json | python3 -m json.tool | grep -A 15 php83
```

## Notes Importantes

1. **Architecture:** Ce package est compilé pour Geminilake uniquement
2. **DSM Version:** Testé sur DSM 7.2.2, requis DSM 7.0+
3. **Web Station:** Doit être installé et démarré
4. **Permissions:** L'installation nécessite les droits administrateur
5. **Port 9083:** Assurez-vous qu'aucun autre service n'utilise ce port
6. **Package Worker:** Nouvelle approche, plus stable que les versions précédentes

## Construit avec

- Binaires PHP 8.3.8 compilés depuis les sources officielles
- Configuration optimisée pour Synology DSM 7.x
- **Package Worker** pour intégration Web Station automatique
- Scripts d'installation simplifiés et robustes
- Support systemctl natif

---

**Build Date:** 22 Novembre 2025
**Build Host:** Windows (Jle-Gamerz)
**Maintainer:** Gilles
**Support:** Vérifiez `/var/log/php83-install.log` pour les détails d'installation

**Approche:** Package Worker (officielle Synology) ✅
**Stabilité:** Haute - Ne modifie pas manuellement les fichiers système
