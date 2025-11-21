# Simplification du Package PHP 8.3

## Date
2025-11-21

## Problème
Le package causait une erreur "Échec d'installation du paquet" sur le NAS.

## Cause identifiée
Les modifications précédentes ajoutaient trop de complexité et tentaient de modifier des fichiers système critiques :

1. **INFO** : Ajout de `install_provide_packages="PHP"` qui créait un conflit avec d'autres packages PHP
2. **postinst** : Tentative de modification du fichier `/usr/syno/etc/packages/WebStation/PHPSettings.json`
3. Scripts trop complexes avec trop de gestion d'erreurs et de cas particuliers

## Solutions appliquées

### 1. Fichier INFO simplifié
**Avant** :
- Version: 8.3.8-0005
- Champs: install_provide_packages, dsmuidir, dsmappname, admin_url, install_wizard, etc.

**Après** :
- Version: 8.3.8-0007
- Champs essentiels uniquement: package, version, description, arch, os_min_ver, maintainer, displayname, startable, ctl_stop

### 2. Script postinst minimal
**Avant** :
- 188 lignes
- Modification de PHPSettings.json
- Configuration Web Station complexe
- Gestion des extensions via wizard

**Après** :
- 25 lignes
- Création de répertoires seulement
- Permissions de base
- Pas de modification de fichiers système

### 3. Script start-stop-status simplifié
**Avant** :
- Plus de 100 lignes
- Logging complexe
- Gestion du web server
- Multiples vérifications

**Après** :
- 55 lignes
- Fonctions basiques : start_daemon, stop_daemon, daemon_status
- Pas de logging complexe
- Gestion PHP-FPM uniquement

### 4. Configuration PHP-FPM inchangée
Le fichier `php-fpm.conf` reste simple avec :
- Listen sur 127.0.0.1:9000
- User/group http
- Paramètres PM basiques

## Structure du package final

```
php83_8.3.8-0001_geminilake.spk
├── INFO (minimal, 9 lignes)
├── PACKAGE_ICON.PNG
├── PACKAGE_ICON_256.PNG
├── scripts/
│   ├── postinst (minimal, 25 lignes)
│   ├── postuninst
│   ├── preinst
│   ├── preuninst
│   ├── start-stop-status (simplifié, 55 lignes)
│   └── service-setup
├── conf/
│   ├── privilege
│   └── resource.conf
├── WIZARD_UIFILES/
│   └── install_uifile
└── package.tgz
    ├── bin/ (php, php-cgi, phpdbg)
    ├── sbin/ (php-fpm)
    ├── lib/ (bibliothèques partagées)
    ├── conf/ (php.ini, php-fpm.conf)
    └── scripts/
```

## Résultat
- Package size: 36423680 bytes (35 MiB)
- MD5: 609f390fd17e429f837164add0c2ab0d
- SHA256: e401eb6a8e970af27662e0185b1f0eb67ee2165fe322696767e3fcd05b2529ce

## Prochaines étapes
1. Tester l'installation sur le NAS
2. Vérifier que PHP-FPM démarre correctement
3. Tester une page PHP simple
4. Si tout fonctionne, commiter les changements
