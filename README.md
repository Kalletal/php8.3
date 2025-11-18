# PHP 8.3 for Synology DSM 7

A complete PHP 8.3 package for Synology NAS (DS920+ / Geminilake architecture) with extension management capabilities.

## 🎯 Features

- **PHP 8.3.8** with full CLI and FPM support
- **Interactive Extension Selection** during installation via DSM Package Center wizard
- **Post-Install Configuration Panel** to enable/disable extensions through DSM interface
- **Dependency Management** - automatically handles extension dependencies and conflicts
- **Optimized for DS920+** (Geminilake) with proper resource limits
- **Logging & Audit** - full audit trail of extension changes
- **Web Station Compatible** - integrates seamlessly with DSM's Web Station

## 📋 Package Contents

### Core Components
- PHP 8.3.8 CLI and FPM binaries
- Default `php.ini` tuned for Synology (128MB memory, opcache enabled)
- PHP-FPM pool configuration (dynamic PM, 5 max children)
- Extension management system with JSON-based configuration

### Available Extensions (Curated Set)
- **Networking**: curl, openssl
- **Database**: pdo_mysql, mysqli, pdo_sqlite, sqlite3
- **Localization**: intl
- **Graphics**: gd
- **Compression**: zip, zlib
- **Data**: json, xml, mbstring

### Management Tools
- Installation wizard with extension selector
- DSM configuration panel (ExtJS-based)
- REST API for extension management (`/php83/extensions`)
- Command-line utilities for batch operations

## 🚀 Quick Start

### Building the Package

1. **Clone this repository**
   ```bash
   git clone <repo-url>
   cd php8.3
   ```

2. **Download PHP sources** (already done if following this guide)
   ```bash
   cd spk/php83
   bash scripts/download-php-source.sh 8.3.8 files/php-src
   ```

3. **Build the SPK structure**
   ```bash
   cd ../..
   bash scripts/build-spk.sh
   ```

   This creates: `dist/php83_8.3.8-0001_geminilake.spk`

### ⚠️ Important: PHP Binary Compilation

The built SPK is a **structure-only package**. To make it functional, you need to:

#### Option A: Use spksrc Toolchain (Recommended)

```bash
# Install spksrc
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc

# Build PHP for Geminilake
make setup
make arch-geminilake-7.2 php83

# Copy binaries to package
cp -r /path/to/spksrc/build/php83/install/* \
   /path/to/php8.3/spk/php83/files/bin/

# Rebuild SPK
cd /path/to/php8.3
bash scripts/build-spk.sh
```

#### Option B: Cross-Compile Manually

See `docs/COMPILATION.md` for detailed cross-compilation instructions.

#### Option C: Download Pre-Built Binaries

```bash
# If you have access to pre-built PHP binaries for Geminilake:
tar xzf php-8.3.8-geminilake.tar.gz -C spk/php83/files/
bash scripts/build-spk.sh
```

## 📦 Installation on Synology

### Via Package Center

1. Open **Package Center** on your Synology DSM
2. Click **Manual Install**
3. Select the `php83_8.3.8-0001_geminilake.spk` file
4. Follow the installation wizard:
   - Select which PHP extensions to enable
   - Review dependencies and conflicts
   - Confirm installation

### Post-Installation Configuration

1. Go to **Main Menu** → **PHP 8.3**
2. The configuration panel allows you to:
   - Enable/disable extensions
   - View extension details and dependencies
   - See disk footprint and restart requirements
   - Apply changes (with automatic FPM restart)

## 🔧 Configuration

### File Locations

```
/var/packages/php83/
├── target/                      # Installed package
│   ├── bin/                     # PHP binaries (php, php-fpm)
│   ├── conf/                    # Configuration files
│   │   ├── php.ini
│   │   ├── php-fpm.conf
│   │   └── pkgctl-php83.sc      # Service control
│   ├── lib/                     # PHP libraries and extensions
│   └── scripts/                 # Management scripts
├── conf/                        # Runtime configuration
│   └── extension_selection.json # Active extension profile
├── var/                         # Runtime data
│   ├── log/                     # Logs
│   ├── run/                     # PID files, sockets
│   ├── sessions/                # PHP sessions
│   └── tmp/                     # Temporary files
└── source/                      # PHP source archive (for reference)
    └── php-8.3.8.tar.gz
```

### PHP-FPM Socket

Applications can connect to PHP-FPM via:
```
/var/packages/php83/var/run/php-fpm.sock
```

Configure your web server (nginx/Apache) to use this socket.

### Logs

- **PHP Errors**: `/var/packages/php83/var/log/php_errors.log`
- **FPM Errors**: `/var/packages/php83/var/log/php-fpm.log`
- **FPM Pool Errors**: `/var/packages/php83/var/log/php-fpm-www-error.log`
- **Extension Events**: `/var/packages/php83/var/log/extension-events.log`

## 🛠️ Development

### Project Structure

```
php8.3/
├── spk/php83/                   # Package definition
│   ├── INFO                     # Package metadata
│   ├── Makefile                 # Build configuration
│   ├── conf/                    # Package configuration
│   │   ├── privilege            # DSM permissions
│   │   ├── resource.conf        # REST API routes
│   │   └── pkgctl-php83.sc      # Service control definition
│   ├── files/                   # Package content
│   │   ├── conf/                # Default configs
│   │   ├── bin/                 # Utilities
│   │   └── php-src/             # PHP source tarball
│   ├── src/                     # Source scripts and UI
│   │   ├── install-wizard/      # Installation wizard UI
│   │   ├── config-panel/        # DSM configuration panel
│   │   └── scripts/             # Installation & management scripts
│   └── icons/                   # Package icons
├── scripts/                     # Build scripts
│   └── build-spk.sh             # Main SPK builder
├── specs/                       # Feature specifications
│   └── 001-extension-selection/
├── tests/                       # Test suites
│   ├── integration/
│   └── unit/
└── dist/                        # Build output
```

### Running Tests

```bash
# Unit tests (extension configuration logic)
bash tests/unit/extension-selection/test-config.sh

# Integration tests (requires DS920+ or VM)
bash tests/integration/extension-selection/install-wizard.sh
bash tests/integration/extension-selection/config-panel.sh
```

### Making Changes

See `specs/001-extension-selection/quickstart.md` for developer workflow.

## 🔐 Security

### Disabled Functions

For security, these functions are disabled in FPM by default:
- `exec`, `passthru`, `shell_exec`, `system`
- `proc_open`, `popen`
- `curl_exec`, `curl_multi_exec`
- `parse_ini_file`, `show_source`

Modify `/var/packages/php83/target/conf/php-fpm.conf` to adjust.

### Permissions

- FPM runs as `http:http` user
- Configuration API requires `system:administrators` group
- Session directory has `1733` permissions (sticky + restricted)

## 📚 Documentation

- **Constitution**: `.specify/memory/constitution.md` - Core principles
- **Feature Spec**: `specs/001-extension-selection/spec.md` - Extension management feature
- **Implementation Plan**: `specs/001-extension-selection/plan.md`
- **Developer Guide**: `specs/001-extension-selection/quickstart.md`
- **Data Model**: `specs/001-extension-selection/data-model.md`
- **API Contracts**: `specs/001-extension-selection/contracts/`

## 🤝 Contributing

1. Follow the **Constitution** principles (upstream parity, reproducible builds, DSM integration)
2. Create feature branches following the spec workflow
3. Test on DS920+ hardware before submitting
4. Update documentation and tests

## 📄 License

This package follows PHP's license for the included PHP sources. Package scripts and tooling are provided as-is for Synology NAS users.

## ⚠️ Disclaimer

- **Unofficial Package**: Not endorsed by Synology or PHP
- **Target Hardware**: DS920+ (Geminilake) on DSM 7.x
- **Use at Your Own Risk**: Test in non-production first
- **No Warranty**: Community-maintained project

## 🐛 Troubleshooting

### Package Won't Install
- Check DSM version (requires 7.2+)
- Verify architecture (must be Geminilake)
- Review `/var/log/packages/php83.log`

### Extensions Not Loading
- Check `/var/packages/php83/var/log/php_errors.log`
- Verify extension file exists: `ls /var/packages/php83/target/lib/php/extensions/`
- Run `php -m` to see loaded modules

### FPM Won't Start
- Check FPM log: `cat /var/packages/php83/var/log/php-fpm.log`
- Verify socket permissions: `ls -la /var/packages/php83/var/run/`
- Test config: `/var/packages/php83/target/bin/php-fpm -t`

### Configuration Panel Not Accessible
- Verify service is running: `synoservicectl --status pkgctl-php83`
- Check DSM user has administrator rights
- Review resource configuration: `cat /var/packages/php83/conf/resource.conf`

## 📞 Support

- **Issues**: File bugs and feature requests on GitHub
- **Synology Forums**: Community support for DSM packages
- **PHP Documentation**: https://www.php.net/docs.php

---

**Built with ❤️ for the Synology community**
