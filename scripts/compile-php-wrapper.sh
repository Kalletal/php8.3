#!/usr/bin/env bash
# Wrapper script to compile PHP with proper PKG_CONFIG_PATH
# This script sets up the environment without modifying spksrc core files

set -e

SPKSRC_DIR="$HOME/spksrc"
PHP_CROSS_DIR="$SPKSRC_DIR/cross/php83"
ARCH="geminilake"
TCVERSION="7.2"
WORK_DIR="$PHP_CROSS_DIR/work-$ARCH-$TCVERSION"

echo "=========================================="
echo "  PHP 8.3.8 Compilation Wrapper"
echo "=========================================="
echo ""

# Build PKG_CONFIG_PATH with all dependencies
PKG_CONFIG_PATHS=(
    "$WORK_DIR/install/usr/local/php/lib/pkgconfig"
    "$WORK_DIR/../libxml2/work-$ARCH-$TCVERSION/install/usr/local/libxml2/lib/pkgconfig"
    "$WORK_DIR/../curl/work-$ARCH-$TCVERSION/install/usr/local/curl/lib/pkgconfig"
    "$WORK_DIR/../zlib/work-$ARCH-$TCVERSION/install/usr/local/zlib/lib/pkgconfig"
    "$WORK_DIR/../sqlite/work-$ARCH-$TCVERSION/install/usr/local/sqlite-autoconf/lib/pkgconfig"
    "$WORK_DIR/../libzip/work-$ARCH-$TCVERSION/install/usr/local/libzip/lib/pkgconfig"
    "$WORK_DIR/../libicu/work-$ARCH-$TCVERSION/install/usr/local/libicu/lib/pkgconfig"
    "$WORK_DIR/../openssl3/work-$ARCH-$TCVERSION/install/usr/local/php/lib/pkgconfig"
)

# Join paths with colons
PKG_CONFIG_PATH_VALUE=$(IFS=:; echo "${PKG_CONFIG_PATHS[*]}")

echo "Setting PKG_CONFIG_PATH to include all dependencies..."
echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH_VALUE"
echo ""

# Also set PKG_CONFIG_LIBDIR (spksrc uses this one)
export PKG_CONFIG_LIBDIR="$PKG_CONFIG_PATH_VALUE"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH_VALUE"

# Additional environment variables for PHP configure
export LIBXML_CFLAGS="-I$WORK_DIR/../libxml2/work-$ARCH-$TCVERSION/install/usr/local/libxml2/include/libxml2"
export LIBXML_LIBS="-L$WORK_DIR/../libxml2/work-$ARCH-$TCVERSION/install/usr/local/libxml2/lib -lxml2"

echo "Environment configured:"
echo "  PKG_CONFIG_LIBDIR: $PKG_CONFIG_LIBDIR"
echo "  LIBXML_CFLAGS: $LIBXML_CFLAGS"
echo "  LIBXML_LIBS: $LIBXML_LIBS"
echo ""

# Change to PHP cross directory
cd "$PHP_CROSS_DIR"

# Run make with our environment
echo "Starting compilation..."
echo "Command: make ARCH=$ARCH TCVERSION=$TCVERSION"
echo ""

if [ "$1" == "--clean" ]; then
    echo "Cleaning work directory..."
    rm -rf "work-$ARCH-$TCVERSION"
    echo "Clean complete."
    echo ""
fi

# Execute make with our PKG_CONFIG settings
exec make ARCH="$ARCH" TCVERSION="$TCVERSION" \
    PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    LIBXML_CFLAGS="$LIBXML_CFLAGS" \
    LIBXML_LIBS="$LIBXML_LIBS"
