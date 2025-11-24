#!/usr/bin/env bash
#
# increment-build.sh - Auto-increment PKG_BUILD number
#
# This script automatically increments the build number across all
# version-related files in the project.
#
# Usage:
#   bash scripts/increment-build.sh          # Increment build by 1
#   bash scripts/increment-build.sh 5        # Increment build by 5
#   bash scripts/increment-build.sh reset    # Reset to a specific number
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Files that contain version information
BUILD_SCRIPT="$PROJECT_ROOT/scripts/build-spk.sh"
INFO_FILE="$PROJECT_ROOT/spk/php83/INFO"
POSTINST="$PROJECT_ROOT/spk/php83/src/scripts/postinst"

# Extract current values
get_current_version() {
    grep '^PKG_VERSION=' "$BUILD_SCRIPT" | cut -d'"' -f2
}

get_current_build() {
    grep '^PKG_BUILD=' "$BUILD_SCRIPT" | cut -d'"' -f2
}

# Get current values
CURRENT_VERSION=$(get_current_version)
CURRENT_BUILD=$(get_current_build)

echo -e "${GREEN}[INFO]${NC} Current version: $CURRENT_VERSION-$CURRENT_BUILD"

# Determine increment amount
INCREMENT=${1:-1}

if [[ "$INCREMENT" == "reset" ]]; then
    read -p "Enter new build number: " NEW_BUILD
elif [[ "$INCREMENT" =~ ^[0-9]+$ ]]; then
    # Force decimal interpretation (handle leading zeros)
    NEW_BUILD=$((10#$CURRENT_BUILD + INCREMENT))
    # Pad with zeros to match original format
    NEW_BUILD=$(printf "%04d" $NEW_BUILD)
else
    echo -e "${RED}[ERROR]${NC} Invalid argument: $INCREMENT"
    echo "Usage: $0 [number|reset]"
    exit 1
fi

echo -e "${YELLOW}[UPDATING]${NC} Incrementing build: $CURRENT_BUILD → $NEW_BUILD"

# Update build-spk.sh
sed -i "s/^PKG_BUILD=\"$CURRENT_BUILD\"/PKG_BUILD=\"$NEW_BUILD\"/" "$BUILD_SCRIPT"

# Update INFO file
sed -i "s/version=\"$CURRENT_VERSION-$CURRENT_BUILD\"/version=\"$CURRENT_VERSION-$NEW_BUILD\"/" "$INFO_FILE"

# Update postinst if it contains version references
if grep -q "$CURRENT_VERSION-$CURRENT_BUILD" "$POSTINST" 2>/dev/null; then
    sed -i "s/$CURRENT_VERSION-$CURRENT_BUILD/$CURRENT_VERSION-$NEW_BUILD/g" "$POSTINST"
fi

# Verify changes
echo ""
echo -e "${GREEN}[SUCCESS]${NC} Build number updated in all files:"
echo "  - scripts/build-spk.sh"
echo "  - spk/php83/INFO"
echo "  - spk/php83/src/scripts/postinst (if applicable)"
echo ""
echo -e "${GREEN}[INFO]${NC} New version: $CURRENT_VERSION-$NEW_BUILD"
echo ""
echo "Run 'bash scripts/build-spk.sh' to build with the new version."
