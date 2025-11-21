# Guide d'installation - PHP 8.3 pour Synology DSM

## Package : php83_8.3.8-0001_geminilake.spk

---

## Pré-requis

### Système :
- **NAS Synology** : DS920+, DS918+, DS1019+, DS1520+ (architecture Geminilake)
- **DSM Version** : 7.2 ou supérieur (64 bits)
- **Espace disque** : 150 MB minimum
- **RAM** : 512 MB minimum disponible

### Packages optionnels (recommandés) :
- **Web Station** : Pour utiliser PHP 8.3 avec des sites web
- **MariaDB 10** : Pour les applications nécessitant MySQL/MariaDB

---

## Installation

### Méthode 1 : Via le Centre de paquets (recommandée)

1. **Ouvrir le Centre de paquets**
   - Connexion à DSM
   - Menu principal → Centre de paquets

2. **Installer manuellement**
   - Cliquer sur le bouton "Action" (⚙️) en haut à droite
   - Sélectionner "Installation manuelle"
   - Parcourir et sélectionner le fichier `php83_8.3.8-0001_geminilake.spk`

3. **Assistant d'installation**
   - Lire et accepter les conditions
   - **Étape importante** : Sélectionner les extensions PHP souhaitées
   - Configurer le port du serveur web (par défaut : 8380)
   - Cliquer sur "Suivant"

4. **Finaliser l'installation**
   - Revoir le résumé
   - Cliquer sur "Appliquer"
   - Attendre la fin de l'installation (~30 secondes)

5. **Vérifier l'installation**
   - Le package "PHP 8.3" apparaît dans "Installés"
   - Un bouton **"Ouvrir"** est visible à côté de "Arrêter"

---

## Configuration initiale

### 1. Gestion des extensions PHP

**Via l'interface graphique :**

1. Dans le Centre de paquets, localiser "PHP 8.3"
2. Cliquer sur le bouton **"Ouvrir"**
3. L'interface de gestion des extensions s'ouvre
4. Sélectionner/désélectionner les extensions selon vos besoins
5. Cliquer sur **"Enregistrer"**
6. Redémarrer le service PHP 8.3 pour appliquer les changements

**Extensions disponibles par catégorie :**

- **Base** : OPcache, Tokenizer, Filter, Ctype
- **Base de données** : PDO, PDO MySQL, MySQLi, PDO SQLite, SQLite3
- **Réseau** : cURL, OpenSSL, FTP, Sockets, SOAP
- **Images** : GD, EXIF
- **XML** : DOM, XML Parser, SimpleXML, XMLReader, XMLWriter
- **Compression** : Zip, Zlib, BZip2
- **I18n** : Mbstring, Intl, Gettext, Iconv
- **Avancées** : BCMath, GMP, Sodium, Fileinfo, POSIX, PCNTL

### 2. Intégration avec Web Station

**Activer PHP 8.3 pour les sites web :**

1. Ouvrir **Web Station**
2. Aller dans **"Paramètres généraux"** → **"Paramètres PHP"**
3. Dans "Version PHP par défaut", sélectionner **"PHP 8.3"**
4. Configurer les paramètres PHP si nécessaire :
   - Memory limit : 256M
   - Max execution time : 300s
   - Upload max filesize : 100M
5. Cliquer sur **"OK"**

**Créer un site web avec PHP 8.3 :**

1. Dans Web Station, cliquer sur **"Créer"** → **"Portail virtuel"**
2. Configurer :
   - Type : **PHP**
   - Backend : Sélectionner **"PHP 8.3"**
   - Nom d'hôte/Port : Configurer selon vos besoins
   - Document root : Sélectionner le dossier de votre site
3. Cliquer sur **"Créer"**

### 3. Configuration PHP personnalisée

**Modifier php.ini :**

1. Se connecter en SSH au NAS
2. Éditer le fichier de configuration :
   ```bash
   sudo nano /var/packages/php83/target/etc/php.ini
   ```
3. Modifier les paramètres souhaités
4. Enregistrer (Ctrl+O, Entrée, Ctrl+X)
5. Redémarrer PHP-FPM :
   ```bash
   sudo synopkgctl stop php83
   sudo synopkgctl start php83
   ```

---

## Vérification de l'installation

### 1. Vérifier que PHP fonctionne

**Via ligne de commande :**

```bash
# Se connecter en SSH
ssh admin@nas-ip

# Vérifier la version PHP
/var/packages/php83/target/bin/php -v

# Lister les extensions chargées
/var/packages/php83/target/bin/php -m

# Tester un script PHP
echo '<?php phpinfo(); ?>' > /tmp/test.php
/var/packages/php83/target/bin/php /tmp/test.php
```

**Via Web Station :**

1. Créer un fichier `info.php` dans le document root de votre site :
   ```php
   <?php phpinfo(); ?>
   ```
2. Accéder à `http://votre-nas/info.php`
3. Vérifier que la version affichée est **8.3.8**
4. Vérifier la liste des extensions chargées

### 2. Vérifier les services

**Vérifier que PHP-FPM est actif :**

```bash
# Vérifier le statut du service
sudo synopkgctl status php83

# Vérifier le processus PHP-FPM
ps aux | grep php-fpm

# Vérifier le socket FastCGI
ls -la /var/packages/php83/var/run/php-fpm.sock
```

**Vérifier les logs :**

```bash
# Logs d'installation
tail -50 /var/log/php83-install.log

# Logs PHP-FPM
tail -50 /var/packages/php83/var/log/php-fpm.log

# Logs d'erreurs PHP
tail -50 /var/packages/php83/var/log/php-errors.log
```

---

## Utilisation

### 1. Exécuter un script PHP en ligne de commande

```bash
# Exécuter un script
/var/packages/php83/target/bin/php script.php

# Avec arguments
/var/packages/php83/target/bin/php script.php arg1 arg2

# Mode interactif
/var/packages/php83/target/bin/php -a
```

### 2. Utiliser PHP-FPM avec nginx

**Configuration nginx (exemple) :**

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/services/web/mysite;
    index index.php index.html;

    location ~ \.php$ {
        fastcgi_pass unix:/var/packages/php83/var/run/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### 3. Applications web compatibles

**Frameworks et CMS testés :**

- ✅ **WordPress** 6.4+ (avec MySQL/MariaDB)
- ✅ **Laravel** 10+ (nécessite Composer)
- ✅ **Symfony** 6+ (nécessite Composer)
- ✅ **PrestaShop** 8+
- ✅ **Nextcloud** 28+
- ✅ **Joomla** 5+
- ✅ **Drupal** 10+

**Extensions requises courantes :**
- WordPress : mysqli, gd, curl, openssl, zip, xml
- Laravel : pdo_mysql, openssl, mbstring, tokenizer, xml, ctype
- Nextcloud : gd, curl, zip, xml, mbstring, intl, fileinfo

---

## Gestion du service

### Démarrer/Arrêter PHP 8.3

**Via l'interface DSM :**

1. Ouvrir le Centre de paquets
2. Localiser "PHP 8.3"
3. Utiliser les boutons "Démarrer" / "Arrêter"

**Via ligne de commande :**

```bash
# Démarrer
sudo synopkgctl start php83

# Arrêter
sudo synopkgctl stop php83

# Redémarrer
sudo synopkgctl restart php83

# Statut
sudo synopkgctl status php83
```

### Activer le démarrage automatique

1. Centre de paquets → PHP 8.3
2. Menu "Action" → "Paramètres"
3. Cocher "Exécuter automatiquement après le démarrage de DSM"

---

## Dépannage

### Problème : Le bouton "Ouvrir" n'apparaît pas

**Solution :**

1. Vérifier que le package est bien installé :
   ```bash
   ls -la /var/packages/php83/
   ```

2. Vérifier la présence de l'interface UI :
   ```bash
   ls -la /var/packages/php83/target/ui/
   ```

3. Réinstaller le package si nécessaire

### Problème : PHP 8.3 n'apparaît pas dans Web Station

**Solution :**

1. Vérifier l'enregistrement Web Station :
   ```bash
   cat /usr/syno/etc/www/app.d/backend-php83.json
   ```

2. Si le fichier est absent, copier manuellement :
   ```bash
   sudo cp /var/packages/php83/target/conf/backend.json \
           /usr/syno/etc/www/app.d/backend-php83.json
   sudo chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
   ```

3. Redémarrer Web Station

### Problème : Erreur "Cannot load extension..."

**Solution :**

1. Vérifier que l'extension existe :
   ```bash
   ls -la /var/packages/php83/target/lib/php/extensions/no-debug-non-zts-20230831/
   ```

2. Vérifier la configuration :
   ```bash
   cat /var/packages/php83/target/etc/php-extensions-enabled.ini
   ```

3. Utiliser l'interface de gestion pour réactiver l'extension

4. Redémarrer PHP-FPM

### Problème : Erreur de permissions

**Solution :**

```bash
# Réparer les permissions
sudo chown -R php83:php83 /var/packages/php83/var/
sudo chmod 1733 /var/packages/php83/var/sessions
sudo chmod 1777 /var/packages/php83/var/tmp
sudo chmod 660 /var/packages/php83/var/run/php-fpm.sock
sudo chown http:http /var/packages/php83/var/run/php-fpm.sock
```

### Problème : Performance lente

**Solutions :**

1. Activer OPcache :
   - Interface de gestion → Cocher "OPcache"
   - Enregistrer et redémarrer

2. Augmenter la mémoire allouée :
   ```bash
   # Éditer php.ini
   sudo nano /var/packages/php83/target/etc/php.ini

   # Modifier
   memory_limit = 512M
   opcache.memory_consumption = 128
   ```

3. Optimiser PHP-FPM :
   ```bash
   # Éditer php-fpm.conf
   sudo nano /var/packages/php83/target/conf/php-fpm.conf

   # Ajuster
   pm.max_children = 20
   pm.start_servers = 4
   pm.min_spare_servers = 2
   pm.max_spare_servers = 6
   ```

---

## Mise à jour

### Procédure de mise à jour

1. **Sauvegarder la configuration actuelle**
   ```bash
   sudo cp /var/packages/php83/target/etc/php.ini /tmp/php.ini.backup
   sudo cp /var/packages/php83/target/etc/php-extensions-enabled.ini /tmp/php-ext.backup
   ```

2. **Installer la nouvelle version**
   - Centre de paquets → Action → Installation manuelle
   - Sélectionner le nouveau fichier SPK
   - L'installation écrasera l'ancienne version

3. **Vérifier la configuration**
   - Comparer avec les fichiers sauvegardés
   - Réappliquer les modifications personnalisées si nécessaire

4. **Redémarrer le service**
   ```bash
   sudo synopkgctl restart php83
   ```

---

## Désinstallation

### Procédure complète

1. **Arrêter les sites web utilisant PHP 8.3**
   - Web Station → Arrêter les portails virtuels concernés

2. **Désinstaller via le Centre de paquets**
   - Localiser "PHP 8.3"
   - Cliquer sur "Désinstaller"
   - Confirmer la suppression

3. **Nettoyage manuel (optionnel)**
   ```bash
   # Supprimer les données résiduelles
   sudo rm -rf /var/packages/php83/
   sudo rm -f /usr/syno/etc/www/app.d/backend-php83.json
   sudo rm -f /var/log/php83-*.log
   ```

---

## Support et ressources

### Fichiers de logs

- **Installation** : `/var/log/php83-install.log`
- **PHP-FPM** : `/var/packages/php83/var/log/php-fpm.log`
- **Erreurs PHP** : `/var/packages/php83/var/log/php-errors.log`
- **Système** : `/var/log/messages`

### Documentation

- Documentation officielle PHP : https://www.php.net/docs.php
- Synology DSM Guide : https://www.synology.com/support
- PHP 8.3 Release Notes : https://www.php.net/releases/8.3/en.php

### Informations du package

- **Version PHP** : 8.3.8
- **Architecture** : Geminilake (Intel Celeron J4125)
- **Compatible avec** : DS920+, DS918+, DS1019+, DS1520+
- **DSM minimum** : 7.2-64570
- **Taille du package** : 35 MB

---

**Date de publication :** 2025-11-20
**Version du guide :** 1.0
**Auteur :** Gilles
