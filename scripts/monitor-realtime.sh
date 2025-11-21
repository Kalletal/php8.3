#!/usr/bin/env bash
# Real-time PHP compilation monitor

LOG_FILE="/tmp/php-build-nographics.log"
PHP_PID=1575522

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear

echo -e "${GREEN}======================================================"
echo "  PHP 8.3.8 COMPILATION - MONITORING EN TEMPS RÉEL"
echo -e "======================================================${NC}"
echo ""

# Check if build is running
if ps -p $PHP_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Processus de compilation ACTIF${NC} (PID: $PHP_PID)"
else
    echo -e "${YELLOW}⊘ Processus terminé ou arrêté${NC}"
fi

echo ""
echo -e "${BLUE}Progression:${NC}"
echo "----------------------------------------"

# Count completed phases
DEPS_DONE=$(grep -c "Nothing to be done for 'default'" "$LOG_FILE" 2>/dev/null || echo "0")
INSTALLING=$(grep -c "===>  Installing for" "$LOG_FILE" 2>/dev/null || echo "0")
COMPILING=$(grep -c "===>  Compiling for" "$LOG_FILE" 2>/dev/null || echo "0")
CONFIGURING=$(grep -c "===>  Configuring for" "$LOG_FILE" 2>/dev/null || echo "0")

echo "Dépendances déjà compilées: $DEPS_DONE"
echo "Packages en configuration: $CONFIGURING"
echo "Packages en compilation: $COMPILING"
echo "Packages en installation: $INSTALLING"

echo ""
echo -e "${BLUE}Package actuel:${NC}"
echo "----------------------------------------"

# Show current package being built
CURRENT=$(grep "===>.*for" "$LOG_FILE" | tail -3 | sed 's/^.*for //')
echo "$CURRENT"

echo ""
echo -e "${BLUE}Dernière activité (20 dernières lignes):${NC}"
echo "----------------------------------------"
tail -20 "$LOG_FILE" | grep -v "^/" | grep -v "^CC=" | head -20

echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  watch -n 5 $0           # Rafraîchir toutes les 5 secondes"
echo "  tail -f $LOG_FILE       # Suivre le log en direct"
echo "  ps -p $PHP_PID          # Vérifier si le processus tourne"
echo "  kill $PHP_PID           # Arrêter la compilation"
echo ""

# Show estimated time
if [ -f "$LOG_FILE" ]; then
    SIZE=$(wc -l < "$LOG_FILE")
    echo -e "${BLUE}Lignes de log:${NC} $SIZE"

    # Simple estimation based on OpenSSL being the longest
    if grep -q "Installing for openssl3" "$LOG_FILE"; then
        echo -e "${GREEN}OpenSSL 3.5.4 terminé !${NC} (~40% du temps total)"
    elif grep -q "Compiling for openssl3" "$LOG_FILE"; then
        echo -e "${YELLOW}Compilation d'OpenSSL 3.5.4 en cours...${NC} (~30 min restantes pour OpenSSL)"
    fi
fi

echo ""
echo -e "${GREEN}======================================================"
echo "  Appuyez sur Ctrl+C pour quitter le monitoring"
echo -e "======================================================${NC}"
