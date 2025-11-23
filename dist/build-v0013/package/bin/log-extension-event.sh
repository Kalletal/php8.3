#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/php83-extension-selection.log"
mkdir -p "$(dirname "$LOG_FILE")"

ts=$(date --iso-8601=seconds)
echo "[$ts] $*" >> "$LOG_FILE"
