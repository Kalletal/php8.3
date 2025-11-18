#!/usr/bin/env bash
set -euo pipefail

# Create runtime directories
mkdir -p /var/packages/php83/var/run
mkdir -p /var/packages/php83/var/log
mkdir -p /var/packages/php83/var/sessions
mkdir -p /var/packages/php83/var/tmp

# Set proper permissions
chown -R http:http /var/packages/php83/var/sessions
chown -R http:http /var/packages/php83/var/tmp
chmod 1733 /var/packages/php83/var/sessions
chmod 1777 /var/packages/php83/var/tmp

# Apply extension configuration
/var/packages/php83/target/scripts/apply_extensions.sh

exit 0
