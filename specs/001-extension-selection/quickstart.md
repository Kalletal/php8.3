# Quickstart – PHP Extension Selection Controls

## Prerequisites

1. Linux build host with `spksrc` prerequisites installed (GNU Make, Docker/QEMU per Synology docs).  
2. DSM 7.x device matching DS920+ (Geminilake) for integration testing.  
3. Environment variables: `SPKSRC_CROSS_PLATFORM=geminilake`, `PYTHON3`, `GOOGLE_CHROME` (if using DSM UI debugger).  
4. Access to `synopkg` CLI on the NAS via SSH for deployment/testing.
5. Internet access to download the official PHP 8.3 source tarball (handled by the helper script below).

## Build & Configure

```bash
cd /path/to/spksrc
make setup
cd spk/php83
./scripts/download-php-source.sh 8.3.28      # caches php-8.3.28.tar.gz with SHA-256 verification
make arch-geminilake-7.2
```

1. Update `spk/php83/Makefile` with the `EXTENSION_OPTIONS` manifest plus wizard file references.  
2. Place installer wizard assets under `spk/php83/src/install-wizard/` and Control Panel assets under `src/config-panel/`.  
3. Provide default config template at `spk/php83/files/conf/extension_selection.json.sample`.  
4. Confirm that `files/php-src/php-8.3.28.tar.gz` exists; it will be copied to `/var/packages/php83/source/php-8.3.28.tar.gz` at install time.

## Deploy to DSM

```bash
scp packages/php83_geminilake-7.2_*.spk admin@nas:/tmp/
ssh admin@nas 'synopkg install /tmp/php83_geminilake-7.2_*.spk'
```

1. Walk through the Package Center wizard; confirm the new extension selection page appears.  
2. After installation, open the PHP 8.3 package settings in DSM and verify the configuration panel lists all extensions with correct states.

## Validate Extension Toggles

1. From DSM UI, enable/disable a few extensions and click Apply.  
2. On the NAS shell, run `php -m | sort` to confirm the module list reflects selections.  
3. Review `/var/log/php83-extension-selection.log` for audit entries produced by `log-extension-event.sh`.  
4. Trigger low-disk or dependency-conflict scenarios to ensure the wizard and DSM panel warnings prevent unsafe operations.  
5. Run `tests/integration/extension-selection/install-wizard.sh` and `tests/integration/extension-selection/config-panel.sh` against a DS920+ to automate regression checks.
6. Validate that `/var/packages/php83/source/php-8.3.28.tar.gz` exists on the NAS (ensuring the source bundle shipped with the package).

## Troubleshooting

- If the wizard page does not appear, verify `INFO` contains `wizard_install_pages` referencing the shipped JSON definition.  
- If changes are not persisted, confirm `/var/packages/php83/conf/extension_selection.json` is writable by the package service account.  
- When toggles hang, inspect `synopkg check` and service logs for restart failures or missing dependencies.
