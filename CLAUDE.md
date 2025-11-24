# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Synology NAS package (SPK)** for PHP 8.3.28, specifically built for DS920+ (Geminilake architecture) running DSM 7.x. The package includes PHP CLI, PHP-FPM, and an extension management system with DSM UI integration.

**Key Architecture**: The build system creates a structure-only SPK package. PHP binaries must be compiled separately using the spksrc toolchain and copied into `spk/php83/files/php/` before building.

## Core Principles (Constitution)

Follow these principles from `.specify/memory/constitution.md`:

1. **Upstream Parity**: Match official PHP 8.3 releases - no DSM-specific surprises
2. **Reproducible spksrc Builds**: Use pinned toolchains and checksum-verified sources
3. **Synology-first Integration**: Clean integration with DSM 7 services, Web Station, and UI
4. **Test & Validate on Target**: Always test on DS920+ (Geminilake) before release
5. **Documentation & Supportability**: Document build steps and DSM-specific constraints

## Building the Package

### Standard Build (Structure-Only)
```bash
# From project root
bash scripts/build-spk.sh
```

This creates: `dist/php83_8.3.28-0019_geminilake.spk`

**IMPORTANT**: This builds the package structure only. For a functional package, you need PHP binaries first.

### Complete Build (With PHP Binaries)

1. **Option A - Using spksrc (recommended)**:
```bash
# Clone and build with spksrc
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc
make setup
make arch-geminilake-7.2 php83

# Copy binaries to this project
cp -r /path/to/spksrc/build/php83/install/* \
      /path/to/php8.3/spk/php83/files/php/

# Build the SPK
cd /path/to/php8.3
bash scripts/build-spk.sh
```

2. **Option B - Using pre-built binaries**:
```bash
# Extract binaries into spk/php83/files/php/
tar xzf php-8.3.28-geminilake.tar.gz -C spk/php83/files/php/
bash scripts/build-spk.sh
```

### Build Script Details

`scripts/build-spk.sh` performs these steps:
1. Cleans `dist/build/` and creates structure
2. Copies files from `spk/php83/` (INFO, configs, scripts, icons)
3. Bundles PHP binaries from `spk/php83/files/php/`
4. Fixes permissions (binaries: 755, files: 644, shared libs: 755)
5. Creates `package.tgz` (main payload)
6. Prepares installation scripts and wizard files
7. Assembles final SPK using POSIX ustar tar format

**Version Control**: Update version in `scripts/build-spk.sh` (`PKG_BUILD` variable) and `spk/php83/INFO` before building.

## Testing

### Unit Tests
```bash
# Test extension configuration logic
bash tests/unit/extension-selection/test-config.sh
```

### Integration Tests (Requires DS920+ or QEMU)
```bash
# Test installation wizard
bash tests/integration/extension-selection/install-wizard.sh

# Test configuration panel
bash tests/integration/extension-selection/config-panel.sh
```

### Manual Installation Test
```bash
# Copy to NAS
scp dist/php83_8.3.28-0019_geminilake.spk admin@nas:/tmp/

# Install via SSH
ssh admin@nas 'synopkg install /tmp/php83_8.3.28-0019_geminilake.spk'

# Or use DSM Package Center GUI (Manual Install)
```

## Project Structure

```
php8.3/
├── spk/php83/                      # Package definition (main work area)
│   ├── INFO                        # Package metadata (name, version, arch)
│   ├── conf/                       # DSM integration configs
│   │   ├── privilege               # Permission requirements
│   │   ├── resource.conf           # REST API route definitions
│   │   ├── pkgctl-php83.sc         # Service control (systemd-like)
│   │   └── backend-php83.json      # Web Station integration
│   ├── files/                      # Package payload
│   │   ├── php/                    # PHP binaries go here (git-ignored)
│   │   │   ├── bin/                # php, php-cgi
│   │   │   ├── sbin/               # php-fpm
│   │   │   ├── lib/                # PHP libraries
│   │   │   │   └── php/extensions/ # .so files
│   │   │   └── etc/                # Default php.ini
│   │   └── conf/                   # Runtime configs
│   │       ├── php-fpm.conf
│   │       ├── extensions.json     # Extension manifest
│   │       └── extension_selection.json.sample
│   ├── src/                        # Source code
│   │   ├── scripts/                # Installation scripts
│   │   │   ├── preinst             # Pre-installation
│   │   │   ├── postinst            # Post-installation (Web Station setup)
│   │   │   ├── preuninst           # Pre-uninstall
│   │   │   ├── postuninst          # Post-uninstall
│   │   │   └── service-setup       # Service initialization
│   │   ├── install-wizard/         # Vue.js wizard (DSM 7.2+)
│   │   │   ├── package.json        # npm dependencies
│   │   │   ├── webpack.config.js   # Build config
│   │   │   └── src/                # Vue components
│   │   └── ui/                     # DSM config panel (ExtJS)
│   │       └── extension_api.cgi   # REST API handler (bash CGI)
│   └── icons/                      # Package icons (72px, 256px)
├── scripts/                        # Build automation
│   ├── build-spk.sh                # Main SPK builder
│   └── fix-binaries-rpath.sh       # RPATH patcher for binaries
├── specs/001-extension-selection/  # Feature specification
│   ├── spec.md                     # Full specification
│   ├── plan.md                     # Implementation plan
│   ├── quickstart.md               # Developer quickstart
│   └── data-model.md               # JSON schema
├── docs/
│   ├── ARCHITECTURE.md             # System architecture (read this!)
│   └── COMPILATION.md              # Cross-compilation guide
├── tests/
│   ├── unit/                       # Shell script tests
│   └── integration/                # End-to-end tests (needs NAS)
└── dist/                           # Build output (git-ignored)
```

## Key Files to Understand

### Package Metadata
- **`spk/php83/INFO`**: Package metadata (name, version, architecture, DSM requirements)
- **`spk/php83/conf/privilege`**: Permission requirements (admin-only install)
- **`spk/php83/conf/pkgctl-php83.sc`**: Service definition for DSM's pkgctl framework

### Installation Scripts
- **`src/scripts/postinst`**: Critical! Handles:
  - Creating runtime directories (`/var/packages/php83/var/`)
  - Setting permissions (sessions: 1733, tmp: 1777)
  - Web Station backend registration (copies `backend-php83.json`)
  - Updating `PluginPackage.json` for Web Station profile creation

### Configuration Management
- **`files/conf/extensions.json`**: Extension manifest with dependencies/conflicts
- **`src/ui/extension_api.cgi`**: Bash CGI script handling REST API (`/php83/extensions`)
- **`src/scripts/apply_extensions.sh`**: Applies extension changes and restarts PHP-FPM

### Build System
- **`scripts/build-spk.sh`**: Main builder - updates version here (line 18: `PKG_BUILD`)
- **`scripts/fix-binaries-rpath.sh`**: Fixes RPATH in binaries for portability

## Runtime Architecture

### Installed Package Structure
```
/var/packages/php83/
├── target/                         # Installed package (from package.tgz)
│   ├── package/                    # All files from build
│   │   ├── bin/                    # php, php-cgi
│   │   ├── sbin/                   # php-fpm
│   │   ├── etc/                    # php.ini
│   │   ├── lib/php/extensions/     # .so files
│   │   ├── conf/                   # configs
│   │   └── scripts/                # management scripts
│   └── backend-php83.json          # Web Station backend config
├── conf/                           # Runtime config (user-modifiable)
│   └── extension_selection.json    # Active extensions
├── var/                            # Runtime data
│   ├── sessions/                   # PHP sessions (1733)
│   ├── tmp/                        # Temp files (1777)
│   ├── log/                        # Logs (php_errors.log, php-fpm.log)
│   └── run/                        # PID files, sockets
│       └── php-fpm.sock            # Unix socket for FPM
└── ui/                             # DSM config panel (from package/ui/)
```

### Service Management
- **Control**: `synoservicectl --start pkgctl-php83`
- **Socket**: `/var/packages/php83/var/run/php-fpm.sock`
- **User**: `http:http` (DSM standard web user)
- **Logs**: `/var/packages/php83/var/log/` (errors, FPM, extension events)

### Web Station Integration
- **Backend Config**: `/usr/syno/etc/www/app.d/backend-php83.json` (auto-copied from `target/`)
- **Plugin Registry**: `/usr/syno/etc/packages/WebStation/PluginPackage.json` (updated by postinst)
- **Profile Creation**: Done through Web Station UI after installation

## Extension Management System

### Data Flow
1. User selects extensions in installation wizard or config panel
2. Selection stored in `/var/packages/php83/conf/extension_selection.json`
3. `apply_extensions.sh` reads JSON, validates dependencies/conflicts
4. Generates `conf.d/99-extensions.ini` with `extension=name.so` lines
5. Tests PHP config with `php -v`
6. If valid: restarts PHP-FPM and logs event
7. If invalid: rolls back and reports error

### Extension Manifest Format
```json
{
  "extensions": {
    "curl": {
      "enabled": true,
      "category": "networking",
      "dependencies": ["openssl"],
      "conflicts": [],
      "footprintMB": 5,
      "restart": "php-fpm"
    }
  }
}
```

### REST API Routes (resource.conf)
- **GET** `/php83/extensions/options` - List available extensions
- **GET** `/php83/extensions/profile` - Get current configuration
- **PATCH** `/php83/extensions/apply` - Apply configuration changes

## Common Development Tasks

### Changing Package Version
1. Edit `scripts/build-spk.sh`: Update `PKG_BUILD` (line 18)
2. Edit `spk/php83/INFO`: Update `version` (line 2)
3. Edit `src/scripts/postinst`: Update version in PluginPackage registration (line 118)
4. Rebuild: `bash scripts/build-spk.sh`

### Adding a New PHP Extension
1. Compile `.so` file using spksrc toolchain
2. Copy to `spk/php83/files/php/lib/php/extensions/no-debug-non-zts-20230831/`
3. Update `spk/php83/files/conf/extensions.json` with metadata
4. Rebuild: `bash scripts/build-spk.sh`
5. Test on DS920+

### Modifying Default php.ini
1. Edit `spk/php83/files/php/etc/php.ini`
2. Rebuild: `bash scripts/build-spk.sh`
3. **Note**: Affects new installations only. Existing installs need manual edit.

### Building Vue.js Wizard
```bash
cd spk/php83/src/install-wizard
npm install
npm run build  # Creates install_uifile

# Rebuild SPK to include updated wizard
cd ../../../../
bash scripts/build-spk.sh
```

### Debugging on NAS
```bash
# SSH to NAS
ssh admin@nas

# Check service status
synoservicectl --status pkgctl-php83

# View logs
tail -f /var/packages/php83/var/log/php-fpm.log
tail -f /var/packages/php83/var/log/php_errors.log
tail -f /var/log/php83-install.log  # Installation log

# Test PHP
/var/packages/php83/target/package/bin/php -v
/var/packages/php83/target/package/bin/php -m  # List modules

# Test FPM config
/var/packages/php83/target/package/sbin/php-fpm -t

# Check socket
ls -la /var/packages/php83/var/run/php-fpm.sock
```

### Web Station Registration Issues
If PHP 8.3 doesn't appear in Web Station:
```bash
# Check backend config
cat /usr/syno/etc/www/app.d/backend-php83.json

# Check plugin registry
cat /usr/syno/etc/packages/WebStation/PluginPackage.json | grep -A 20 php83

# Force nginx reload
systemctl reload nginx

# Check installation log
cat /var/log/php83-install.log
```

## Important Constraints

### Platform Targets
- **Architecture**: Geminilake only (Intel Celeron J4125)
- **Hardware**: DS920+ and similar models
- **DSM Version**: 7.0-40000 minimum (DSM 7.x)

### Resource Limits (DS920+)
- **Memory**: Default 128MB, opcache 128MB
- **FPM Workers**: 5 max children (dynamic PM)
- **Disk**: ~60MB with all extensions

### Security Constraints
- **Disabled Functions** (in php-fpm.conf): `exec`, `passthru`, `shell_exec`, `system`, `proc_open`, `popen`, `curl_exec`, `curl_multi_exec`, `parse_ini_file`, `show_source`
- **Install Permission**: `system:administrators` group only
- **Service User**: `http:http` (restricted)

### SPK Format Requirements (DSM 7)
- **Tar Format**: POSIX ustar (not GNU)
- **File Order**: INFO must be first, scripts after package.tgz
- **Wizard**: Directory format (`WIZARD_UIFILES/`) not tarball
- **UI Files**: Must be in `package/ui/` (extracted to `/var/packages/php83/ui/`)

## Design Decisions (Read docs/ARCHITECTURE.md for details)

- **Why JSON for config?** Human-readable, DSM-native (ExtJS), atomic updates
- **Why Bash CGI for API?** No dependencies, fast startup, secure, debuggable
- **Why Unix socket?** 20% faster than TCP, file permissions for security, DSM standard
- **Why pkgctl not systemd?** DSM 7 native, UI integration, dependency tracking
- **Why structure-only build?** Portability, flexibility with binary sources, fast iteration

## Documentation

- **`.specify/memory/constitution.md`**: Core principles (READ THIS FIRST)
- **`docs/ARCHITECTURE.md`**: Full system architecture with diagrams
- **`docs/COMPILATION.md`**: Cross-compilation instructions
- **`specs/001-extension-selection/spec.md`**: Extension management feature spec
- **`specs/001-extension-selection/quickstart.md`**: Developer workflow
- **`specs/001-extension-selection/data-model.md`**: JSON schemas

## Workflow

### Feature Development
1. Create feature branch: `git checkout -b 002-feature-name`
2. Add spec in `specs/002-feature-name/spec.md`
3. Implement in `spk/php83/src/`
4. Test on DS920+ hardware
5. Update documentation
6. Merge to main (currently: `001-extension-selection`)

### Release Process
1. Update version (see "Changing Package Version" above)
2. Run unit tests: `bash tests/unit/extension-selection/test-config.sh`
3. Build: `bash scripts/build-spk.sh`
4. Test install/uninstall on DS920+
5. Tag release: `git tag php8.3-v8.3.28-0019`
6. Upload SPK and checksum to GitHub releases

## Troubleshooting

### Build fails with "PHP binaries not found"
- **Cause**: Missing `spk/php83/files/php/` directory
- **Fix**: Compile PHP with spksrc or extract pre-built binaries first

### Package won't install on DSM
- **Check**: Architecture matches (geminilake only)
- **Check**: DSM version >= 7.0-40000
- **Logs**: `/var/log/packages/php83.log` on NAS

### PHP-FPM won't start
- **Check**: Socket permissions: `ls -la /var/packages/php83/var/run/`
- **Test config**: `/var/packages/php83/target/package/sbin/php-fpm -t`
- **Logs**: `/var/packages/php83/var/log/php-fpm.log`

### Extensions not loading
- **Verify**: `.so` file exists in `lib/php/extensions/`
- **Check**: `extension_selection.json` has correct state
- **Test**: `php -m` to see loaded modules
- **Logs**: `/var/packages/php83/var/log/php_errors.log`

### Web Station doesn't see PHP 8.3
- **Check**: `backend-php83.json` in `/usr/syno/etc/www/app.d/`
- **Check**: PluginPackage.json contains php83 entry
- **Reload**: `systemctl reload nginx`
- **Logs**: `/var/log/php83-install.log`

## Git Workflow

- **Main branch**: Currently `001-extension-selection` (feature branch)
- **Untracked files** (normal):
  - `dist/*.spk` - Build artifacts
  - `spk/php83/files/php/` - PHP binaries (too large)
  - `src/install-wizard/node_modules/` - npm dependencies

## Getting Help

- **Issues**: GitHub issue tracker
- **Synology Forums**: Community support for DSM packages
- **Logs**: Always check `/var/log/php83-install.log` and `/var/packages/php83/var/log/` first
