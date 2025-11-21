# Guide d'Installation - PHP 8.3 pour Synology

## 📦 Fichiers du package

**Emplacement** : `/home/gilles/ProjetSPK/php8.3/dist/`

- `php83_8.3.8-0001_geminilake.spk` (35 MiB)
- `php83_8.3.8-0001_geminilake.spk.sha256`

## 🔧 Étapes d'installation

### 1. Désinstaller l'ancienne version (si nécessaire)

```bash
# Via l'interface DSM
Centre de paquets > Installés > php83 > Désinstaller
```

Ou via SSH :
```bash
sudo synopkg stop php83
sudo synopkg uninstall php83
```

### 2. Transférer le nouveau package

```bash
# Depuis votre machine locale
scp /home/gilles/ProjetSPK/php8.3/dist/php83_8.3.8-0001_geminilake.spk admin@192.168.1.X:/tmp/
```

Remplacez `192.168.1.X` par l'IP de votre NAS.

### 3. Installer le package

#### Via l'interface DSM (recommandé)
1. Ouvrir **Centre de paquets**
2. Cliquer sur **Installation manuelle** (icône en haut à droite)
3. Cliquer sur **Parcourir**
4. Sélectionner le fichier `.spk` dans `/tmp/`
5. Cliquer sur **Suivant** puis **Appliquer**

#### Via SSH
```bash
sudo synopkg install /tmp/php83_8.3.8-0001_geminilake.spk
sudo synopkg start php83
```

## ✅ Vérifications post-installation

### 1. Vérifier que le package est installé

```bash
synopkg status php83
```
Devrait afficher : `package php83 is running`

### 2. Vérifier que PHP-FPM écoute

```bash
netstat -tln | grep 9000
```
Devrait afficher : `tcp 0 0 127.0.0.1:9000 0.0.0.0:* LISTEN`

### 3. Vérifier l'enregistrement Web Station

```bash
ls -la /usr/syno/etc/www/app.d/php83.json
cat /usr/syno/etc/www/app.d/php83.json
```

### 4. Vérifier les logs

```bash
cat /var/log/php83-install.log
```

Devrait contenir :
```
[2025-11-21 ...] Web Station backend registered
[2025-11-21 ...] PHP 8.3 installed successfully
```

### 5. Vérifier dans Web Station

1. Ouvrir **Web Station** dans DSM
2. Aller dans **Paramètres généraux**
3. Cliquer sur **Version PHP**
4. **PHP 8.3** devrait apparaître dans la liste

## 🧪 Test avec un Virtual Host

### 1. Créer un Virtual Host

1. Dans **Web Station**, aller dans **Virtual Host**
2. Cliquer sur **Créer**
3. Configuration :
   - **Nom d'hôte** : `test.local` (ou autre)
   - **Port** : `80`
   - **Racine du document** : `/volume1/web/test` (ou autre)
   - **Backend HTTP** : Nginx
   - **Version PHP** : **PHP 8.3** ✅
4. Cliquer sur **OK**

### 2. Créer un fichier de test

```bash
# Se connecter en SSH
sudo mkdir -p /volume1/web/test
sudo chown http:http /volume1/web/test

# Créer info.php
sudo tee /volume1/web/test/info.php > /dev/null << 'EOF'
<?php
phpinfo();
EOF

sudo chown http:http /volume1/web/test/info.php
```

### 3. Tester l'accès

Ouvrir dans un navigateur :
```
http://IP_DU_NAS/info.php
```

Ou si vous avez configuré un Virtual Host :
```
http://test.local/info.php
```

Vous devriez voir la page `phpinfo()` avec :
- **PHP Version** : 8.3.8
- **Server API** : FPM/FastCGI
- Extensions chargées (opcache, mysqli, pdo_mysql, gd, curl, etc.)

## 🐛 Dépannage

### PHP 8.3 n'apparaît pas dans Web Station

1. Vérifier que le fichier backend.json existe :
```bash
cat /usr/syno/etc/www/app.d/php83.json
```

2. Redémarrer Web Station :
```bash
sudo synoservicectl --restart pkgctl-WebStation
```

3. Forcer le rechargement :
```bash
sudo synowebservice --reload-config
```

### PHP-FPM ne démarre pas

1. Vérifier les logs :
```bash
cat /var/packages/php83/var/log/php-fpm.log
```

2. Vérifier que le binaire existe :
```bash
ls -la /var/packages/php83/target/package/sbin/php-fpm
```

3. Tester le binaire :
```bash
/var/packages/php83/target/package/sbin/php-fpm --version
```

4. Redémarrer le service :
```bash
sudo synopkg stop php83
sudo synopkg start php83
```

### Erreur "Failed to start service"

1. Vérifier les permissions :
```bash
ls -la /var/packages/php83/var/
```

2. Corriger les permissions si nécessaire :
```bash
sudo chmod 1733 /var/packages/php83/var/sessions
sudo chmod 1777 /var/packages/php83/var/tmp
sudo chmod 755 /var/packages/php83/var/log
sudo chmod 755 /var/packages/php83/var/run
sudo chown -R http:http /var/packages/php83/var
```

3. Redémarrer :
```bash
sudo synopkg start php83
```

## 📊 Informations du package

- **Nom** : php83
- **Version** : 8.3.8-0008
- **Architecture** : geminilake (DS920+)
- **OS minimum** : DSM 7.0-40000
- **Taille** : 35 MiB
- **Extensions** : 36 extensions compilées

## 📝 Extensions disponibles

- **Core** : opcache, tokenizer, filter, ctype
- **Databases** : mysqli, mysqlnd, pdo, pdo_mysql, pdo_sqlite, sqlite3
- **Network** : curl, openssl, ftp, sockets
- **Images** : gd, exif
- **XML** : dom, xml, simplexml, xmlreader, xmlwriter, soap
- **Compression** : zlib
- **I/O** : fileinfo, session, phar
- **System** : posix, pcntl, shmop, sysvmsg, sysvsem, sysvshm
- **Math** : bcmath
- **Misc** : calendar, gettext, dba

## 🔐 Sécurité

Le fichier `php.ini` inclut les fonctions désactivées par défaut :
```
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
```

Pour autoriser ces fonctions (déconseillé), éditez :
```
/var/packages/php83/target/package/conf/php.ini
```

Puis redémarrez PHP-FPM :
```bash
sudo synopkg restart php83
```

## 📚 Documentation complémentaire

- `WEBSTATION_INTEGRATION.md` - Détails techniques de l'intégration
- `SIMPLIFICATION.md` - Historique des corrections
- `README.md` - Vue d'ensemble du projet
