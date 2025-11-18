#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_NAME="php83"
PHP_SOURCE_VERSION="8.3.8"
ARCH_RAW="${ARCH:-geminilake-7.2}"
# Allow overriding DSM target identifier directly
DSM_TARGET="${DSM_TARGET:-}"
INFO_VERSION=$(grep '^version=' "$ROOT_DIR/spk/php83/INFO" | cut -d'"' -f2)
DIST_DIR="$ROOT_DIR/dist"
TMP_DIR="$(mktemp -d)"
PACKAGE_STAGE="$TMP_DIR/package"
SPK_STAGE="$TMP_DIR/spk"

if [[ "$ARCH_RAW" == *-* ]]; then
    TARGET_ARCH="${ARCH_RAW%%-*}"
    TC_VERSION_RAW="${ARCH_RAW#*-}"
else
    TARGET_ARCH="$ARCH_RAW"
    TC_VERSION_RAW=""
fi

if [[ -z "${DSM_TARGET}" ]]; then
    if [[ -n "$TC_VERSION_RAW" ]]; then
        IFS='.' read -r major minor <<< "$TC_VERSION_RAW"
        major=${major:-0}
        minor=${minor:-0}
        major=$((10#$major))
        minor=$((10#$minor))
        if (( major > 7 )) || (( major == 7 && minor >= 2 )); then
            DSM_TARGET="dsm72"
        elif (( major >= 7 )); then
            DSM_TARGET="dsm7"
        elif (( major >= 6 )); then
            DSM_TARGET="dsm6"
        elif (( major >= 3 )); then
            DSM_TARGET="all"
        else
            DSM_TARGET="srm"
        fi
    else
        DSM_TARGET="dsm72"
    fi
fi

mkdir -p "$DIST_DIR" \
         "$PACKAGE_STAGE"/bin "$PACKAGE_STAGE"/conf "$PACKAGE_STAGE"/ui "$PACKAGE_STAGE"/source \
         "$SPK_STAGE/scripts" "$SPK_STAGE/conf" "$SPK_STAGE/WIZARD_UIFILES"

cp "$ROOT_DIR/spk/php83/src/scripts/apply_extensions.sh" "$PACKAGE_STAGE/bin/"
cp "$ROOT_DIR/spk/php83/src/scripts/extension_config.sh" "$PACKAGE_STAGE/bin/"
cp "$ROOT_DIR/spk/php83/src/scripts/extension_api.cgi" "$PACKAGE_STAGE/bin/"
cp "$ROOT_DIR/spk/php83/files/bin/log-extension-event.sh" "$PACKAGE_STAGE/bin/"
cp "$ROOT_DIR/spk/php83/files/conf/extension_selection.json.sample" "$PACKAGE_STAGE/conf/"
cp "$ROOT_DIR/spk/php83/files/conf/extension_options.json" "$PACKAGE_STAGE/conf/"
cp "$ROOT_DIR/spk/php83/files/php-src/php-${PHP_SOURCE_VERSION}.tar.gz" "$PACKAGE_STAGE/source/"
cp "$ROOT_DIR/spk/php83/src/config-panel/extension-panel.js" "$PACKAGE_STAGE/ui/"

chmod +x "$PACKAGE_STAGE/bin"/*.sh "$PACKAGE_STAGE/bin"/extension_api.cgi

( cd "$PACKAGE_STAGE" && tar --format=ustar -czf "$SPK_STAGE/package.tgz" . )

sed "s/^arch=\".*\"/arch=\"${TARGET_ARCH}\"/" "$ROOT_DIR/spk/php83/INFO" > "$SPK_STAGE/INFO"
CHECKSUM=$(md5sum "$SPK_STAGE/package.tgz" | awk '{print $1}')
if grep -q '^checksum=' "$SPK_STAGE/INFO"; then
    sed -i "s/^checksum=.*/checksum=\"$CHECKSUM\"/" "$SPK_STAGE/INFO"
else
    printf 'checksum="%s"\n' "$CHECKSUM" >> "$SPK_STAGE/INFO"
fi
cp "$ROOT_DIR/spk/php83/icons/PACKAGE_ICON.PNG" "$SPK_STAGE/PACKAGE_ICON.PNG"
cp "$ROOT_DIR/spk/php83/icons/PACKAGE_ICON_256.PNG" "$SPK_STAGE/PACKAGE_ICON_256.PNG"
cp "$ROOT_DIR/spk/php83/conf/privilege" "$SPK_STAGE/conf/"
cp "$ROOT_DIR/spk/php83/conf/resource.conf" "$SPK_STAGE/conf/"
cp "$ROOT_DIR/spk/php83/src/install-wizard/"*.json "$SPK_STAGE/WIZARD_UIFILES/" || true
cp "$ROOT_DIR/spk/php83/src/install-wizard/extension-selection"*.js "$SPK_STAGE/WIZARD_UIFILES/" || true

cp "$ROOT_DIR/spk/php83/src/scripts/preinst" "$SPK_STAGE/scripts/"
cp "$ROOT_DIR/spk/php83/src/scripts/postinst" "$SPK_STAGE/scripts/"
cp "$ROOT_DIR/spk/php83/src/scripts/service-setup" "$SPK_STAGE/scripts/"
cp "$ROOT_DIR/spk/php83/src/scripts/start-stop-status" "$SPK_STAGE/scripts/"
chmod +x "$SPK_STAGE/scripts/"*

if [[ -n "$TC_VERSION_RAW" ]]; then
    OUTPUT="$DIST_DIR/${PKG_NAME}_${TARGET_ARCH}-${DSM_TARGET}_${INFO_VERSION}.spk"
else
    OUTPUT="$DIST_DIR/${PKG_NAME}_${TARGET_ARCH}-${DSM_TARGET}_${INFO_VERSION}.spk"
fi
( cd "$SPK_STAGE" && tar --format=ustar -cf "$OUTPUT" . )

rm -rf "$TMP_DIR"
echo "SPK created at $OUTPUT"
