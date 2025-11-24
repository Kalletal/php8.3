# PHP 8.3 Package Architecture

This document describes the technical architecture of the PHP 8.3 Synology package, including how components interact, data flows, and key design decisions.

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Synology DSM 7                         │
│  ┌───────────────┐         ┌──────────────────────────┐    │
│  │ Package Center│◄────────┤  Installation Wizard      │    │
│  │               │         │  (Extension Selection)    │    │
│  └───────┬───────┘         └──────────────────────────┘    │
│          │                                                   │
│          ▼                                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Package Installation Flow                 │  │
│  │  preinst → extract → postinst → service-setup         │  │
│  └───────────────────────────────────────────────────────┘  │
│          │                                                   │
│          ▼                                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          /var/packages/php83/                         │  │
│  │  ┌─────────────┐    ┌──────────────┐                 │  │
│  │  │   target/   │    │    conf/     │                 │  │
│  │  │  (binaries) │    │ (user config)│                 │  │
│  │  └──────┬──────┘    └──────┬───────┘                 │  │
│  │         │                  │                          │  │
│  │         ▼                  ▼                          │  │
│  │  ┌────────────────────────────────────┐              │  │
│  │  │     PHP-FPM Service                │              │  │
│  │  │  (runs as http:http)               │              │  │
│  │  │  Socket: var/run/php-fpm.sock      │              │  │
│  │  └────────────────────────────────────┘              │  │
│  └───────────────────────────────────────────────────────┘  │
│          ▲                          ▲                        │
│          │                          │                        │
│  ┌───────┴────────┐        ┌────────┴──────────┐           │
│  │  Web Station   │        │  Config Panel     │           │
│  │  (nginx/Apache)│        │  (ExtJS UI)       │           │
│  └────────────────┘        └───────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Installation Layer

#### Wizard (WIZARD_UIFILES)
- **Location**: `src/install-wizard/`
- **Technology**: JSON schema + vanilla JavaScript
- **Purpose**: Present extension selection UI during package installation
- **Files**:
  - `extension-selection.json`: UI layout and field definitions
  - `extension-selection.js`: Client-side validation and dependency logic
  - `strings.json`: Localized UI strings

**Data Flow**:
```
User selects extensions in wizard
    ↓
extension-selection.js validates dependencies
    ↓
wizard_php83_extensions variable populated
    ↓
preinst script reads variable
    ↓
Writes to /var/packages/php83/conf/extension_selection.json
```

#### Installation Scripts
- **Location**: `src/scripts/`
- **Technology**: POSIX shell (bash)
- **Scripts**:
  - `preinst`: Creates directories, captures wizard selections
  - `postinst`: Applies extension config, sets permissions, registers service
  - `preuninst`: Stops service gracefully
  - `postuninst`: Cleans up runtime data

### 2. Service Layer

#### PHP-FPM Process Management
- **Control**: `pkgctl` (DSM 7 service framework)
- **Configuration**: `conf/pkgctl-php83.sc`
- **Socket**: Unix domain socket at `/var/packages/php83/var/run/php-fpm.sock`

**Service Lifecycle**:
```
Package Center "Start" button
    ↓
synoservicectl --start pkgctl-php83
    ↓
pkgctl reads pkgctl-php83.sc
    ↓
Executes pre-start.sh (creates dirs, applies extensions)
    ↓
Starts PHP-FPM with config: conf/php-fpm.conf
    ↓
FPM creates socket with http:http ownership
    ↓
Service registered as "Running"
```

#### Configuration Files
- **php.ini**: `/var/packages/php83/target/conf/php.ini`
  - Memory: 128MB
  - Opcache: Enabled (128MB)
  - Error log: `/var/packages/php83/var/log/php_errors.log`
  - Session path: `/var/packages/php83/var/sessions`

- **php-fpm.conf**: `/var/packages/php83/target/conf/php-fpm.conf`
  - Process manager: `dynamic`
  - Max children: 5 (tuned for 4GB RAM on DS920+)
  - User/Group: `http:http`
  - Socket mode: 0660

### 3. Extension Management System

#### Data Model
Central to the package is the **Extension Configuration Profile**:

```json
{
  "version": "1.0",
  "extensions": {
    "curl": {
      "enabled": true,
      "category": "networking",
      "dependencies": ["openssl"],
      "conflicts": [],
      "footprintMB": 5,
      "restart": "php-fpm"
    },
    "pdo_mysql": {
      "enabled": false,
      "category": "database",
      "dependencies": ["pdo"],
      "conflicts": ["mysqli"],
      "footprintMB": 7,
      "restart": "php-fpm"
    }
  },
  "metadata": {
    "lastModified": "2025-11-18T16:00:00Z",
    "modifiedBy": "admin",
    "previousProfile": "/var/packages/php83/conf/extension_selection.json.bak"
  }
}
```

Stored at: `/var/packages/php83/conf/extension_selection.json`

#### Extension Application Pipeline

**Script**: `apply_extensions.sh`

```
Read extension_selection.json
    ↓
For each enabled extension:
  ├─ Verify .so file exists in lib/php/extensions/
  ├─ Check dependencies are enabled
  └─ Validate no conflicts
    ↓
Generate INI fragment: conf.d/99-extensions.ini
    ↓
Test PHP config: php -v
    ↓
If test passes:
  ├─ Backup old config → extension_selection.json.bak
  ├─ Restart PHP-FPM: synoservicectl --restart pkgctl-php83
  └─ Log event → var/log/extension-events.log
Else:
  └─ Rollback and report error
```

### 4. Configuration Panel

#### REST API (`extension_api.cgi`)
- **Technology**: Bash CGI script
- **Routes**: Defined in `conf/resource.conf`

```
GET  /php83/extensions/options    → List available extensions
GET  /php83/extensions/profile    → Get current configuration
PATCH /php83/extensions/apply     → Apply configuration changes
```

**Request/Response Format**:
```json
// GET /profile
{
  "extensions": { /* current state */ },
  "metadata": { /* timestamps, etc */ }
}

// PATCH /apply
Request: {
  "extensions": {
    "intl": { "enabled": true },
    "gd": { "enabled": false }
  }
}

Response: {
  "success": true,
  "applied": ["intl"],
  "failed": [],
  "restartRequired": true,
  "restartQueued": true
}
```

#### ExtJS Panel
- **Location**: `src/config-panel/extension-panel.js`
- **Framework**: ExtJS (DSM standard)
- **Features**:
  - Grid view of extensions
  - Filtering by category
  - Batch enable/disable
  - Dependency tree visualization
  - Real-time validation

**UI Flow**:
```
Panel loads
    ↓
Fetch current state: GET /profile
    ↓
Display in grid with status indicators
    ↓
User toggles extensions
    ↓
Client-side validation (dependencies/conflicts)
    ↓
User clicks "Apply"
    ↓
Batch PATCH request to /apply
    ↓
Show progress spinner
    ↓
Display results (success/errors)
    ↓
Trigger FPM restart if needed
    ↓
Refresh status
```

### 5. Security Architecture

#### Permission Model
- **Package Install**: `system:administrators` only (via `conf/privilege`)
- **Service User**: `http:http` (DSM standard web user)
- **API Access**: Requires admin token (enforced by DSM)

#### File Permissions
```
/var/packages/php83/
├── target/               (root:root, 755)
├── conf/                 (root:root, 755)
│   └── extension_selection.json (root:root, 644)
├── var/
│   ├── sessions/         (http:http, 1733) - sticky, restricted delete
│   ├── tmp/              (http:http, 1777) - world writable, sticky
│   ├── log/              (root:root, 755)
│   └── run/              (http:http, 755)
        └── php-fpm.sock  (http:http, 660)
```

#### Disabled Functions (Security Hardening)
In `php-fpm.conf`:
```ini
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
```

Rationale:
- Prevent command injection attacks
- Block PHP shells
- Secure multi-tenant environments (e.g., Web Station with multiple sites)

### 6. Logging & Observability

#### Log Files

| Log | Purpose | Rotation |
|-----|---------|----------|
| `php_errors.log` | PHP runtime errors (via error_log) | 10MB × 5 |
| `php-fpm.log` | FPM process events (start/stop/restart) | 10MB × 5 |
| `php-fpm-www-error.log` | Pool-specific errors | 10MB × 5 |
| `extension-events.log` | Audit trail of extension changes | 10MB × 5 |

**Rotation**: Configured in `conf/logrotate.d/php83-extension-selection`

#### Event Logging
Every extension state change is logged:
```
2025-11-18T16:30:00Z [admin] ENABLE curl (dependencies: openssl)
2025-11-18T16:30:05Z [system] RESTART php-fpm (pid: 12345)
2025-11-18T16:30:10Z [admin] APPLY success (changed: 1, failed: 0)
```

### 7. Build & Packaging

#### SPK Structure
```
php83_8.3.28-0019_geminilake.spk (tar archive)
├── INFO                          # Package metadata
├── package.tgz                   # Main payload
│   ├── bin/                      # PHP binaries
│   ├── conf/                     # Default configs
│   ├── lib/                      # PHP libraries + extensions
│   ├── scripts/                  # Management scripts
│   └── ui/                       # Config panel assets
├── scripts.tgz                   # Installation scripts
│   ├── preinst
│   ├── postinst
│   ├── preuninst
│   ├── postuninst
│   └── service-setup
├── WIZARD_UIFILES.tgz            # Installation wizard
│   └── extension-selection.{json,js}
├── PACKAGE_ICON_72.PNG           # Small icon
├── PACKAGE_ICON_256.PNG          # Large icon
└── privilege                     # Permission requirements
```

#### Build Process
```
scripts/build-spk.sh
    ↓
1. Clean dist/build/
2. Create directory structure
3. Copy files from spk/php83/
    ├─ INFO → root
    ├─ files/* → package/
    ├─ src/scripts/* → package/scripts/ + scripts/
    ├─ src/install-wizard/* → WIZARD_UIFILES/
    └─ conf/* → root
4. Create package.tgz (package/)
5. Create scripts.tgz (scripts/)
6. Create WIZARD_UIFILES.tgz
7. Combine into final SPK (tar)
    ↓
Output: dist/php83_8.3.28-0019_geminilake.spk
```

## Design Decisions

### Why JSON for Extension Config?
- **Human-readable**: Admins can manually edit if needed
- **Structured**: Easy to validate and version
- **DSM-native**: ExtJS has excellent JSON handling
- **Atomic updates**: Single file write with backup

### Why Bash CGI for API?
- **No dependencies**: Works with base DSM install
- **Fast startup**: No interpreter overhead
- **Secure**: Runs with restricted permissions
- **Debuggable**: Easy to trace with `set -x`

### Why Unix Socket (not TCP)?
- **Performance**: ~20% faster than TCP loopback
- **Security**: File permissions control access
- **No port conflicts**: No need to manage port allocation
- **DSM standard**: Matches nginx/Apache expectations

### Why pkgctl (not systemd)?
- **DSM 7 native**: Guaranteed compatibility
- **UI integration**: Status visible in Package Center
- **Dependency tracking**: DSM manages service ordering
- **Automatic restart**: On package upgrade

### Why Structure-Only Build?
- **Portability**: Build system works without cross-compiler
- **Flexibility**: Use any PHP binary source (spksrc, manual, cached)
- **Fast iteration**: Rebuild SPK in seconds to test packaging changes
- **Documentation**: Forces clear separation between compilation and packaging

## Extension Points

### Adding New Extensions

1. **Compile extension** (see `docs/COMPILATION.md`)
2. **Copy `.so` file** to `files/lib/php/extensions/`
3. **Update manifest** in `files/conf/extension_options.json`:
   ```json
   {
     "name": "redis",
     "category": "cache",
     "default": false,
     "dependencies": [],
     "conflicts": [],
     "footprintMB": 3,
     "restart": "php-fpm"
   }
   ```
4. **Rebuild SPK**: `bash scripts/build-spk.sh`
5. **Test**: Install and verify in DSM

### Customizing php.ini Defaults

Edit `files/conf/php.ini` before build:
```ini
memory_limit = 256M  # Increase for heavy workloads
opcache.memory_consumption=256  # More opcache
```

Rebuild SPK. Changes apply to new installations.

Existing installations: Manual edit `/var/packages/php83/target/conf/php.ini`

### Integrating with Web Station

Web Station configuration (nginx example):
```nginx
location ~ \.php$ {
    fastcgi_pass unix:/var/packages/php83/var/run/php-fpm.sock;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

### Monitoring & Metrics

Future enhancement: Expose PHP-FPM status page
```ini
# In php-fpm.conf
pm.status_path = /fpm-status

# Accessible via:
# curl unix:/var/packages/php83/var/run/php-fpm.sock/fpm-status
```

## Performance Characteristics

### Resource Usage (DS920+)

| Metric | Value | Notes |
|--------|-------|-------|
| Idle RAM | ~50MB | 2 FPM workers + master |
| Peak RAM | ~200MB | 5 workers active + opcache |
| Disk (base) | ~30MB | Binaries + core extensions |
| Disk (all ext) | ~60MB | With all extensions enabled |
| Startup time | ~2s | Cold start to ready |
| Request latency | <10ms | Opcache hit, simple script |

### Bottlenecks

1. **Worker count**: Limited to 5 by default (tune for workload)
2. **Opcache size**: 128MB (increase for large codebases)
3. **Socket permissions**: Ensure nginx/Apache runs as `http` or in `http` group

## Testing Strategy

### Unit Tests
- **Target**: Shell functions in `extension_config.sh`, `apply_extensions.sh`
- **Location**: `tests/unit/extension-selection/`
- **Execution**: Local development machine

### Integration Tests
- **Target**: Full install/uninstall cycle, API endpoints, wizard flow
- **Location**: `tests/integration/extension-selection/`
- **Execution**: DS920+ hardware or QEMU emulator

### Smoke Tests
Manual checklist before release:
- [ ] Install via Package Center
- [ ] Select extensions in wizard
- [ ] Verify `php -m` matches selection
- [ ] Start service successfully
- [ ] Connect via socket from nginx
- [ ] Open config panel in DSM
- [ ] Toggle extensions and apply
- [ ] Check logs for errors
- [ ] Uninstall cleanly

## Future Enhancements

### Planned
- [ ] Automatic security updates (PHP patches)
- [ ] Extension marketplace (browse PECL)
- [ ] Performance metrics dashboard
- [ ] Multi-version support (PHP 8.1, 8.2, 8.3 simultaneously)

### Considered but Deferred
- ❌ CLI-based extension manager (DSM UI sufficient)
- ❌ Docker integration (conflicts with DSM philosophy)
- ❌ Automatic backups (user responsibility)

---

**Architecture Review Date**: 2025-11-18
**Reviewed By**: Implementation Team
**Status**: Stable for Production
