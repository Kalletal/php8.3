# PHP 8.3 Synology Package Constitution

## Core Principles

### I. Upstream Parity
Match official PHP 8.3 releases (security patches, default extensions, INI defaults) so Synology users get the same behavior as Linux distributions without DSM-specific surprises.

### II. Reproducible spksrc Builds
Every build must come from spksrc recipes, pinned toolchains, and checksum-verified sources to guarantee deterministic artifacts and easy rebuilds across Gemini Lake Synology models.

### III. Synology-first Integration
Ensure the package plugs cleanly into DSM 7 services: Systemd-style start scripts, Web Station compatibility, proper `/var/services/web` integration, and DSM UI metadata tuned for Gemini Lake hardware limits.

### IV. Test & Validate on Target
Run PHP’s test suite (or a curated subset) within the cross-built environment and confirm startup, CLI, FPM, and extension loading directly on a DS920+ (Gemini Lake) before release.

### V. Documentation & Supportability
Document build steps, DSM-specific tweaks, extension availability, and upgrade paths so future maintainers—and end users installing the SPK—understand Gemini Lake constraints and recovery steps.

## Platform & Compliance Constraints

- Target hardware: Synology DS920+ (Intel Celeron J4125, Gemini Lake) running DSM 7.x.
- Toolchain: spksrc native for DSM 7, cross toolchain `geminilake` unless override justified.
- Deliverables: SPK with PHP CLI, FPM, required extensions (curl, openssl, zip, intl, gd, pdo_mysql, sqlite) and sane defaults for Synology paths.
- Security: ship upstream security fixes quickly; disable insecure defaults; ensure OpenSSL links against DSM-provided libraries.
- Performance: enable opcache by default with memory tuned for 4+ GB systems, but configurable to lower footprints.

## Development Workflow

- Use feature branches per PHP minor/patch update; keep `master` deployable.
- Before merge: verify spksrc `make arch-geminilake-7.2` succeeds locally, run smoke tests on extracted package, and document results.
- Tag releases with `php8.3-vX.Y.Z` and attach generated SPK + checksum.
- Any DSM-specific patch requires an upstream issue reference or rationale, plus removal plan once upstream resolves.

## Governance

- Constitution overrides ad-hoc decisions; deviations require a recorded ADR and maintainer approval.
- All PRs must confirm adherence to the principles, platform constraints, and workflow steps.
- Amendments require consensus from active maintainers and documentation in `docs/CHANGELOG.md`.

**Version**: 1.0.0 | **Ratified**: 2024-06-05 | **Last Amended**: 2024-06-05
