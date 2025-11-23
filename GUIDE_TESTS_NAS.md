# Guide de Tests PHP 8.3 sur Synology NAS

## 🎯 Informations du NAS

- **Hostname**: ServeurNAS
- **IP**: 192.168.1.47
- **Port SSH**: 44
- **Architecture**: Geminilake (DS920+)

---

## 📋 Plan de Test Complet

### Phase 1: Vérification Locale (sur Windows)

Avant de transférer sur le NAS, vérifiez que le package est correct :

```bash
# Vérifier que le SPK existe
ls -lh dist/php83_8.3.8-0001_geminilake.spk

# Vérifier le contenu du SPK
tar -tf dist/php83_8.3.8-0001_geminilake.spk | head -20

# Vérifier le fichier INFO
tar -xOf dist/php83_8.3.8-0001_geminilake.spk INFO

# Vérifier les binaires PHP
tar -xOf dist/php83_8.3.8-0001_geminilake.spk package.tgz | tar -tz | grep -E "bin/php|sbin/php-fpm"

# Vérifier les extensions
tar -xOf dist/php83_8.3.8-0001_geminilake.spk package.tgz | tar -tz | grep "\.so$" | wc -l
```

**Résultat attendu**:
- SPK de ~35 MB
- 36 extensions .so
- Binaires php et php-fpm présents

---

### Phase 2: Transfert et Installation sur le NAS

#### Option A: Script Automatisé (Recommandé)

```bash
# Définir votre utilisateur NAS
export NAS_USER=admin  # ou votre utilisateur admin

# Exécuter le script de déploiement
bash deploy-to-nas.sh
```

Le script vous guidera à travers :
1. Vérification des fichiers
2. Test de connexion SSH
3. Transfert du SPK et du script de test
4. Menu interactif pour installation et tests

#### Option B: Transfert Manuel

```bash
# 1. Créer un répertoire temporaire
NAS_USER=admin  # Ajustez selon votre utilisateur
ssh -p 44 ${NAS_USER}@192.168.1.47 "mkdir -p /tmp/php83-test"

# 2. Transférer le SPK
scp -P 44 dist/php83_8.3.8-0001_geminilake.spk ${NAS_USER}@192.168.1.47:/tmp/php83-test/

# 3. Transférer le script de test
scp -P 44 test-nas-complete.sh ${NAS_USER}@192.168.1.47:/tmp/php83-test/

# 4. Rendre le script exécutable
ssh -p 44 ${NAS_USER}@192.168.1.47 "chmod +x /tmp/php83-test/test-nas-complete.sh"
```

---

### Phase 3: Installation du Package

#### Via DSM (Interface Web)

1. **Ouvrez DSM** dans votre navigateur:
   ```
   http://192.168.1.47:5000
   ```

2. **Désinstaller l'ancienne version** (si elle existe):
   - Centre de paquets → PHP 8.3 → Désinstaller
   - Attendre la fin de la désinstallation

3. **Installer le nouveau package**:
   - Centre de paquets → Installation manuelle (bouton en haut à droite)
   - Parcourir → Sélectionner `/tmp/php83-test/php83_8.3.8-0001_geminilake.spk`
   - Suivre l'assistant

4. **Sélection des extensions**:
   L'assistant affichera un formulaire avec toutes les extensions disponibles, organisées par catégories :
   - ✅ **Core**: opcache, tokenizer, filter, ctype (recommandés)
   - ✅ **Database**: pdo, pdo_mysql, mysqli, pdo_sqlite
   - ✅ **Network**: curl, openssl, ftp, sockets
   - ✅ **Images**: gd, exif
   - ✅ **XML**: dom, xml, simplexml
   - ✅ **Compression**: zip, zlib, bz2
   - ✅ **i18n**: mbstring, intl, gettext, iconv
   - ✅ **Advanced**: bcmath, gmp, sodium, fileinfo, posix, pcntl

   **Conseil**: Sélectionnez au moins opcache, curl, mysqli/pdo_mysql, gd, mbstring, openssl

5. **Finaliser l'installation**:
   - Cliquez sur Suivant
   - Acceptez les conditions
   - Appliquer

---

### Phase 4: Tests Post-Installation

#### Exécution du Script de Test Complet

```bash
# Se connecter au NAS et exécuter le script de test
NAS_USER=admin
ssh -p 44 ${NAS_USER}@192.168.1.47 "bash /tmp/php83-test/test-nas-complete.sh"
```

**Le script testera automatiquement** :
1. ✅ Informations système (hostname, kernel, DSM version)
2. ✅ Installation du package (répertoires, structure)
3. ✅ Binaires PHP (php, php-fpm, php-cgi, phpdbg)
4. ✅ Extensions PHP (36 extensions attendues)
5. ✅ Fichiers de configuration (php.ini, php-fpm.conf)
6. ✅ Service (état du service pkgctl-php83)
7. ✅ Logs (php-fpm.log, php_errors.log)
8. ✅ Test fonctionnel (exécution d'un script PHP de test)
9. ✅ Intégration Web Station (si installé)
10. ✅ Interface DSM (app.config, index.html)

#### Tests Manuels Supplémentaires

**Vérifier la version PHP** :
```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "/var/packages/php83/target/bin/php -v"
```

**Lister les extensions chargées** :
```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "/var/packages/php83/target/bin/php -m"
```

**Tester la configuration PHP-FPM** :
```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "/var/packages/php83/target/sbin/php-fpm -t"
```

**Vérifier l'état du service** :
```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "sudo synoservicectl --status pkgctl-php83"
```

**Vérifier le processus PHP-FPM** :
```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "ps aux | grep php-fpm | grep -v grep"
```

**Vérifier le socket** :
```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "ls -la /var/packages/php83/var/run/php-fpm.sock"
```

**Afficher les logs** :
```bash
# Logs PHP-FPM
ssh -p 44 ${NAS_USER}@192.168.1.47 "tail -50 /var/packages/php83/var/log/php-fpm.log"

# Logs du package
ssh -p 44 ${NAS_USER}@192.168.1.47 "tail -50 /var/log/packages/php83.log"

# Logs d'installation
ssh -p 44 ${NAS_USER}@192.168.1.47 "tail -50 /var/log/synopkg.log | grep php83"
```

---

### Phase 5: Test de l'Interface DSM

1. **Ouvrir l'interface PHP 8.3** :
   - Menu principal DSM → PHP 8.3
   - Vous devriez voir le panneau de configuration des extensions

2. **Tester le panneau de configuration** :
   - Activer/désactiver des extensions
   - Vérifier que les dépendances sont correctement gérées
   - Appliquer les changements
   - Vérifier que PHP-FPM redémarre automatiquement

---

### Phase 6: Test Web Station (si applicable)

**Vérifier que PHP 8.3 est disponible dans Web Station** :

1. Ouvrez **Web Station**
2. Allez dans **Paramètres généraux** → **Paquets dorsaux PHP**
3. Vérifiez que **PHP 8.3** apparaît dans la liste

**Créer un site de test** :

1. Web Station → Portail Web → Créer
2. Sélectionner PHP 8.3 comme backend
3. Créer un fichier `info.php` dans le dossier du site :
   ```php
   <?php phpinfo(); ?>
   ```
4. Accéder au site et vérifier que PHP 8.3 s'affiche correctement

---

## 🔧 Dépannage

### Le service ne démarre pas

```bash
# Vérifier les logs
ssh -p 44 ${NAS_USER}@192.168.1.47 "cat /var/packages/php83/var/log/php-fpm.log"

# Tester la configuration
ssh -p 44 ${NAS_USER}@192.168.1.47 "/var/packages/php83/target/sbin/php-fpm -t"

# Démarrer manuellement
ssh -p 44 ${NAS_USER}@192.168.1.47 "sudo synoservicectl --start pkgctl-php83"
```

### Les extensions ne se chargent pas

```bash
# Vérifier le fichier php.ini
ssh -p 44 ${NAS_USER}@192.168.1.47 "grep ^extension /var/packages/php83/target/conf/php.ini"

# Vérifier que les fichiers .so existent
ssh -p 44 ${NAS_USER}@192.168.1.47 "ls -la /var/packages/php83/target/lib/php/extensions/no-debug-non-zts-20230831/"
```

### Le socket n'existe pas

```bash
# Vérifier les permissions du répertoire run
ssh -p 44 ${NAS_USER}@192.168.1.47 "ls -la /var/packages/php83/var/run/"

# Créer le répertoire si nécessaire
ssh -p 44 ${NAS_USER}@192.168.1.47 "sudo mkdir -p /var/packages/php83/var/run && sudo chown http:http /var/packages/php83/var/run"
```

### L'interface DSM ne s'ouvre pas

```bash
# Vérifier app.config
ssh -p 44 ${NAS_USER}@192.168.1.47 "cat /var/packages/php83/target/ui/app.config"

# Vérifier les permissions
ssh -p 44 ${NAS_USER}@192.168.1.47 "ls -la /var/packages/php83/target/ui/"
```

---

## 📊 Résultats Attendus

### Installation réussie si :
- ✅ Package installé dans `/var/packages/php83/`
- ✅ PHP version 8.3.8 affiché avec `php -v`
- ✅ 36 extensions compilées disponibles
- ✅ Extensions sélectionnées chargées (vérifier avec `php -m`)
- ✅ Service `pkgctl-php83` en cours d'exécution
- ✅ Socket `/var/packages/php83/var/run/php-fpm.sock` existe
- ✅ Processus `php-fpm` visible avec `ps aux`
- ✅ Interface DSM accessible depuis le menu principal
- ✅ PHP 8.3 visible dans Web Station (si installé)
- ✅ Aucune erreur dans `/var/packages/php83/var/log/php-fpm.log`

---

## 🧹 Nettoyage

Après les tests, nettoyez les fichiers temporaires :

```bash
ssh -p 44 ${NAS_USER}@192.168.1.47 "rm -rf /tmp/php83-test"
```

---

## 📝 Rapport de Test

Créez un rapport avec les résultats :

```bash
# Exécuter tous les tests et sauvegarder le résultat
ssh -p 44 ${NAS_USER}@192.168.1.47 "bash /tmp/php83-test/test-nas-complete.sh" > test-results-$(date +%Y%m%d-%H%M%S).txt

# Consulter le rapport
cat test-results-*.txt
```

---

## 🆘 Support

En cas de problème :

1. **Vérifiez les logs** (Phase 4)
2. **Consultez le guide de dépannage** ci-dessus
3. **Exécutez le script de diagnostic** complet
4. **Sauvegardez les logs** pour analyse

---

**Bonne chance avec les tests ! 🚀**
