#!/bin/bash
# Configuration sudo pour synopkg - À exécuter UNE SEULE FOIS

echo "════════════════════════════════════════════════════════════════"
echo "Configuration sudo pour synopkg"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Ce script va configurer sudo pour permettre l'exécution de synopkg"
echo "sans mot de passe pour l'utilisateur gilles."
echo ""
echo "Vous devrez entrer votre mot de passe sudo UNE FOIS."
echo ""

# Créer le fichier de configuration sudoers
SUDOERS_CONTENT="# Allow gilles to run synopkg without password
gilles ALL=(ALL) NOPASSWD: /usr/syno/bin/synopkg
gilles ALL=(ALL) NOPASSWD: /usr/syno/sbin/synoservicectl"

# Créer un fichier temporaire
TEMP_FILE="/tmp/sudoers-synopkg-$$"
echo "$SUDOERS_CONTENT" > "$TEMP_FILE"

# Vérifier la syntaxe avec visudo
echo "Vérification de la syntaxe..."
if sudo visudo -c -f "$TEMP_FILE" > /dev/null 2>&1; then
    echo "✓ Syntaxe correcte"

    # Copier dans /etc/sudoers.d/
    echo "Installation de la configuration..."
    sudo cp "$TEMP_FILE" /etc/sudoers.d/synopkg
    sudo chmod 0440 /etc/sudoers.d/synopkg

    # Nettoyer
    rm -f "$TEMP_FILE"

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "✓ Configuration terminée !"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Vous pouvez maintenant exécuter synopkg sans mot de passe."
    echo ""
    echo "Test :"
    sudo -n synopkg list 2>&1 | head -3

else
    echo "✗ Erreur de syntaxe dans le fichier sudoers"
    rm -f "$TEMP_FILE"
    exit 1
fi
