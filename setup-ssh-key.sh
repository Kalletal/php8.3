#!/bin/bash
# Configuration d'une clé SSH pour accès automatique au NAS

NAS_HOST="192.168.1.47"
NAS_PORT="44"
NAS_USER="gilles"

echo "═══════════════════════════════════════════════════════════════"
echo "Configuration d'une Clé SSH pour le NAS"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Cette configuration permettra de se connecter au NAS sans mot de passe."
echo "C'est plus sécurisé et plus pratique."
echo ""

# Vérifier si une clé existe déjà
if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "✓ Une clé SSH existe déjà: ~/.ssh/id_rsa.pub"
else
    echo "➤ Génération d'une nouvelle clé SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "claude-code-nas-access"
    echo "✓ Clé SSH générée"
fi

echo ""
echo "➤ Copie de la clé sur le NAS..."
echo "   (Vous devrez entrer votre mot de passe UNE DERNIÈRE FOIS)"
echo ""

# Copier la clé sur le NAS
ssh-copy-id -p $NAS_PORT $NAS_USER@$NAS_HOST

if [ $? -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "✓ Configuration terminée !"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Test de connexion sans mot de passe..."
    ssh -p $NAS_PORT $NAS_USER@$NAS_HOST "echo '✓ Connexion SSH sans mot de passe fonctionne !'"
    echo ""
    echo "Vous pouvez maintenant vous connecter au NAS sans entrer de mot de passe."
else
    echo ""
    echo "✗ Erreur lors de la copie de la clé"
    echo ""
    echo "Solution alternative : Copie manuelle de la clé"
    echo ""
    echo "1. Affichez votre clé publique :"
    echo "   cat ~/.ssh/id_rsa.pub"
    echo ""
    echo "2. Connectez-vous au NAS :"
    echo "   ssh -p $NAS_PORT $NAS_USER@$NAS_HOST"
    echo ""
    echo "3. Sur le NAS, exécutez :"
    echo "   mkdir -p ~/.ssh"
    echo "   echo 'COLLEZ_ICI_VOTRE_CLE_PUBLIQUE' >> ~/.ssh/authorized_keys"
    echo "   chmod 700 ~/.ssh"
    echo "   chmod 600 ~/.ssh/authorized_keys"
fi
