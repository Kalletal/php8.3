# 🔍 Diagnostic : Problème d'Intégration Web Station

## ❌ Problèmes Identifiés

### Problème 1: **Nom du fichier backend incorrect**

**Dans le postinst actuel** (ligne 37):
```bash
cp -f "${BACKEND_JSON}" /usr/syno/etc/www/app.d/php83.json
```

**Devrait être**:
```bash
cp -f "${BACKEND_JSON}" /usr/syno/etc/www/app.d/backend-php83.json
```

**Impact**: Web Station ne détecte pas PHP 8.3 car il cherche des fichiers nommés `backend-*.json`

---

### Problème 2: **Emplacement du fichier backend incomplet**

Le fichier backend est copié uniquement dans `/usr/syno/etc/www/app.d/` mais selon les versions de DSM, il devrait aussi être présent dans:
- `/usr/syno/etc/packages/WebStation/backends/`

**Impact**: Sur certaines versions de DSM, PHP 8.3 n'apparaît pas dans Web Station

---

### Problème 3: **Rechargement Web Station insuffisant**

La commande `synowebservice --reload-config` peut ne pas exister ou ne pas être suffisante pour recharger la configuration de Web Station.

**Impact**: Nécessite un redémarrage manuel de Web Station pour voir PHP 8.3

---

## ✅ Solutions

### Solution 1: Corriger le script postinst

Voici le script corrigé à intégrer dans `spk/php83/src/scripts/postinst`:

```bash
# Register with Web Station - IMPROVED VERSION
BACKEND_JSON="${SYNOPKG_PKGDEST}/package/conf/backend.json"
echo "[$(date)] Looking for backend.json at: ${BACKEND_JSON}"

if [ -f "${BACKEND_JSON}" ]; then
    echo "[$(date)] backend.json found, registering with Web Station"

    # Method 1: Copy to app.d (DSM 7.x)
    mkdir -p /usr/syno/etc/www/app.d
    cp -f "${BACKEND_JSON}" /usr/syno/etc/www/app.d/backend-php83.json
    chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
    echo "[$(date)] Copied to /usr/syno/etc/www/app.d/backend-php83.json"

    # Method 2: Copy to WebStation backends (some DSM versions)
    if [ -d "/usr/syno/etc/packages/WebStation" ]; then
        mkdir -p /usr/syno/etc/packages/WebStation/backends
        cp -f "${BACKEND_JSON}" /usr/syno/etc/packages/WebStation/backends/backend-php83.json
        chmod 644 /usr/syno/etc/packages/WebStation/backends/backend-php83.json
        echo "[$(date)] Copied to /usr/syno/etc/packages/WebStation/backends/backend-php83.json"
    fi

    # Try multiple methods to reload Web Station configuration
    if command -v synowebservice >/dev/null 2>&1; then
        echo "[$(date)] Reloading Web Station via synowebservice"
        synowebservice --reload-config 2>&1 || echo "[$(date)] synowebservice reload failed"
    fi

    # Alternative: Restart nginx if WebStation uses it
    if command -v synoservicectl >/dev/null 2>&1; then
        echo "[$(date)] Reloading nginx"
        synoservicectl --reload nginx 2>&1 || echo "[$(date)] nginx reload failed"
    fi

    # Suggest manual restart if needed
    echo "[$(date)] Web Station backend registered"
    echo "[$(date)] NOTE: If PHP 8.3 doesn't appear in Web Station, restart Web Station manually"

else
    echo "[$(date)] ERROR: backend.json not found at ${BACKEND_JSON}"
    echo "[$(date)] Contents of ${SYNOPKG_PKGDEST}/package/conf/:"
    ls -la "${SYNOPKG_PKGDEST}/package/conf/" || echo "Directory does not exist"
fi
```

### Solution 2: Corriger le script postuninst

```bash
# Unregister from Web Station - IMPROVED VERSION
echo "[$(date)] Unregistering from Web Station"

# Remove from app.d
rm -f /usr/syno/etc/www/app.d/backend-php83.json
echo "[$(date)] Removed /usr/syno/etc/www/app.d/backend-php83.json"

# Remove from WebStation backends
if [ -f "/usr/syno/etc/packages/WebStation/backends/backend-php83.json" ]; then
    rm -f /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    echo "[$(date)] Removed /usr/syno/etc/packages/WebStation/backends/backend-php83.json"
fi

# Reload Web Station
if command -v synowebservice >/dev/null 2>&1; then
    synowebservice --reload-config 2>&1 || true
fi

if command -v synoservicectl >/dev/null 2>&1; then
    synoservicectl --reload nginx 2>&1 || true
fi
```

---

## 🔧 Correctif Manuel pour le Package Actuel

Si vous avez déjà construit le SPK et ne voulez pas le reconstruire, voici un script de correctif à exécuter **sur le NAS après installation**:

```bash
#!/bin/bash
# Correctif Web Station pour PHP 8.3
# À exécuter sur le NAS après installation du package

echo "=== Correctif Web Station PHP 8.3 ==="

BACKEND_SRC="/var/packages/php83/target/package/conf/backend.json"

if [ ! -f "$BACKEND_SRC" ]; then
    echo "ERROR: backend.json introuvable"
    exit 1
fi

# Correction 1: Renommer le fichier dans app.d
if [ -f "/usr/syno/etc/www/app.d/php83.json" ]; then
    echo "Renommage php83.json -> backend-php83.json"
    sudo mv /usr/syno/etc/www/app.d/php83.json \
            /usr/syno/etc/www/app.d/backend-php83.json
fi

# Correction 2: Copier dans app.d si absent
if [ ! -f "/usr/syno/etc/www/app.d/backend-php83.json" ]; then
    echo "Copie vers /usr/syno/etc/www/app.d/backend-php83.json"
    sudo cp "$BACKEND_SRC" /usr/syno/etc/www/app.d/backend-php83.json
    sudo chmod 644 /usr/syno/etc/www/app.d/backend-php83.json
fi

# Correction 3: Copier dans WebStation backends
if [ -d "/usr/syno/etc/packages/WebStation" ]; then
    echo "Copie vers /usr/syno/etc/packages/WebStation/backends/"
    sudo mkdir -p /usr/syno/etc/packages/WebStation/backends
    sudo cp "$BACKEND_SRC" /usr/syno/etc/packages/WebStation/backends/backend-php83.json
    sudo chmod 644 /usr/syno/etc/packages/WebStation/backends/backend-php83.json
fi

# Correction 4: Recharger Web Station
echo "Rechargement de Web Station..."
sudo synoservicectl --reload nginx 2>/dev/null || true
sudo synopkg restart WebStation 2>/dev/null || true

echo ""
echo "✓ Correctif appliqué"
echo ""
echo "Vérifications:"
echo "1. Ouvrez Web Station"
echo "2. Allez dans 'Paramètres PHP' ou 'PHP Settings'"
echo "3. Vérifiez que 'PHP 8.3' apparaît dans la liste"
echo ""
echo "Si PHP 8.3 n'apparaît toujours pas:"
echo "  sudo synopkg stop WebStation"
echo "  sudo synopkg start WebStation"
```

---

## 📝 Checklist de Vérification Web Station

Après avoir appliqué le correctif, vérifiez:

### ✅ Fichiers backend présents

```bash
# Doit exister avec le nom backend-php83.json (pas php83.json)
ls -la /usr/syno/etc/www/app.d/backend-php83.json

# Peut exister selon la version de DSM
ls -la /usr/syno/etc/packages/WebStation/backends/backend-php83.json
```

### ✅ Contenu du fichier correct

```bash
cat /usr/syno/etc/www/app.d/backend-php83.json
```

Doit contenir:
```json
{
  "service": "php83",
  "display_name": "PHP 8.3",
  "type": "nginx_php",
  ...
}
```

### ✅ PHP-FPM accessible

```bash
# Vérifier que PHP-FPM écoute sur le port 9000
netstat -tlnp | grep 9000

# Ou tester la connexion
telnet 127.0.0.1 9000
```

### ✅ Web Station redémarré

```bash
sudo synopkg status WebStation
```

### ✅ PHP 8.3 visible dans Web Station

1. Ouvrir Web Station
2. Aller dans "Paramètres PHP" (ou "PHP Settings")
3. Vérifier que "PHP 8.3" apparaît dans la liste des profils

---

## 🔄 Reconstruction du Package avec le Correctif

Si vous voulez reconstruire le SPK avec les corrections:

1. **Éditer le fichier source**:
   ```
   spk/php83/src/scripts/postinst
   spk/php83/src/scripts/postuninst
   ```

2. **Appliquer les modifications** décrites dans "Solution 1" et "Solution 2" ci-dessus

3. **Reconstruire le SPK**:
   ```bash
   bash scripts/build-spk.sh
   ```

4. **Le nouveau SPK** sera dans `dist/` avec les corrections intégrées

---

## 📊 Comparaison Avant/Après

### Avant (problématique)
```bash
/usr/syno/etc/www/app.d/php83.json          # ❌ Nom incorrect
```

### Après (corrigé)
```bash
/usr/syno/etc/www/app.d/backend-php83.json                        # ✅
/usr/syno/etc/packages/WebStation/backends/backend-php83.json     # ✅ (si DSM le requiert)
```

---

## 🆘 Si le Problème Persiste

### Vérifier les logs Web Station

```bash
# Logs nginx (Web Station utilise nginx)
tail -100 /var/log/nginx/error.log

# Logs Web Station
tail -100 /var/log/synolog/synoscgi.log
```

### Vérifier la version de DSM

```bash
cat /etc.defaults/VERSION | grep productversion
```

Certaines versions de DSM peuvent avoir des emplacements différents pour les backends PHP.

### Forcer le rechargement complet

```bash
# Arrêter Web Station
sudo synopkg stop WebStation

# Vérifier qu'il n'y a plus de processus nginx
ps aux | grep nginx

# Redémarrer Web Station
sudo synopkg start WebStation
```

---

**Créé le**: 2025-11-22
**Pour**: Package PHP 8.3 (version 8.3.8-0009)
**NAS**: ServeurNAS (192.168.1.47)
