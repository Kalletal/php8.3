#!/usr/bin/env bash
# Script to copy compiled PHP binaries and extensions to SPK package structure
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source and destination paths
PHP_INSTALL_DIR="/home/gilles/spksrc/cross/php83/work-geminilake-7.2/install/usr/local/php"
SPK_TARGET_DIR="/home/gilles/ProjetSPK/php8.3/spk/php83/files/php"

echo -e "${GREEN}=== Copying PHP 8.3.8 binaries and extensions ===${NC}"

# Create target directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p "$SPK_TARGET_DIR/bin"
mkdir -p "$SPK_TARGET_DIR/sbin"
mkdir -p "$SPK_TARGET_DIR/lib/php/extensions/no-debug-non-zts-20230831"
mkdir -p "$SPK_TARGET_DIR/etc"
mkdir -p "$SPK_TARGET_DIR/etc/conf.d"

# Copy PHP binaries
echo -e "${YELLOW}Copying PHP binaries...${NC}"
cp -v "$PHP_INSTALL_DIR/bin/php" "$SPK_TARGET_DIR/bin/"
cp -v "$PHP_INSTALL_DIR/bin/php-cgi" "$SPK_TARGET_DIR/bin/"
cp -v "$PHP_INSTALL_DIR/bin/phpdbg" "$SPK_TARGET_DIR/bin/"
cp -v "$PHP_INSTALL_DIR/sbin/php-fpm" "$SPK_TARGET_DIR/sbin/"

# Make binaries executable
chmod +x "$SPK_TARGET_DIR/bin/"*
chmod +x "$SPK_TARGET_DIR/sbin/"*

# Copy all extension modules
echo -e "${YELLOW}Copying extension modules...${NC}"
cp -v "$PHP_INSTALL_DIR/lib/php/extensions/no-debug-non-zts-20230831/"*.so \
   "$SPK_TARGET_DIR/lib/php/extensions/no-debug-non-zts-20230831/"

# Count extensions
EXT_COUNT=$(ls -1 "$SPK_TARGET_DIR/lib/php/extensions/no-debug-non-zts-20230831/"*.so 2>/dev/null | wc -l)
echo -e "${GREEN}Copied $EXT_COUNT extension modules${NC}"

# List all copied extensions
echo -e "${YELLOW}Extension list:${NC}"
ls -1 "$SPK_TARGET_DIR/lib/php/extensions/no-debug-non-zts-20230831/"*.so | \
    sed 's/.*\///' | sed 's/\.so$//' | sort | column -c 80

# Copy required shared libraries (dependencies)
echo -e "${YELLOW}Copying shared library dependencies...${NC}"
mkdir -p "$SPK_TARGET_DIR/lib"

# Function to copy library if it exists
copy_lib() {
    local lib_name="$1"
    local search_paths=(
        "/home/gilles/spksrc/cross/*/work-geminilake-7.2/install/usr/local/*/lib"
        "/home/gilles/spksrc/toolchain/syno-geminilake-7.2/work/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib"
    )

    for search_path in "${search_paths[@]}"; do
        local found=$(find $search_path -name "$lib_name*" -type f 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            echo "  Copying $lib_name from $(dirname $found)"
            cp -v "$found" "$SPK_TARGET_DIR/lib/" 2>/dev/null || true
            return 0
        fi
    done
    echo -e "  ${YELLOW}Warning: $lib_name not found${NC}"
    return 1
}

# Copy essential shared libraries for PHP extensions
copy_lib "libcurl.so*"
copy_lib "libssl.so*"
copy_lib "libcrypto.so*"
copy_lib "libxml2.so*"
copy_lib "libz.so*"
copy_lib "libpng16.so*"
copy_lib "libjpeg.so*"
copy_lib "libfreetype.so*"
copy_lib "libwebp.so*"
copy_lib "libonig.so*"
copy_lib "libzip.so*"
copy_lib "libsqlite3.so*"
copy_lib "libicuuc.so*"
copy_lib "libicuio.so*"
copy_lib "libicui18n.so*"
copy_lib "libicudata.so*"

# Get PHP version info
echo -e "${YELLOW}Verifying PHP version...${NC}"
if [ -x "$SPK_TARGET_DIR/bin/php" ]; then
    "$SPK_TARGET_DIR/bin/php" -v || echo -e "${RED}Warning: PHP binary test failed${NC}"
fi

# Generate file size summary
echo -e "${GREEN}=== Size Summary ===${NC}"
du -sh "$SPK_TARGET_DIR/bin"
du -sh "$SPK_TARGET_DIR/sbin"
du -sh "$SPK_TARGET_DIR/lib"
echo -e "${GREEN}Total package size:${NC}"
du -sh "$SPK_TARGET_DIR"

echo -e "${GREEN}=== Copy complete ===${NC}"
echo "PHP binaries location: $SPK_TARGET_DIR"
echo "Ready for SPK packaging"
