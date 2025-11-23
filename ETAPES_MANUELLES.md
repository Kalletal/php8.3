# 📋 Installation Manuelle PHP 8.3 - Étapes à Suivre

## ✅ Ce qui a déjà été fait
- Répertoire `/tmp/php83-install` créé sur le NAS

## 🚀 Étapes à Exécuter Maintenant

### Étape 1: Ouvrir un nouveau terminal Git Bash

Ouvrez un **nouveau** terminal Git Bash (séparé de celui de Claude Code)

---

### Étape 2: Transférer le SPK (Commande 1)

Copiez et collez cette commande :

```bash
cd /c/Users/gdalm/ProjetsSPK/php8.3
scp -P 44 dist/php83_8.3.8-0001_geminilake.spk gilles@192.168.1.47:/tmp/php83-install/
```

➡️ Entrez votre mot de passe quand demandé
➡️ Le transfert prend ~30 secondes (35 MB)

**Résultat attendu** :
```
php83_8.3.8-0001_geminilake.spk    100%   35MB   xxx.xKB/s   00:xx
```

---

### Étape 3: Transférer le script de test (Commande 2)

```bash
scp -P 44 test-nas-complete.sh gilles@192.168.1.47:/tmp/php83-install/
```

➡️ Entrez votre mot de passe quand demandé

---

### Étape 4: Vérifier l'état du NAS (Commande 3)

```bash
ssh -p 44 gilles@192.168.1.47 "chmod +x /tmp/php83-install/test-nas-complete.sh && ls -lh /tmp/php83-install/"
```

➡️ Entrez votre mot de passe

**Résultat attendu** : Liste des fichiers transférés

---

### Étape 5: Vérifier si PHP 8.3 est déjà installé (Commande 4)

```bash
ssh -p 44 gilles@192.168.1.47 "ls -la /var/packages/php83 2>/dev/null && echo 'PHP 8.3 DÉJÀ INSTALLÉ' || echo 'PHP 8.3 NON INSTALLÉ'"
```

➡️ Entrez votre mot de passe

**Si le résultat est "PHP 8.3 DÉJÀ INSTALLÉ"** :
   ⚠️ Vous DEVEZ le désinstaller d'abord via DSM :
   1. http://192.168.1.47:5000
   2. Centre de paquets → PHP 8.3 → Désinstaller
   3. Attendre la fin
   4. Revenir ici

**Si le résultat est "PHP 8.3 NON INSTALLÉ"** :
   ✅ Parfait, continuez

---

### Étape 6: Installer le package via DSM

1. **Ouvrez votre navigateur**
2. **Allez sur** : http://192.168.1.47:5000
3. **Centre de paquets** → **Installation manuelle** (bouton en haut à droite)
4. **Parcourir** → Naviguez vers :
   `/tmp/php83-install/php83_8.3.8-0001_geminilake.spk`

   💡 **Astuce** : Si vous ne trouvez pas /tmp, utilisez File Station pour y accéder

5. **Suivez l'assistant** :
   - Sélectionnez les extensions (recommandées : opcache, curl, openssl, mysqli, pdo_mysql, gd, mbstring, xml, dom, zip)
   - Suivant → Accepter → Appliquer

6. **Attendez** 1-2 minutes

7. **Vérifiez** que "PHP 8.3" est marqué comme installé

---

### Étape 7: Exécuter les tests complets (Commande 5)

```bash
ssh -p 44 gilles@192.168.1.47 "bash /tmp/php83-install/test-nas-complete.sh"
```

➡️ Entrez votre mot de passe

**Le script va tester** :
- ✓ Installation du package
- ✓ Binaires PHP
- ✓ Extensions chargées
- ✓ Service PHP-FPM
- ✓ **Intégration Web Station ⭐**

---

### Étape 8: Vérifier Web Station (CRITIQUE ⭐)

**Dans DSM** :
1. Ouvrir **Web Station**
2. Aller dans **"Paramètres PHP"** (ou "PHP Settings")
3. **Vérifier la liste des profils**

✅ **SUCCÈS si** : "PHP 8.3" apparaît dans la liste
❌ **Problème si** : PHP 8.3 n'apparaît pas

---

### Étape 9: Vérifier le fichier backend (Si problème)

```bash
ssh -p 44 gilles@192.168.1.47 "cat /usr/syno/etc/www/app.d/backend-php83.json"
```

➡️ Le fichier DOIT exister et contenir `"display_name": "PHP 8.3"`

---

### Étape 10: Créer un site de test

**Dans Web Station** :
1. Portail Web → Créer
2. Type : Hôte virtuel basé sur le port
3. Nom : test-php83
4. Port HTTP : 8088
5. Dossier racine : /volume1/web/test-php83
6. **Backend server : PHP 8.3** ⭐

**Créer le fichier de test** :

```bash
ssh -p 44 gilles@192.168.1.47 "
sudo mkdir -p /volume1/web/test-php83 && \
sudo tee /volume1/web/test-php83/index.php << 'EOF'
<?php
phpinfo();
?>
EOF
sudo chown -R http:http /volume1/web/test-php83
"
```

**Tester dans le navigateur** :
http://192.168.1.47:8088/

✅ **Vous devez voir** : PHP 8.3.8, FPM/FastCGI, liste des extensions

---

## 📊 Résumé de Validation

- [ ] SPK transféré (35 MB)
- [ ] Script de test transféré
- [ ] PHP 8.3 installé via DSM
- [ ] Tests complets exécutés
- [ ] **PHP 8.3 visible dans Web Station** ⭐ CRITIQUE
- [ ] Site de test créé
- [ ] Page phpinfo() affiche PHP 8.3.8

---

## 🆘 En Cas de Problème

### PHP 8.3 n'apparaît pas dans Web Station

```bash
# Vérifier le fichier backend
ssh -p 44 gilles@192.168.1.47 "ls -la /usr/syno/etc/www/app.d/backend-php83.json"

# Redémarrer Web Station
ssh -p 44 gilles@192.168.1.47 "sudo synopkg restart WebStation"

# Vérifier les logs
ssh -p 44 gilles@192.168.1.47 "tail -50 /var/log/php83-install.log"
```

---

## 🎯 Point de Validation Principal

**Le correctif fonctionne SI ET SEULEMENT SI** :

✅ PHP 8.3 apparaît dans Web Station → Paramètres PHP

C'est **LA** vérification critique qui prouve que le correctif Web Station est opérationnel !

---

**Une fois ces étapes terminées, dites-moi le résultat et je vous aiderai si besoin !**
