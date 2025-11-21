#!/usr/bin/env bash
# Extract compiled PHP binaries from spksrc build and integrate into SPK package

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SPKSRC_DIR="$HOME/spksrc"
PHP_WORK_DIR="$SPKSRC_DIR/cross/php83/work-geminilake-7.2"
SPK_FILES_DIR="$HOME/ProjetSPK/php8.3/spk/php83/files"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  PHP 8.3.8 Binary Extraction Tool${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Step 1: Verify compilation completed successfully
echo -e "${BLUE}[1/5]${NC} Verifying compilation status..."

if [ ! -d "$PHP_WORK_DIR" ]; then
    echo -e "${RED}ERROR: PHP work directory not found!${NC}"
    echo "Expected: $PHP_WORK_DIR"
    echo "Did the compilation complete?"
    exit 1
fi

# Check for PHP binary
PHP_BINARY="$PHP_WORK_DIR/install/usr/local/php/bin/php"
if [ ! -f "$PHP_BINARY" ]; then
    echo -e "${RED}ERROR: PHP binary not found!${NC}"
    echo "Expected: $PHP_BINARY"
    echo "Compilation may not have completed successfully."
    exit 1
fi

echo -e "${GREEN}✓ PHP binary found${NC}"

# Verify PHP version
PHP_VERSION=$("$PHP_BINARY" -v | head -1 || echo "Unknown")
echo "  Version: $PHP_VERSION"

# Step 2: Check for PHP-FPM
echo ""
echo -e "${BLUE}[2/5]${NC} Checking for PHP-FPM..."

PHP_FPM_BINARY="$PHP_WORK_DIR/install/usr/local/php/sbin/php-fpm"
if [ ! -f "$PHP_FPM_BINARY" ]; then
    echo -e "${YELLOW}WARNING: php-fpm binary not found at $PHP_FPM_BINARY${NC}"
else
    echo -e "${GREEN}✓ php-fpm found${NC}"
fi

# Step 3: List all compiled binaries and libraries
echo ""
echo -e "${BLUE}[3/5]${NC} Identifying compiled files..."

INSTALL_DIR="$PHP_WORK_DIR/install/usr/local"

echo ""
echo "Binaries:"
find "$INSTALL_DIR/php/bin" -type f -executable 2>/dev/null | while read -r file; do
    SIZE=$(du -h "$file" | cut -f1)
    echo "  - $(basename "$file") ($SIZE)"
done

echo ""
echo "PHP-FPM:"
find "$INSTALL_DIR/php/sbin" -type f -executable 2>/dev/null | while read -r file; do
    SIZE=$(du -h "$file" | cut -f1)
    echo "  - $(basename "$file") ($SIZE)"
done

echo ""
echo "Extensions (.so files):"
EXT_COUNT=$(find "$INSTALL_DIR/php/lib/php/extensions" -name "*.so" 2>/dev/null | wc -l || echo "0")
echo "  Found $EXT_COUNT extension files"

echo ""
echo "Shared libraries:"
LIB_COUNT=$(find "$INSTALL_DIR" -name "*.so*" -type f 2>/dev/null | wc -l || echo "0")
echo "  Found $LIB_COUNT shared library files"

# Step 4: Create target directory structure
echo ""
echo -e "${BLUE}[4/5]${NC} Creating target directory structure..."

mkdir -p "$SPK_FILES_DIR/bin"
mkdir -p "$SPK_FILES_DIR/sbin"
mkdir -p "$SPK_FILES_DIR/lib/php/extensions"
mkdir -p "$SPK_FILES_DIR/lib/dependencies"
mkdir -p "$SPK_FILES_DIR/include"

echo -e "${GREEN}✓ Directories created${NC}"

# Step 5: Copy binaries and libraries
echo ""
echo -e "${BLUE}[5/5]${NC} Copying compiled files..."

# Copy PHP CLI binary
echo "  Copying PHP CLI..."
if [ -f "$INSTALL_DIR/php/bin/php" ]; then
    cp "$INSTALL_DIR/php/bin/php" "$SPK_FILES_DIR/bin/"
    echo -e "    ${GREEN}✓ php${NC}"
fi

# Copy other PHP binaries (if any)
for binary in phpize php-config; do
    if [ -f "$INSTALL_DIR/php/bin/$binary" ]; then
        cp "$INSTALL_DIR/php/bin/$binary" "$SPK_FILES_DIR/bin/"
        echo -e "    ${GREEN}✓ $binary${NC}"
    fi
done

# Copy PHP-FPM
echo "  Copying PHP-FPM..."
if [ -f "$INSTALL_DIR/php/sbin/php-fpm" ]; then
    cp "$INSTALL_DIR/php/sbin/php-fpm" "$SPK_FILES_DIR/sbin/"
    echo -e "    ${GREEN}✓ php-fpm${NC}"
fi

# Copy PHP extensions
echo "  Copying PHP extensions..."
if [ -d "$INSTALL_DIR/php/lib/php/extensions" ]; then
    cp -r "$INSTALL_DIR/php/lib/php/extensions"/* "$SPK_FILES_DIR/lib/php/extensions/" 2>/dev/null || true
    EXT_COPIED=$(find "$SPK_FILES_DIR/lib/php/extensions" -name "*.so" | wc -l)
    echo -e "    ${GREEN}✓ $EXT_COPIED extensions copied${NC}"
fi

# Copy shared libraries from dependencies
echo "  Copying dependency libraries..."

# Function to copy a library and its dependencies
copy_lib_and_deps() {
    local lib_path=$1
    local lib_name=$(basename "$lib_path")

    if [ -f "$lib_path" ]; then
        cp "$lib_path" "$SPK_FILES_DIR/lib/dependencies/"

        # Also copy symlinks if they exist
        local lib_dir=$(dirname "$lib_path")
        local lib_base=$(echo "$lib_name" | sed 's/\.[0-9].*$//')
        find "$lib_dir" -name "${lib_base}*.so*" -type l -exec cp -P {} "$SPK_FILES_DIR/lib/dependencies/" \; 2>/dev/null || true
    fi
}

# Copy critical libraries (OpenSSL, libxml2, curl, etc.)
for dep in openssl3 libxml2 curl zlib libzip sqlite libicu; do
    DEP_LIB_DIR="$INSTALL_DIR/$dep/lib"
    if [ -d "$DEP_LIB_DIR" ]; then
        echo "    Copying $dep libraries..."
        find "$DEP_LIB_DIR" -name "*.so*" -type f -exec cp {} "$SPK_FILES_DIR/lib/dependencies/" \; 2>/dev/null || true
    fi
done

LIB_COPIED=$(find "$SPK_FILES_DIR/lib/dependencies" -name "*.so*" | wc -l)
echo -e "    ${GREEN}✓ $LIB_COPIED dependency libraries copied${NC}"

# Copy include files (needed for php-config)
echo "  Copying PHP headers..."
if [ -d "$INSTALL_DIR/php/include" ]; then
    cp -r "$INSTALL_DIR/php/include"/* "$SPK_FILES_DIR/include/" 2>/dev/null || true
    echo -e "    ${GREEN}✓ Headers copied${NC}"
fi

# Step 6: Summary
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Extraction Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh "$SPK_FILES_DIR" | cut -f1)
echo "Total size: $TOTAL_SIZE"
echo ""

echo "Files extracted to:"
echo "  $SPK_FILES_DIR"
echo ""

echo "Next steps:"
echo "  1. Run: $HOME/ProjetSPK/php8.3/scripts/build-spk.sh"
echo "  2. Test the generated SPK package"
echo ""

# Verify binaries are executable
echo "Verifying binaries..."
for binary in "$SPK_FILES_DIR/bin/php" "$SPK_FILES_DIR/sbin/php-fpm"; do
    if [ -f "$binary" ]; then
        chmod +x "$binary"
        if "$binary" -v &>/dev/null || "$binary" -h &>/dev/null; then
            echo -e "  ${GREEN}✓ $(basename "$binary") is executable${NC}"
        else
            echo -e "  ${YELLOW}⚠ $(basename "$binary") may need additional libraries${NC}"
        fi
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
