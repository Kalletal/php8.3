# 🎯 Solution Complète: Intégration Web Station PHP 8.3

## 📋 Résumé du Problème

Votre package PHP 8.3 s'installe correctement mais **n'apparaît pas dans Web Station** comme option de backend PHP.

### Cause Identifiée

Le script `postinst` copie le fichier backend avec un **nom incorrect**:
- ❌ Copié comme: `/usr/syno/etc/www/app.d/php83.json`
- ✅ Devrait être: `/usr/syno/etc/www/app.d/backend-php83.json`

Web Station recherche spécifiquement les fichiers nommés `backend-*.json`

---

## 🚀 Solutions (2 Options)

### Option A: Correctif Rapide (Sans Reconstruire le SPK)

**Avantages**: Rapide, pas besoin de reconstruire le package
**Inconvénient**: Doit être appliqué après chaque installation

#### Étapes:

1. **Installer le package normalement** via DSM

2. **Transférer le script de correctif** sur le NAS:
   ```bash
   scp -P 44 fix-webstation.sh admin@192.168.1.47:/tmp/
   ```

3. **Se connecter au NAS** et exécuter le correctif:
   ```bash
   ssh -p 44 admin@192.168.1.47
   bash /tmp/fix-webstation.sh
   ```

4. **Vérifier dans Web Station**:
   - Ouvrir Web Station → Paramètres PHP
   - PHP 8.3 devrait maintenant apparaître

---

### Option B: Reconstruire le SPK avec le Correctif Intégré

**Avantages**: Solution permanente, aucune action post-installation nécessaire
**Inconvénient**: Nécessite de reconstruire le SPK

#### Étapes:

1. **Éditer** `spk/php83/src/scripts/postinst`
2. **Remplacer** la section Web Station (lignes 30-56)
3. **Éditer** `spk/php83/src/scripts/postuninst`
4. **Reconstruire** le SPK
5. **Installer** le nouveau SPK sur le NAS

Les modifications détaillées sont dans `PROBLEME_WEB_STATION.md`

---

## 📝 Script Postinst Corrigé

Voici la version corrigée à intégrer dans `spk/php83/src/scripts/postinst`:

```bash
# Register with Web Station
BACKEND_JSON="${SYNOPKG_PKGDEST}/package/conf/backend.json"
echo "[$(date)] Looking for backend.json at: ${BACKEND_JSON}"

if [ -f "${BACKEND_JSON}" ]; then
    echo "[$(date)] backend.json found, registering with Web Station"

    # Copy to app.d with correct name (backend-php83.json)
    mkdir -p /usr/syno/etc/www/app.d
    cp -f "${BACKEND_JSON}" /usr/syno/etc/www/app.d/backend-php83.json
    chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
    echo "[$(date)] Copied to /usr/syno/etc/www/app.d/backend-php83.json"

    # Also copy to WebStation backends if directory exists
    if [ -d "/usr/syno/etc/packages/WebStation" ]; then
        mkdir -p /usr/syno/etc/packages/WebStation/backends
        cp -f "${BACKEND_JSON}" /usr/syno/etc/packages/WebStation/backends/backend-php83.json
        chmod 644 /usr/syno/etc/packages/WebStation/backends/backend-php83.json
        echo "[$(date)] Copied to /usr/syno/etc/packages/WebStation/backends/backend-php83.json"
    fi

    # Reload Web Station configuration
    if command -v synoservicectl >/dev/null 2>&1; then
        echo "[$(date)] Reloading nginx"
        synoservicectl --reload nginx 2>&1 || true
    fi

    echo "[$(date)] Web Station backend registered"
else
    echo "[$(date)] ERROR: backend.json not found at ${BACKEND_JSON}"
    ls -la "${SYNOPKG_PKGDEST}/package/conf/" || echo "Directory does not exist"
fi
```

---

## 🔧 Plan d'Action Recommandé

### Scénario 1: Test Rapide (Aujourd'hui)

1. ✅ Installer le SPK actuel (php83_8.3.8-0001_geminilake.spk)
2. ✅ Appliquer le correctif `fix-webstation.sh`
3. ✅ Vérifier que PHP 8.3 apparaît dans Web Station
4. ✅ Créer un site de test
5. ✅ Valider que tout fonctionne

**Commandes**:
```bash
# Définir l'utilisateur NAS
export NAS_USER=admin

# Transférer les fichiers
scp -P 44 dist/php83_8.3.8-0001_geminilake.spk ${NAS_USER}@192.168.1.47:/tmp/
scp -P 44 fix-webstation.sh ${NAS_USER}@192.168.1.47:/tmp/
scp -P 44 test-nas-complete.sh ${NAS_USER}@192.168.1.47:/tmp/

# Installer via DSM (interface web)
# Puis appliquer le correctif:
ssh -p 44 ${NAS_USER}@192.168.1.47 "bash /tmp/fix-webstation.sh"

# Exécuter les tests
ssh -p 44 ${NAS_USER}@192.168.1.47 "bash /tmp/test-nas-complete.sh"
```

---

### Scénario 2: Solution Permanente (Après Validation)

Une fois que vous avez validé que le correctif fonctionne:

1. **Modifier les scripts source**:
   - `spk/php83/src/scripts/postinst` (corrections ci-dessus)
   - `spk/php83/src/scripts/postuninst` (voir PROBLEME_WEB_STATION.md)

2. **Reconstruire le SPK**:
   ```bash
   bash scripts/build-spk.sh
   ```

3. **Le nouveau SPK** inclura le correctif et fonctionnera immédiatement

---

## ✅ Checklist de Validation

Après avoir appliqué la solution (A ou B):

### Sur le NAS (via SSH)

```bash
# 1. Vérifier le nom du fichier backend
ls -la /usr/syno/etc/www/app.d/backend-php83.json
# Doit exister avec le bon nom

# 2. Vérifier le contenu
cat /usr/syno/etc/www/app.d/backend-php83.json | grep "PHP 8.3"
# Doit afficher "display_name": "PHP 8.3"

# 3. Vérifier PHP-FPM
ps aux | grep php-fpm | grep -v grep
# Doit afficher les processus PHP-FPM

# 4. Vérifier le port 9000
netstat -tlnp | grep 9000
# Doit afficher que le port 9000 est en écoute

# 5. Vérifier l'état du service
synoservicectl --status pkgctl-php83
# Doit afficher "running"
```

### Dans DSM (Interface Web)

1. **Web Station** → **Paramètres PHP**
   - [ ] PHP 8.3 apparaît dans la liste

2. **Créer un site de test**:
   - [ ] Créer un nouveau portail web
   - [ ] Sélectionner "PHP 8.3" comme backend
   - [ ] Créer un fichier `<?php phpinfo(); ?>`
   - [ ] Accéder au site
   - [ ] Vérifier que PHP 8.3.8 s'affiche

---

## 🆘 Dépannage

### PHP 8.3 n'apparaît toujours pas après le correctif

**Solution 1: Redémarrage forcé de Web Station**
```bash
ssh -p 44 admin@192.168.1.47
sudo synopkg stop WebStation
sleep 5
sudo synopkg start WebStation
```

**Solution 2: Vérifier les emplacements**
```bash
# Vérifier tous les emplacements possibles
find /usr/syno/etc -name "*php83*" -o -name "*backend*php*"

# Copier manuellement si nécessaire
sudo cp /var/packages/php83/target/package/conf/backend.json \
       /usr/syno/etc/www/app.d/backend-php83.json
sudo chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
```

**Solution 3: Vérifier les logs**
```bash
# Logs nginx (Web Station)
tail -100 /var/log/nginx/error.log

# Logs PHP 8.3
tail -100 /var/log/php83-install.log
tail -50 /var/packages/php83/var/log/php-fpm.log
```

---

### Erreur "502 Bad Gateway" lors de l'accès au site

**Cause**: PHP-FPM ne répond pas

**Solution**:
```bash
# Vérifier que PHP-FPM tourne
ps aux | grep php-fpm

# Redémarrer PHP-FPM
sudo synoservicectl --restart pkgctl-php83

# Vérifier les logs
tail -50 /var/packages/php83/var/log/php-fpm.log
```

---

### Les extensions ne se chargent pas

**Vérification**:
```bash
# Lister les extensions chargées
/var/packages/php83/target/bin/php -m

# Vérifier le fichier php.ini
grep "^extension=" /var/packages/php83/target/conf/php.ini
```

---

## 📊 Différences Entre Versions

### Version Actuelle (Problématique)
```
/usr/syno/etc/www/app.d/php83.json  ❌
```

### Version Corrigée (Solution A - Correctif)
```
/usr/syno/etc/www/app.d/backend-php83.json  ✅
/usr/syno/etc/packages/WebStation/backends/backend-php83.json  ✅
```

### Version Corrigée (Solution B - SPK Rebuild)
Même résultat que Solution A, mais automatique lors de l'installation

---

## 📁 Fichiers Créés pour Vous

1. **PROBLEME_WEB_STATION.md** - Diagnostic détaillé
2. **fix-webstation.sh** - Script de correctif automatique
3. **SOLUTION_WEBSTATION.md** - Ce fichier (guide complet)

---

## 🎯 Recommandation

**Pour tester aujourd'hui**: Utilisez **Solution A** (correctif rapide)

**Pour la production**: Utilisez **Solution B** (reconstruire le SPK)

Cela vous permet de valider rapidement que la solution fonctionne, puis de l'intégrer de manière permanente une fois validé.

---

## 📞 Prochaines Étapes

1. **Choisir** une solution (A ou B)
2. **Appliquer** les modifications
3. **Tester** dans Web Station
4. **Valider** avec un site de test
5. **Créer** un site réel si les tests réussissent

---

**Créé le**: 2025-11-22
**Package**: php83_8.3.8-0009_geminilake.spk
**NAS**: ServeurNAS (192.168.1.47:44)

**Voulez-vous que je vous guide pour appliquer la solution maintenant ?**
