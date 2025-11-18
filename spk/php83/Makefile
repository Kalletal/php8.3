SPK_NAME = php83
SPK_VERS = 8.3.0
SPK_REV  = 1
SPK_ICON = src/install-wizard/icon.png
DSM_TARGET = geminilake
PHP_VERSION = 8.3.8
PHP_SRC_ARCHIVE = files/php-src/php-$(PHP_VERSION).tar.gz
PHP_SOURCE_DST = /var/packages/php83/source

WIZARD_UIFILES = \
	src/install-wizard/extension-selection.json \
	src/install-wizard/extension-selection.js

# EXTENSION_OPTIONS encodes metadata consumed by the wizard + DSM panel.
# Format: name|category|default|dependencies|conflicts|footprintMB|restart
EXTENSION_OPTIONS = \
	curl|networking|1|openssl||5|php-fpm \
	openssl|security|1|||3|php-fpm \
	pdo_mysql|database|0|pdo|mysqli|7|php-fpm \
	mysqli|database|0|||6|php-fpm \
	intl|localization|0|||12|both \
	gd|graphics|0|libjpeg,libpng|||php-fpm

INSTALLER_DEFAULT_CONF = /var/packages/php83/conf/extension_selection.json

.PHONY: custom_install
custom_install:
	install -m 644 files/conf/extension_selection.json.sample "$(STAGING_DIR)$(INSTALLER_DEFAULT_CONF)"
	install -d "$(STAGING_DIR)$(PHP_SOURCE_DST)"
	install -m 644 "$(PHP_SRC_ARCHIVE)" "$(STAGING_DIR)$(PHP_SOURCE_DST)/php-$(PHP_VERSION).tar.gz"
