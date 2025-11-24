# Feature Specification: PHP 8.3.28 Update

**Feature Branch**: `002-php-update-8-3-28`
**Created**: 2025-11-23
**Status**: Draft
**Input**: User description: "maintenant mets à jour PHP et ses extensions en version 8.3.28"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Core PHP Runtime Update (Priority: P1)

As a DS920+ administrator, I need to update my PHP runtime from 8.3.8 to 8.3.28 to benefit from security fixes, bug patches, and performance improvements released by the PHP project.

**Why this priority**: This is the core of the update - the PHP runtime itself. Without this, the package doesn't deliver its primary value of providing the latest stable PHP version. Security patches are critical for production environments.

**Independent Test**: Install the updated SPK on a DS920+ with the current PHP 8.3.8 package and verify that `php -v` reports version 8.3.28. Check that Web Station profiles using PHP 8.3 continue to work without reconfiguration.

**Acceptance Scenarios**:

1. **Given** a DS920+ running PHP 8.3.8, **When** the administrator upgrades to the new package, **Then** PHP CLI reports version 8.3.28 and all previously enabled extensions remain functional
2. **Given** Web Station sites using PHP 8.3.8 profiles, **When** the package is upgraded, **Then** all sites continue serving requests without downtime or configuration changes
3. **Given** custom php.ini modifications, **When** the upgrade completes, **Then** user customizations are preserved and not overwritten

---

### User Story 2 - Extension Compatibility Update (Priority: P1)

As a DS920+ administrator, I need all bundled PHP extensions (curl, gd, mbstring, mysqli, opcache, etc.) to be recompiled against PHP 8.3.28 to maintain full compatibility with the updated runtime.

**Why this priority**: Extensions compiled for 8.3.8 may not load correctly with 8.3.28 due to ABI changes or API updates. This is P1 because without working extensions, core functionality (database access, image processing, web services) breaks.

**Independent Test**: After installation, run `php -m` to list loaded modules and verify all previously available extensions load successfully. Test a Web Station site that uses mysqli, curl, and gd to confirm functionality.

**Acceptance Scenarios**:

1. **Given** a site using mysqli extension, **When** PHP 8.3.28 is installed, **Then** database connections work without errors
2. **Given** a site using gd for image processing, **When** PHP 8.3.28 is installed, **Then** image manipulation functions execute successfully
3. **Given** the extension selection configuration, **When** PHP is upgraded, **Then** only extensions that were previously enabled remain enabled

---

### User Story 3 - Package Metadata Update (Priority: P2)

As a DS920+ administrator viewing the Package Center, I need the package to display accurate version information (8.3.28-0XXX) so I can track which version is installed and confirm the update succeeded.

**Why this priority**: This is P2 because it doesn't affect functionality, but it's essential for maintenance and support. Users need to verify the update was successful and troubleshoot issues based on version numbers.

**Independent Test**: Check Package Center UI and verify the displayed version is 8.3.28-0XXX. Run `synopkg version php83` via SSH and confirm it returns the correct version string.

**Acceptance Scenarios**:

1. **Given** Package Center is open, **When** viewing the PHP 8.3 package details, **Then** the version field shows 8.3.28-0XXX
2. **Given** command-line access, **When** running `synopkg version php83`, **Then** the output displays 8.3.28-0XXX
3. **Given** installation logs, **When** reviewing `/var/log/packages/php83.log`, **Then** the version 8.3.28 is clearly logged

---

### User Story 4 - Documentation and Build Artifacts Update (Priority: P3)

As a developer maintaining this package, I need all documentation, build scripts, and README files to reference version 8.3.28 to avoid confusion and ensure reproducible builds.

**Why this priority**: This is P3 because it doesn't affect end-user functionality, but it's important for maintainability and future development. Outdated version references cause confusion during troubleshooting.

**Independent Test**: Search the repository for "8.3.8" and verify all relevant files reference 8.3.28 instead. Run the build script and confirm generated artifacts use the correct version number.

**Acceptance Scenarios**:

1. **Given** the project repository, **When** searching for version references, **Then** no outdated "8.3.8" references remain in active code/configs
2. **Given** the build script, **When** executed, **Then** it generates an SPK named `php83_8.3.28-0XXX_geminilake.spk`
3. **Given** CLAUDE.md documentation, **When** developers read it, **Then** all examples and instructions reference 8.3.28

---

### Edge Cases

- **Upgrade from 8.3.x to 8.3.28**: Does the postinst script handle version upgrades gracefully without recreating existing configurations?
- **Rollback scenario**: If the upgrade fails, can users reinstall 8.3.8 without losing Web Station profiles or extension configurations?
- **Binary compatibility**: Are all shared libraries (libcrypto, libssl, libxml2) compatible with the Geminilake architecture and DSM 7.x?
- **Extension API changes**: Does PHP 8.3.28 introduce any breaking changes in extension APIs that require code modifications beyond recompilation?
- **Concurrent Web Station usage**: If a site is actively processing requests during upgrade, does PHP-FPM restart gracefully without dropping connections?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST update PHP CLI binary from version 8.3.8 to 8.3.28
- **FR-002**: System MUST update PHP-FPM binary from version 8.3.8 to 8.3.28
- **FR-003**: System MUST recompile all bundled extensions against PHP 8.3.28 API (Zend API 20230831)
- **FR-004**: System MUST preserve user-modified php.ini settings during upgrade
- **FR-005**: System MUST preserve extension selection configuration (`extension_selection.json`) during upgrade
- **FR-006**: System MUST update package metadata (INFO file) to reflect version 8.3.28-0XXX
- **FR-007**: System MUST maintain backward compatibility with existing Web Station profiles configured for "PHP 8.3"
- **FR-008**: System MUST restart PHP-FPM service after upgrade to load the new binaries
- **FR-009**: System MUST log the upgrade process to `/var/log/php83-install.log` with version details
- **FR-010**: System MUST validate that PHP binaries are executable and compatible with Geminilake architecture
- **FR-011**: Build system MUST generate SPK with filename pattern `php83_8.3.28-0XXX_geminilake.spk`
- **FR-012**: Build system MUST update internal version references in build scripts and INFO file
- **FR-013**: System MUST verify extension compatibility during postinst (test load with `php -m`)
- **FR-014**: System MUST preserve existing unix socket path (`/var/packages/php83/var/run/php-fpm.sock`)
- **FR-015**: System MUST maintain file ownership (http:http) and permissions after upgrade

### Key Entities

- **PHP Runtime**: Core interpreter and runtime environment, updated to version 8.3.28, includes CLI and FPM binaries
- **PHP Extensions**: Compiled shared objects (.so files) providing additional functionality (curl, gd, mbstring, mysqli, opcache, etc.), must match Zend API 20230831
- **Package Metadata**: INFO file, build scripts, and configuration files containing version numbers (8.3.28-0XXX)
- **User Configuration**: php.ini modifications and extension_selection.json that persist across upgrades
- **Web Station Integration**: Backend configuration (backend-php83.json) and profile registry ensuring continuity with version label "PHP 8.3"

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: PHP CLI command returns version 8.3.28 when queried with `php -v`
- **SC-002**: PHP-FPM process runs version 8.3.28 as verified by `ps aux | grep php-fpm`
- **SC-003**: All previously functional extensions load successfully (verified by comparing `php -m` output before and after upgrade)
- **SC-004**: Web Station sites using PHP 8.3 profiles continue serving requests with zero downtime beyond the PHP-FPM restart (under 2 seconds)
- **SC-005**: Package Center displays version 8.3.28-0XXX in the UI
- **SC-006**: Installation completes without errors in `/var/log/packages/php83.log`
- **SC-007**: Generated SPK file follows naming convention `php83_8.3.28-0XXX_geminilake.spk`
- **SC-008**: Build process completes successfully using the updated build scripts
- **SC-009**: Upgrade preserves at least 95% of existing php.ini customizations
- **SC-010**: Extension configuration remains intact (same extensions enabled before and after upgrade)

## Dependencies *(mandatory)*

### External Dependencies

- **spksrc Toolchain**: Required to cross-compile PHP 8.3.28 for Geminilake (Intel Celeron J4125)
- **PHP 8.3.28 Source**: Official PHP source tarball from php.net
- **Extension Libraries**: OpenSSL 1.1+, libxml2, libpng, libjpeg, libcurl, libmysqlclient compatible with Geminilake
- **DSM 7.x**: Target platform must be running DSM 7.0-40000 or higher
- **DS920+ Hardware**: Geminilake architecture (or compatible models)

### Internal Dependencies

- **Existing Installation**: Assumes PHP 8.3.8 package is currently installed (upgrade scenario)
- **Extension Management System**: Relies on the feature implemented in branch 001-extension-selection
- **Web Station Package**: PHP integration depends on Web Station being installed

## Assumptions *(mandatory)*

1. **Upstream Compatibility**: PHP 8.3.28 is backward compatible with 8.3.8 at the source level (no major API breaks)
2. **ABI Stability**: Zend API version remains 20230831 (same as 8.3.8), allowing extension recompilation without code changes
3. **Build Environment**: Developer has access to spksrc toolchain configured for Geminilake cross-compilation
4. **Testing Environment**: DS920+ (or equivalent Geminilake device) is available for integration testing
5. **Version Numbering**: Package build number increments sequentially (0018 → 0019 or similar)
6. **Extension Source Compatibility**: All bundled extensions (curl, gd, mbstring, mysqli, opcache, etc.) have versions compatible with PHP 8.3.28
7. **No Major Configuration Changes**: PHP 8.3.28 doesn't introduce breaking changes to php.ini directives used in default configuration
8. **Upgrade Path**: Users can upgrade directly from 8.3.8 without uninstalling first (DSM package upgrade mechanism works)
9. **Backward Compatibility**: Web Station continues to recognize "PHP 8.3" as a valid profile type (no DSM API changes)
10. **Build Process**: Existing build scripts (`scripts/build-spk.sh`) work with minimal modifications (only version number changes)

## Constraints *(mandatory)*

### Technical Constraints

- **Architecture**: Geminilake only (x86_64 Intel Celeron J4125)
- **DSM Version**: DSM 7.0-40000 minimum
- **PHP Version**: Must be 8.3.28 exactly (not 8.3.29 or 8.4.x)
- **Zend API**: Extensions must target Zend API 20230831
- **Socket Path**: Must preserve `/var/packages/php83/var/run/php-fpm.sock`
- **Service User**: Must run as http:http (DSM standard web user)
- **Package Name**: Must remain "php83" (not "php8328")

### Business Constraints

- **Testing Requirement**: Must be tested on physical DS920+ before release
- **Reproducibility**: Build must be reproducible using documented spksrc commands
- **Documentation**: Must update CLAUDE.md with new version references
- **Backward Compatibility**: Must not break existing Web Station sites

### Resource Constraints

- **Build Time**: Cross-compilation typically takes 30-60 minutes on standard development machine
- **Disk Space**: Build artifacts and intermediate files require approximately 500MB during compilation
- **Target Storage**: Installed package footprint must remain under 80MB with all extensions

## Out of Scope *(mandatory)*

The following are explicitly NOT included in this update:

1. **Major Version Upgrade**: Upgrading to PHP 8.4.x or PHP 9.0 (different major/minor versions)
2. **New Extension Addition**: Adding extensions not present in 8.3.8 package
3. **Configuration Changes**: Modifying default php.ini settings beyond what upstream PHP 8.3.28 changed
4. **Architecture Expansion**: Adding support for other Synology architectures (apollolake, broadwell, etc.)
5. **DSM 6.x Support**: Backporting to DSM 6.x
6. **Performance Tuning**: OPcache, FPM worker, or memory limit adjustments
7. **Feature Additions**: New wizard steps, UI enhancements, or management tools
8. **Extension Configuration**: Changes to extension manifest (`extensions.json`)
9. **Web Station Integration Changes**: Modifications to backend registration or profile creation
10. **Migration Tools**: Scripts to migrate from PHP 7.x or other PHP packages

## Risks & Mitigations

### Risk 1: Extension Compilation Failure

**Description**: Some extensions may fail to compile against PHP 8.3.28 due to API changes or deprecated functions.

**Impact**: High - users lose functionality (database access, image processing, etc.)

**Likelihood**: Medium - PHP maintains API stability in patch releases, but edge cases exist

**Mitigation**:
- Test compile all extensions during build process
- Review PHP 8.3.28 changelog for extension-affecting changes
- Have fallback plan to exclude problematic extensions and document them

### Risk 2: Web Station Profile Breakage

**Description**: DSM may not recognize the updated package as compatible with existing "PHP 8.3" profiles.

**Impact**: High - all existing sites stop working until profiles are recreated

**Likelihood**: Low - package name and backend config remain unchanged

**Mitigation**:
- Test profile continuity on staging NAS before release
- Document profile recreation procedure as contingency
- Preserve `backend-php83.json` structure exactly

### Risk 3: User Configuration Loss

**Description**: Upgrade process may overwrite user-modified php.ini or extension selections.

**Impact**: Medium - requires manual reconfiguration after upgrade

**Likelihood**: Medium - depends on DSM upgrade behavior and postinst script logic

**Mitigation**:
- Test upgrade path specifically (not just fresh install)
- Use DSM's `support_conf_folder="yes"` to preserve `/var/packages/php83/conf/`
- Document backup procedure in upgrade notes

### Risk 4: Binary Incompatibility

**Description**: Compiled binaries may not work on all Geminilake devices or DSM 7.x versions.

**Impact**: Critical - package won't install or PHP won't start

**Likelihood**: Low - using spksrc standard toolchain

**Mitigation**:
- Test on DS920+ running both DSM 7.0 and 7.2
- Use spksrc's proven toolchain configuration
- Verify RPATH fixes for shared library loading

## Notes

- PHP 8.3.28 was released in November 2024 as part of the PHP 8.3 stable series
- This is a patch-level update (8.3.8 → 8.3.28), not a minor or major version change
- All changes should be binary-compatible (no source code modifications needed for extensions)
- Package build number will increment (0012 → 0013 or similar) to reflect the update
- Focus is on updating version numbers and recompiling binaries, not adding features
