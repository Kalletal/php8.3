#!/usr/bin/env bash
set -euo pipefail

#############################################
# SPK Builder for PHP 8.3 - Synology Package
# Standalone builder without spksrc dependency
#############################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SPK_DIR="$PROJECT_ROOT/spk/php83"
BUILD_DIR="$PROJECT_ROOT/dist/build"
OUTPUT_DIR="$PROJECT_ROOT/dist"

# Package metadata
PKG_NAME="php83"
PKG_VERSION="8.3.8"
PKG_BUILD="0001"
PKG_ARCH="geminilake"
PKG_FULL_VERSION="${PKG_VERSION}-${PKG_BUILD}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Clean previous build
clean_build() {
    log_info "Cleaning previous build..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
}

# Create package structure
create_structure() {
    log_info "Creating package structure..."

    mkdir -p "$BUILD_DIR/package"
    mkdir -p "$BUILD_DIR/package/bin"
    mkdir -p "$BUILD_DIR/package/conf"
    mkdir -p "$BUILD_DIR/package/scripts"
    mkdir -p "$BUILD_DIR/package/lib"
    mkdir -p "$BUILD_DIR/package/share"
}

# Copy package files
copy_files() {
    log_info "Copying package files..."

    # Copy INFO file
    cp "$SPK_DIR/INFO" "$BUILD_DIR/"

    # Copy configuration files
    cp -r "$SPK_DIR/files/conf/"* "$BUILD_DIR/package/conf/" || true
    cp "$SPK_DIR/conf/pkgctl-php83.sc" "$BUILD_DIR/package/conf/"

    # Copy scripts
    cp "$SPK_DIR/src/scripts/"*.sh "$BUILD_DIR/package/scripts/" 2>/dev/null || true
    cp "$SPK_DIR/src/scripts/"*.cgi "$BUILD_DIR/package/scripts/" 2>/dev/null || true

    # Create scripts directory for installation scripts
    mkdir -p "$BUILD_DIR/scripts"

    # Copy installation scripts to root
    for script in preinst postinst preuninst postuninst service-setup start-stop-status; do
        if [ -f "$SPK_DIR/src/scripts/$script" ]; then
            cp "$SPK_DIR/src/scripts/$script" "$BUILD_DIR/scripts/"
            chmod +x "$BUILD_DIR/scripts/$script"
        fi
    done

    # Copy wizard files
    if [ -d "$SPK_DIR/src/install-wizard" ]; then
        mkdir -p "$BUILD_DIR/WIZARD_UIFILES"
        cp "$SPK_DIR/src/install-wizard/"*.json "$BUILD_DIR/WIZARD_UIFILES/" 2>/dev/null || true
        cp "$SPK_DIR/src/install-wizard/"*.js "$BUILD_DIR/WIZARD_UIFILES/" 2>/dev/null || true
    fi

    # Copy config panel files
    if [ -d "$SPK_DIR/src/config-panel" ]; then
        mkdir -p "$BUILD_DIR/package/ui"
        cp -r "$SPK_DIR/src/config-panel/"* "$BUILD_DIR/package/ui/" 2>/dev/null || true
    fi

    # Copy utilities
    if [ -d "$SPK_DIR/files/bin" ]; then
        cp "$SPK_DIR/files/bin/"* "$BUILD_DIR/package/bin/" 2>/dev/null || true
    fi

    # Copy icons
    if [ -d "$SPK_DIR/icons" ]; then
        for size in 72 256; do
            if [ -f "$SPK_DIR/icons/php83_${size}.png" ]; then
                cp "$SPK_DIR/icons/php83_${size}.png" "$BUILD_DIR/PACKAGE_ICON_${size}.PNG"
            fi
        done
    fi

    # Copy privilege and resource config
    cp "$SPK_DIR/conf/privilege" "$BUILD_DIR/"
    cp "$SPK_DIR/conf/resource.conf" "$BUILD_DIR/package/conf/" 2>/dev/null || true
}

# Download and bundle PHP binaries (stub - would need actual PHP compilation)
bundle_php() {
    log_warn "PHP binary bundling step - normally would compile PHP from source"
    log_info "For a working package, you need to:"
    echo "  1. Cross-compile PHP 8.3.8 for Geminilake architecture"
    echo "  2. Place binaries in $BUILD_DIR/package/bin/"
    echo "  3. Place libraries in $BUILD_DIR/package/lib/"
    echo "  4. Include extensions in $BUILD_DIR/package/lib/php/extensions/"

    # Create placeholder structure
    mkdir -p "$BUILD_DIR/package/lib/php/extensions"

    # Note: In a real build, you would:
    # - Use spksrc toolchain to cross-compile PHP
    # - Or download pre-built binaries from a trusted source
    # - Bundle all required .so files for extensions

    log_warn "Continuing with structure-only build..."
}

# Create package tarball
create_package_tar() {
    log_info "Creating package.tgz..."

    cd "$BUILD_DIR"
    tar czf package.tgz package/

    # Calculate checksum
    PACKAGE_SIZE=$(stat -c%s package.tgz)
    PACKAGE_MD5=$(md5sum package.tgz | cut -d' ' -f1)

    log_info "Package size: $PACKAGE_SIZE bytes"
    log_info "Package MD5: $PACKAGE_MD5"
}

# Create scripts tarball
create_scripts_tar() {
    log_info "Creating scripts tarball..."

    cd "$BUILD_DIR"
    if [ -d "scripts" ]; then
        tar czf scripts.tgz scripts/
    else
        # Create empty scripts tar if no scripts
        mkdir -p scripts
        tar czf scripts.tgz scripts/
        rmdir scripts
    fi
}

# Create wizard tarball
create_wizard_tar() {
    log_info "Creating wizard tarball..."

    cd "$BUILD_DIR"
    if [ -d "WIZARD_UIFILES" ] && [ "$(ls -A WIZARD_UIFILES)" ]; then
        tar czf WIZARD_UIFILES.tgz WIZARD_UIFILES/
    fi
}

# Create final SPK
create_spk() {
    log_info "Creating final SPK package..."

    cd "$BUILD_DIR"

    SPK_NAME="${PKG_NAME}_${PKG_FULL_VERSION}_${PKG_ARCH}.spk"

    # SPK is just a tar archive containing:
    # - INFO
    # - package.tgz
    # - scripts.tgz (optional)
    # - WIZARD_UIFILES.tgz (optional)
    # - PACKAGE_ICON*.PNG (optional)
    # - privilege (optional)

    tar cf "$OUTPUT_DIR/$SPK_NAME" \
        INFO \
        package.tgz \
        $([ -f scripts.tgz ] && echo "scripts.tgz") \
        $([ -f WIZARD_UIFILES.tgz ] && echo "WIZARD_UIFILES.tgz") \
        $([ -f PACKAGE_ICON_72.PNG ] && echo "PACKAGE_ICON_72.PNG") \
        $([ -f PACKAGE_ICON_256.PNG ] && echo "PACKAGE_ICON_256.PNG") \
        $([ -f privilege ] && echo "privilege")

    SPK_SIZE=$(stat -c%s "$OUTPUT_DIR/$SPK_NAME")
    SPK_MD5=$(md5sum "$OUTPUT_DIR/$SPK_NAME" | cut -d' ' -f1)

    log_info "=================================="
    log_info "SPK created successfully!"
    log_info "Package: $SPK_NAME"
    log_info "Location: $OUTPUT_DIR/$SPK_NAME"
    log_info "Size: $SPK_SIZE bytes ($(numfmt --to=iec-i --suffix=B $SPK_SIZE))"
    log_info "MD5: $SPK_MD5"
    log_info "=================================="
}

# Generate build info
generate_build_info() {
    log_info "Generating build information..."

    cat > "$OUTPUT_DIR/BUILD_INFO.txt" <<EOF
PHP 8.3 Synology Package Build
==============================

Package Name: ${PKG_NAME}
Version: ${PKG_FULL_VERSION}
Architecture: ${PKG_ARCH}
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Build Host: $(hostname)

Files Generated:
- ${PKG_NAME}_${PKG_FULL_VERSION}_${PKG_ARCH}.spk

Build Notes:
- This is a structure-only build
- PHP binaries need to be compiled separately using spksrc toolchain
- Extensions are managed via the included configuration scripts

Next Steps:
1. Cross-compile PHP 8.3.8 for Geminilake
2. Re-run this script after placing binaries in spk/php83/files/bin/
3. Test installation on DS920+ (or equivalent Geminilake device)

For more information, see specs/001-extension-selection/quickstart.md
EOF

    cat "$OUTPUT_DIR/BUILD_INFO.txt"
}

# Main execution
main() {
    log_info "Starting SPK build for PHP ${PKG_VERSION}"
    log_info "Target architecture: ${PKG_ARCH}"

    clean_build
    create_structure
    copy_files
    bundle_php
    create_package_tar
    create_scripts_tar
    create_wizard_tar
    create_spk
    generate_build_info

    log_info "Build completed successfully!"
    log_warn "Remember: This package needs PHP binaries to be functional"
}

# Run
main "$@"
