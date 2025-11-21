# Guide de débogage - Installation SPK sur Synology

## Récupérer les logs d'erreur

### Méthode 1 : Via SSH (Recommandé)

1. **Activer SSH sur votre Synology** :
   - Panneau de configuration → Terminal & SNMP
   - Cocher "Activer le service SSH"

2. **Se connecter en SSH** :
   ```bash
   ssh admin@<IP_SYNOLOGY>
   ```

3. **Consulter les logs du Gestionnaire de paquets** :
   ```bash
   # Log principal du Package Center
   sudo tail -100 /var/log/packages/synopkg.log

   # Log système
   sudo tail -100 /var/log/messages | grep -i package

   # Log d'installation
   sudo tail -100 /var/log/synopkg.log
   ```

4. **Tenter l'installation manuellement pour voir l'erreur** :
   ```bash
   # Copier le SPK vers /tmp
   sudo synopkgctl install /chemin/vers/php83_8.3.8-0001_geminilake.spk
   ```

### Méthode 2 : Via Centre de journaux DSM

1. Ouvrir **Centre de journaux** dans DSM
2. Sélectionner **Système** dans le menu de gauche
3. Filtrer par "package" ou "synopkg"
4. Noter le message d'erreur exact

### Méthode 3 : Télécharger les logs

1. Centre de journaux → Exporter
2. Sélectionner les logs système
3. M'envoyer le fichier

## Informations système à vérifier

### Version de DSM
Panneau de configuration → Info → Version de DSM
Format attendu : DSM 7.x-xxxxx

### Architecture
```bash
ssh admin@<IP_SYNOLOGY>
uname -m
# Devrait afficher: x86_64
```

### Vérifier les packages installés
```bash
synopkg list
```

## Tests de validation du SPK

### Test 1 : Vérifier le fichier SPK sur le NAS
```bash
# Sur le Synology après avoir copié le SPK
file php83_8.3.8-0001_geminilake.spk
# Devrait afficher: POSIX tar archive

tar -tzf php83_8.3.8-0001_geminilake.spk | head -20
# Devrait lister: package.tgz, INFO, scripts/, conf/, etc.
```

### Test 2 : Vérifier le contenu INFO
```bash
tar -xOf php83_8.3.8-0001_geminilake.spk INFO
# Devrait afficher le contenu du fichier INFO
```

### Test 3 : Vérifier privilege
```bash
tar -xOf php83_8.3.8-0001_geminilake.spk INFO | grep os_min_ver
# Devrait afficher: os_min_ver="7.0-40000"
```

## Erreurs courantes

### "Format de fichier non valide"
Causes possibles :
1. Architecture incompatible (geminilake vs autre)
2. Version DSM trop ancienne (< os_min_ver)
3. Fichier INFO malformé
4. Champ non standard dans INFO
5. JSON invalide dans conf/privilege
6. Ordre des fichiers dans le tar

### "Version incompatible"
- Vérifier que DSM >= 7.0-40000
- Le numéro après le tiret est le build number

### "Échec de l'installation"
- Consulter `/var/log/packages/synopkg.log`
- Vérifier les permissions des scripts (doivent être 755)

## Package actuel

**Fichier** : `dist/php83_8.3.8-0001_geminilake.spk`
**Architecture** : geminilake (DS920+, DS1520+, DS1621+, etc.)
**Version DSM minimum** : 7.0-40000
**Taille** : ~35 MB

**Contenu vérifié** :
- ✅ Fichier INFO avec tous les champs obligatoires
- ✅ conf/privilege au format JSON valide
- ✅ Scripts d'installation avec permissions correctes (755)
- ✅ Icônes PACKAGE_ICON*.PNG
- ✅ package.tgz contenant les binaires PHP
- ✅ WIZARD_UIFILES pour l'assistant d'installation

## Prochaines étapes

1. **Récupérer les logs** avec l'une des méthodes ci-dessus
2. **Noter le message d'erreur exact**
3. **Vérifier la version DSM** et l'architecture
4. **Me transmettre ces informations** pour diagnostic approfondi
