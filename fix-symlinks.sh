#!/bin/bash
# Fix broken symlinks in lib directory

LIB_DIR="spk/php83/files/php/lib"

cd "$LIB_DIR" || exit 1

echo "Fixing symlinks in $LIB_DIR..."

# Find all .so files with version numbers and create symlinks
for full_lib in *.so.*.*; do
    if [ ! -f "$full_lib" ]; then
        continue
    fi

    # Get the base name without version (e.g., libxml2.so.2 from libxml2.so.2.12.9)
    base_name=$(echo "$full_lib" | sed -E 's/\.[0-9]+\.[0-9]+(\.[0-9]+)?$//')

    # Check if base_name file exists and is not a symlink
    if [ -f "$base_name" ] && [ ! -L "$base_name" ]; then
        file_size=$(stat --format='%s' "$base_name" 2>/dev/null || stat -f '%z' "$base_name" 2>/dev/null)

        # If file is very small (less than 100 bytes), it's probably corrupted
        if [ "$file_size" -lt 100 ]; then
            echo "  Fixing: $base_name -> $full_lib"
            rm -f "$base_name"
            ln -s "$full_lib" "$base_name"
        fi
    elif [ ! -e "$base_name" ]; then
        echo "  Creating: $base_name -> $full_lib"
        ln -s "$full_lib" "$base_name"
    fi
done

echo ""
echo "✓ Symlinks fixed!"
echo ""
echo "Verifying symlinks:"
ls -lh | grep "^l" | head -10
