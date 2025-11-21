#!/bin/bash
#
# Script pour corriger les RPATH des binaires PHP
# Supprime les chemins absolus de compilation et utilise $ORIGIN
#

set -e

PACKAGE_DIR="$1"
if [ -z "$PACKAGE_DIR" ]; then
    echo "Usage: $0 <package_directory>"
    exit 1
fi

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "Error: Directory $PACKAGE_DIR does not exist"
    exit 1
fi

echo "=== Fixing RPATH for PHP binaries ==="
echo "Package directory: $PACKAGE_DIR"
echo ""

# Check if patchelf is available
if ! command -v patchelf &> /dev/null; then
    echo "Error: patchelf is not installed"
    echo "Install with: sudo apt-get install patchelf"
    exit 1
fi

# List of binaries to fix
BINARIES=(
    "$PACKAGE_DIR/sbin/php-fpm"
    "$PACKAGE_DIR/bin/php"
    "$PACKAGE_DIR/bin/php-cgi"
    "$PACKAGE_DIR/bin/phpdbg"
)

# Create missing libz.so symlink if needed
if [ ! -e "$PACKAGE_DIR/lib/libz.so" ] && [ -e "$PACKAGE_DIR/lib/libz.so.1" ]; then
    echo "Creating libz.so symlink..."
    ln -sf libz.so.1 "$PACKAGE_DIR/lib/libz.so"
fi

# Fix shared libraries first (they need $ORIGIN to point to lib/)
echo "Fixing shared libraries RPATH..."
find "$PACKAGE_DIR/lib" -type f -name "*.so*" | while read LIB; do
    if file "$LIB" | grep -q "ELF"; then
        echo "  Processing: $(basename $LIB)"

        # Replace absolute paths in NEEDED entries with just library names
        readelf -d "$LIB" | grep NEEDED | grep -o '/[^]]*\.so[^]]*' | sed 's/]$//' | while read ABSPATH; do
            LIBNAME=$(basename "$ABSPATH")
            echo "    Replacing $ABSPATH with $LIBNAME"
            patchelf --replace-needed "$ABSPATH" "$LIBNAME" "$LIB" 2>/dev/null || true
        done

        # Set RPATH to look in current dir and parent dir
        patchelf --set-rpath '$ORIGIN:$ORIGIN/..' "$LIB" 2>/dev/null || true
    fi
done

# Fix each binary
echo ""
echo "Fixing binaries RPATH..."
for BINARY in "${BINARIES[@]}"; do
    if [ ! -f "$BINARY" ]; then
        echo "Warning: $BINARY not found, skipping"
        continue
    fi

    echo "Processing: $(basename $BINARY)"

    # Remove hardcoded absolute paths by replacing them with relative $ORIGIN paths
    # This tells the binary to look for libraries relative to its own location
    patchelf --set-rpath '$ORIGIN/../lib' "$BINARY" 2>/dev/null || true

    echo "  ✓ RPATH set to: \$ORIGIN/../lib"
done

echo ""
echo "=== Verification ==="
for BINARY in "${BINARIES[@]}"; do
    if [ -f "$BINARY" ]; then
        echo "$(basename $BINARY):"
        readelf -d "$BINARY" | grep -E 'RPATH|RUNPATH' || echo "  (no RPATH/RUNPATH)"
    fi
done

echo ""
echo "=== Done ==="
