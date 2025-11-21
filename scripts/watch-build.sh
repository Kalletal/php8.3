#!/bin/bash
# Script de monitoring de la compilation PHP

LOG_FILE="/tmp/php-build-final.log"
BUILD_DIR="/home/gilles/spksrc/cross/php83/work-geminilake-7.2"

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║        PHP 8.3.8 Build Monitor for Geminilake (DS920+)             ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

while true; do
    clear
    echo "═══ Build Status - $(date '+%H:%M:%S') ═══"
    echo ""
    
    # Check which component is being built
    if [ -f "$LOG_FILE" ]; then
        CURRENT=$(tail -5 "$LOG_FILE" | grep -E "(===>|Compiling|Building|make\[)" | tail -1)
        echo "Current: $CURRENT"
        echo ""
        
        # Component status
        echo "─── Dependencies Status ───"
        [ -f "$BUILD_DIR/.openssl3-install_done" ] && echo "✓ OpenSSL 3.5.4" || echo "⏳ OpenSSL 3.5.4"
        [ -f "$BUILD_DIR/.curl-install_done" ] && echo "✓ cURL 8.4.0" || echo "⏳ cURL 8.4.0"
        [ -f "$BUILD_DIR/.libicu-install_done" ] && echo "✓ ICU" || echo "⏳ ICU"
        [ -f "$BUILD_DIR/.libxml2-install_done" ] && echo "✓ libxml2" || echo "⏳ libxml2"
        [ -f "$BUILD_DIR/.zlib-install_done" ] && echo "✓ zlib" || echo "⏳ zlib"
        [ -f "$BUILD_DIR/.sqlite-install_done" ] && echo "✓ SQLite" || echo "⏳ SQLite"
        [ -f "$BUILD_DIR/.libzip-install_done" ] && echo "✓ libzip" || echo "⏳ libzip"
        
        echo ""
        echo "─── PHP Compilation ───"
        [ -f "$BUILD_DIR/.php-configure_done" ] && echo "✓ Configure" || echo "⏳ Configure"
        [ -f "$BUILD_DIR/.php-compile_done" ] && echo "✓ Compile" || echo "⏳ Compile"
        [ -f "$BUILD_DIR/.php-install_done" ] && echo "✓ Install" || echo "⏳ Install"
        
        echo ""
        echo "─── Binaries ───"
        if [ -f "$BUILD_DIR/install/usr/local/php/bin/php" ]; then
            PHP_VER=$("$BUILD_DIR/install/usr/local/php/bin/php" -v 2>/dev/null | head -1)
            echo "✓ php binary: $PHP_VER"
        else
            echo "⏳ php binary"
        fi
        
        if [ -f "$BUILD_DIR/install/usr/local/php/sbin/php-fpm" ]; then
            echo "✓ php-fpm binary"
        else
            echo "⏳ php-fpm binary"
        fi
        
        echo ""
        echo "─── Recent Output ───"
        tail -8 "$LOG_FILE" | sed 's/^/  /'
    else
        echo "⏳ Waiting for build to start..."
    fi
    
    # Check if build is complete
    if [ -f "$BUILD_DIR/.php-install_done" ]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════════════╗"
        echo "║                    ✓ BUILD COMPLETE!                                ║"
        echo "╚══════════════════════════════════════════════════════════════════════╝"
        break
    fi
    
    sleep 30
done
