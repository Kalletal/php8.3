#!/bin/bash
#
# Script pour enregistrer PHP 8.3 dans Web Station via l'API Synology
#

# Configuration
PHP_NAME="PHP 8.3"
PHP_VERSION="8.3.8"
PHP_PATH="/var/packages/php83/target/package/bin/php"
PHP_FPM_PATH="/var/packages/php83/target/package/sbin/php-fpm"
PHP_FPM_ADDR="127.0.0.1:9000"

echo "Enregistrement de PHP 8.3 dans Web Station..."

# Vérifier que Web Station est installé
if [ ! -d "/var/packages/WebStation" ]; then
    echo "Erreur: Web Station n'est pas installé"
    exit 1
fi

# Créer le fichier de configuration du profil PHP
PROFILE_DIR="/usr/syno/etc/packages/WebStation/PHPSettings"
mkdir -p "$PROFILE_DIR"

cat > "$PROFILE_DIR/php83.conf" << 'EOF'
[php83]
profile_name=PHP 8.3
profile_desc=PHP 8.3.8 with comprehensive extension support
backend=php83-fpm
fpm_addr=127.0.0.1:9000
php_path=/var/packages/php83/target/package/bin/php
open_basedir=/home:/tmp:/var/services/web:/var/services/homes
extensions=opcache,curl,mysqli,pdo_mysql,pdo_sqlite,sqlite3,gd,openssl,xml,dom,simplexml
memory_limit=256M
max_execution_time=300
upload_max_filesize=100M
post_max_size=100M
EOF

chmod 644 "$PROFILE_DIR/php83.conf"

echo "Profil PHP 8.3 créé dans $PROFILE_DIR/php83.conf"
echo ""
echo "Redémarrage de Web Station..."
systemctl restart pkgctl-WebStation

echo ""
echo "PHP 8.3 devrait maintenant apparaître dans Web Station"
echo "Ouvrez DSM → Web Station → Script Language Settings → PHP"
