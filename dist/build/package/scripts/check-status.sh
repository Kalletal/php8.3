#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/var/packages/php83/var/run/php-fpm.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "PHP-FPM is running (PID: $PID)"
        exit 0
    else
        echo "PID file exists but process is not running"
        exit 1
    fi
else
    echo "PHP-FPM is not running"
    exit 1
fi
