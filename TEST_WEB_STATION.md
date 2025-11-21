# Guide de test - Intégration Web Station pour PHP 8.3

## Nouveau package avec PHP-FPM automatique

**Fichier** : `dist/php83_8.3.8-0001_geminilake.spk`
**MD5** : `e655a859b7cd41db25865e0e2197a9c4`
**Date** : 2025-11-20

### Modifications apportées

✅ **PHP-FPM démarre automatiquement** au lancement du package
✅ Le bouton "Ouvrir" fonctionne
✅ Intégration Web Station configurée

---

## Étape 1 : Installation du package

### 1.1 Désinstaller l'ancienne version (si installée)

```bash
# Sur le Synology via SSH
sudo synopkg stop php83
sudo synopkg uninstall php83
```

### 1.2 Installer la nouvelle version

1. Copier `dist/php83_8.3.8-0001_geminilake.spk` sur votre NAS
2. Ouvrir le **Gestionnaire de paquets**
3. Cliquer sur **Installation manuelle**
4. Sélectionner le fichier SPK
5. Suivre l'assistant d'installation
6. Sélectionner les extensions PHP souhaitées
7. Valider l'installation

---

## Étape 2 : Vérification de PHP-FPM

### 2.1 Vérifier que PHP-FPM est démarré

```bash
# Via SSH sur le Synology
sudo synopkg status php83
```

**Résultat attendu** : `package php83 is running`

### 2.2 Vérifier le processus PHP-FPM

```bash
ps aux | grep php-fpm | grep -v grep
```

**Résultat attendu** :
```
http      12345  0.0  0.5  123456  45678 ?  Ss   14:00   0:00 php-fpm: master process
http      12346  0.0  0.3  123456  34567 ?  S    14:00   0:00 php-fpm: pool www
http      12347  0.0  0.3  123456  34567 ?  S    14:00   0:00 php-fpm: pool www
```

### 2.3 Vérifier le socket PHP-FPM

```bash
ls -la /var/packages/php83/var/run/php-fpm.sock
```

**Résultat attendu** :
```
srw-rw---- 1 http http 0 Nov 20 14:00 /var/packages/php83/var/run/php-fpm.sock
```

**Important** : Le socket doit avoir les permissions `660` et appartenir à `http:http`

### 2.4 Vérifier le fichier PID

```bash
cat /var/packages/php83/var/run/php-fpm.pid
```

**Résultat attendu** : Un numéro de PID (ex: `12345`)

---

## Étape 3 : Vérification de l'enregistrement Web Station

### 3.1 Vérifier le fichier backend

```bash
cat /usr/syno/etc/www/app.d/backend-php83.json
```

**Résultat attendu** : Le fichier doit contenir la configuration JSON :
```json
{
  "service": "php83",
  "display_name": "PHP 8.3",
  "support_alias": true,
  "support_server": true,
  "type": "nginx_php",
  ...
}
```

### 3.2 Vérifier les permissions

```bash
ls -la /usr/syno/etc/www/app.d/backend-php83.json
```

**Résultat attendu** :
```
-rw-r--r-- 1 root root 1237 Nov 20 14:00 /usr/syno/etc/www/app.d/backend-php83.json
```

---

## Étape 4 : Test dans Web Station

### 4.1 Redémarrer Web Station

```bash
sudo synopkg stop WebStation
sudo synopkg start WebStation
```

### 4.2 Vérifier PHP 8.3 dans Web Station

1. Ouvrir **Web Station**
2. Aller dans **Paramètres PHP** (ou **PHP Settings**)
3. Dans l'onglet **Profils PHP**

**Résultat attendu** : "PHP 8.3" doit apparaître dans la liste des profils disponibles

### 4.3 Créer un site de test

1. Dans Web Station, cliquer sur **Portail Web** → **Créer**
2. Choisir **Hôte virtuel basé sur le port**
3. Configurer :
   - **Nom** : `test-php83`
   - **Port HTTP** : `8088` (ou autre port libre)
   - **Dossier racine** : `/volume1/web/test-php83`
   - **Backend server** : **PHP 8.3** ⬅️ IMPORTANT
4. Cliquer sur **OK**

### 4.4 Créer un fichier PHP de test

```bash
# Créer le répertoire
sudo mkdir -p /volume1/web/test-php83
sudo chown http:http /volume1/web/test-php83

# Créer un fichier phpinfo
sudo tee /volume1/web/test-php83/index.php << 'EOF'
<?php
phpinfo();
?>
EOF

sudo chown http:http /volume1/web/test-php83/index.php
```

### 4.5 Tester l'accès

Ouvrir dans un navigateur :
```
http://<IP_SYNOLOGY>:8088/
```

**Résultat attendu** : Page phpinfo() s'affiche avec :
- **PHP Version** : `8.3.8`
- **Server API** : `FPM/FastCGI`
- **Configuration File** : `/var/packages/php83/target/etc/php.ini`

---

## Étape 5 : Vérification des extensions

### 5.1 Vérifier les extensions chargées

Dans la page phpinfo(), chercher la section **Loaded Configuration File** et vérifier que les extensions sont bien chargées.

### 5.2 Tester une extension spécifique

Créer `/volume1/web/test-php83/test-extensions.php` :

```php
<?php
echo "<h1>Test des extensions PHP 8.3</h1>";

$extensions = [
    'opcache',
    'mysqli',
    'pdo_mysql',
    'gd',
    'curl',
    'openssl',
    'zip',
    'xml',
    'json'
];

echo "<table border='1'>";
echo "<tr><th>Extension</th><th>Status</th></tr>";
foreach ($extensions as $ext) {
    $loaded = extension_loaded($ext);
    $status = $loaded ? '✅ Chargée' : '❌ Non chargée';
    echo "<tr><td>$ext</td><td>$status</td></tr>";
}
echo "</table>";

echo "<h2>Connexion MySQL</h2>";
if (extension_loaded('mysqli')) {
    echo "✅ Extension mysqli disponible<br>";
    echo "Vous pouvez maintenant tester la connexion à votre base de données MySQL/MariaDB";
} else {
    echo "❌ Extension mysqli non disponible";
}
?>
```

Accéder à : `http://<IP_SYNOLOGY>:8088/test-extensions.php`

---

## Étape 6 : Test du bouton "Ouvrir"

### 6.1 Accès via le Centre de paquets

1. Ouvrir le **Centre de paquets** (ou **Gestionnaire de paquets**)
2. Localiser **PHP 8.3** dans la liste des paquets installés
3. Cliquer sur **Ouvrir**

**Résultat attendu** : L'interface de gestion des extensions PHP s'ouvre

### 6.2 Test de l'interface de gestion

1. Vérifier que la liste des extensions s'affiche
2. Tester l'activation/désactivation d'une extension
3. Sauvegarder les modifications
4. Redémarrer PHP-FPM :

```bash
sudo synopkg stop php83
sudo synopkg start php83
```

5. Recharger `http://<IP_SYNOLOGY>:8088/test-extensions.php`
6. Vérifier que les changements sont appliqués

---

## Étape 7 : Tests de performance

### 7.1 Test de charge simple

Créer `/volume1/web/test-php83/bench.php` :

```php
<?php
$start = microtime(true);

// Calcul simple
$result = 0;
for ($i = 0; $i < 1000000; $i++) {
    $result += $i;
}

$time = microtime(true) - $start;
echo "Calcul de 1 million d'itérations : " . number_format($time, 4) . " secondes<br>";

// Test OPcache
if (function_exists('opcache_get_status')) {
    $status = opcache_get_status();
    echo "<h2>OPcache Status</h2>";
    echo "Enabled: " . ($status['opcache_enabled'] ? 'Oui' : 'Non') . "<br>";
    echo "Cache full: " . ($status['cache_full'] ? 'Oui' : 'Non') . "<br>";
    echo "Hit rate: " . number_format($status['opcache_statistics']['opcache_hit_rate'], 2) . "%<br>";
}
?>
```

### 7.2 Vérifier les logs

```bash
# Logs PHP-FPM
sudo tail -50 /var/packages/php83/var/log/php-fpm.log

# Logs d'erreurs PHP
sudo tail -50 /var/packages/php83/var/log/php-fpm-www-error.log
```

---

## Dépannage

### Problème : PHP-FPM ne démarre pas

**Diagnostic** :
```bash
# Vérifier les logs
sudo tail -100 /var/packages/php83/var/log/php-fpm.log

# Tester le démarrage manuel
sudo /var/packages/php83/target/sbin/php-fpm \
  --fpm-config /var/packages/php83/target/etc/php-fpm.conf \
  --pid /var/packages/php83/var/run/php-fpm.pid
```

**Solutions courantes** :
- Vérifier que le port/socket n'est pas déjà utilisé
- Vérifier les permissions sur `/var/packages/php83/var/run/`
- Vérifier que l'utilisateur `http` existe

### Problème : PHP 8.3 n'apparaît pas dans Web Station

**Solutions** :
```bash
# Vérifier le fichier backend
cat /usr/syno/etc/www/app.d/backend-php83.json

# Réenregistrer le backend
sudo cp /var/packages/php83/target/conf/backend.json \
  /usr/syno/etc/www/app.d/backend-php83.json
sudo chmod 644 /usr/syno/etc/www/app.d/backend-php83.json

# Redémarrer Web Station
sudo synopkg stop WebStation
sudo synopkg start WebStation
```

### Problème : Le socket n'existe pas

**Solutions** :
```bash
# Créer le répertoire
sudo mkdir -p /var/packages/php83/var/run
sudo chown http:http /var/packages/php83/var/run
sudo chmod 755 /var/packages/php83/var/run

# Redémarrer PHP-FPM
sudo synopkg restart php83
```

### Problème : Erreur "502 Bad Gateway"

**Causes possibles** :
1. PHP-FPM n'est pas démarré
2. Permissions incorrectes sur le socket
3. Configuration nginx incorrecte

**Solutions** :
```bash
# Vérifier PHP-FPM
ps aux | grep php-fpm

# Vérifier le socket
ls -la /var/packages/php83/var/run/php-fpm.sock

# Redémarrer les deux services
sudo synopkg restart php83
sudo synopkg restart WebStation
```

---

## Checklist de validation

- [ ] Package installé sans erreur
- [ ] Bouton "Ouvrir" visible et fonctionnel
- [ ] PHP-FPM démarre automatiquement
- [ ] Socket PHP-FPM créé avec bonnes permissions
- [ ] Fichier backend copié dans `/usr/syno/etc/www/app.d/`
- [ ] PHP 8.3 visible dans Web Station
- [ ] Site de test créé et fonctionnel
- [ ] Page phpinfo() affiche PHP 8.3.8
- [ ] Extensions PHP chargées correctement
- [ ] Pas d'erreurs dans les logs
- [ ] Performance acceptable
- [ ] Redémarrage du service fonctionne

---

## Résumé des changements

### Version précédente
- ❌ PHP-FPM non démarré automatiquement
- ❌ Nécessitait de cocher l'option dans l'assistant

### Version actuelle (e655a859b7cd41db25865e0e2197a9c4)
- ✅ PHP-FPM démarre automatiquement au lancement du package
- ✅ Aucune action manuelle requise
- ✅ Intégration Web Station immédiate
- ✅ Script `start-stop-status` amélioré avec gestion PHP-FPM

---

**Date de création** : 2025-11-20
**Version du package** : 8.3.8-0001
**Architecture** : geminilake (DS920+)
**DSM Version** : 7.2.2-72806
