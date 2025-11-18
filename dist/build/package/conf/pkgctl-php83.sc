[php83-fpm]
title="PHP 8.3 FPM"
author="you"
capabilities=env,setenv,set-working-dir,process-control

[php83-fpm-prestart]
command=/var/packages/php83/target/scripts/pre-start.sh
timeout=30

[php83-fpm-start]
command=/var/packages/php83/target/bin/php-fpm
arguments=--fpm-config /var/packages/php83/target/conf/php-fpm.conf --php-ini /var/packages/php83/target/conf/php.ini
user=http
timeout=30

[php83-fpm-stop]
command=kill
timeout=30

[php83-fpm-status]
command=/var/packages/php83/target/scripts/check-status.sh
timeout=10
