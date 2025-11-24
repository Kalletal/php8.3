import json

# Read the compiled bundle
with open('/mnt/c/Users/gdalm/ProjetsSPK/php8.3/spk/php83/src/install-wizard/dist/install_entry.bundle.js', 'r') as f:
    bundle_content = f.read()

# Create the install_uifile JSON structure
uifile_data = [{
    "custom_render_fn": bundle_content,
    "custom_render_name": "install_setting"
}]

# Write to install_uifile
with open('/mnt/c/Users/gdalm/ProjetsSPK/php8.3/spk/php83/src/install-wizard/install_uifile', 'w') as f:
    json.dump(uifile_data, f)

print("✓ install_uifile regenerated successfully")
