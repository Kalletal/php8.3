#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://nas:5001/webapi/php83/extensions"
COOKIE_JAR=$(mktemp)

# Authenticate via DSM session env variables or pre-generated cookie (placeholder)
# curl -c "$COOKIE_JAR" ... login request goes here.

curl -sk -b "$COOKIE_JAR" "$API_BASE/options"
curl -sk -b "$COOKIE_JAR" "$API_BASE/profile"
curl -sk -b "$COOKIE_JAR" -X PATCH -H 'Content-Type: application/json' \
  -d '{"operations":[{"id":"curl","targetState":"enable"}]}' "$API_BASE/apply"
