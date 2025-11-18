# Tasks: PHP Extension Selection Controls

**Input**: Design documents from `/specs/001-extension-selection/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Integration smoke tests are included where needed to satisfy Principle IV (Test & Validate on Target).

**Organization**: Tasks are grouped by user story priority so each story can be developed and tested independently.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish repository structure and configuration files referenced by all user stories.

- [x] T001 Create feature directories per plan (`spk/php83/src/install-wizard/`, `spk/php83/src/config-panel/`, `spk/php83/src/scripts/`, `spk/php83/files/ui/`) with placeholder README.md files.
- [x] T002 Seed default extension profile template in `spk/php83/files/conf/extension_selection.json.sample` reflecting data-model fields (selected, pending, metadata).
- [x] T003 Create test harness folders `tests/integration/extension-selection/` and `tests/unit/extension-selection/` with README describing DS920+ execution workflow.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure shared by all stories; must be complete before UI or API work begins.

- [x] T004 Update `spk/php83/Makefile` to declare `EXTENSION_OPTIONS` manifest, bundle wizard assets via `WIZARD_UIFILES`, and install the default JSON config into `/var/packages/php83/conf/`.
- [x] T005 Implement shared config helper `spk/php83/src/scripts/extension_config.sh` to load/save `extension_selection.json`, maintain `.bak`, and expose dependency/conflict lookup utilities.
- [x] T006 Implement apply pipeline `spk/php83/src/scripts/apply_extensions.sh` that regenerates PHP INI fragments, runs `php -m` verification, and queues `php-fpm`/CLI restarts.
- [x] T007 Add audit logging utility `spk/php83/files/bin/log-extension-event.sh` plus log rotation entry in `spk/php83/conf/logrotate.d/php83-extension-selection`.

**Checkpoint**: Foundational scripts and manifest plumbing ready.

---

## Phase 3: User Story 1 – Guided install selection (Priority: P1) 🎯 MVP

**Goal**: Allow admins to choose compatible PHP extensions during the Package Center wizard and have those selections applied automatically.

**Independent Test**: Run `synopkg install` on DS920+, toggle several extensions (including dependency scenarios), and confirm `php -m` plus generated INI files match selections immediately after install.

### Implementation

- [x] T008 [US1] Build wizard page definition `spk/php83/src/install-wizard/extension-selection.json` and localized strings presenting extension names, descriptions, and dependency hints pulled from `EXTENSION_OPTIONS`.
- [x] T009 [US1] Implement wizard logic `spk/php83/src/install-wizard/extension-selection.js` to handle checkbox state, auto-select dependencies, and block incompatible combinations.
- [x] T010 [US1] Capture wizard selections in `spk/php83/src/scripts/preinst` (reading `wizard_<var>` values) and persist to `/var/packages/php83/conf/extension_selection.json`.
- [x] T011 [US1] Apply selections post-install in `spk/php83/src/scripts/postinst` and `spk/php83/src/scripts/service-setup` by invoking `apply_extensions.sh` with the stored profile before services start.
- [x] T012 [US1] Add install-time integration test `tests/integration/extension-selection/install-wizard.sh` that automates `synopkg install`, edits wizard variables, and asserts resulting `php -m` list.

**Checkpoint**: Installation wizard delivers configured PHP instance without post-install steps.

---

## Phase 4: User Story 2 – Post-install configuration panel (Priority: P2)

**Goal**: Provide a DSM configuration panel to review and toggle extensions after installation using the documented REST API.

**Independent Test**: From DSM UI, change multiple extensions via the new panel, apply, and verify `php -m` and the stored profile update together with success/failure messaging.

### Implementation

- [x] T013 [US2] Implement local REST handler `spk/php83/src/scripts/extension_api.cgi` fulfilling `/options`, `/profile`, and `/apply` (per `contracts/extension-config.openapi.yaml`) backed by `extension_config.sh`.
- [x] T014 [US2] Register the API endpoint with DSM by updating `spk/php83/conf/resource.conf` (or equivalent) and routing HTTPS requests from DSM Control Panel to `extension_api.cgi`.
- [x] T015 [US2] Build ExtJS control panel client `spk/php83/src/config-panel/extension-panel.js` listing extensions, showing status, and batching enable/disable toggles.
- [x] T016 [US2] Wire control panel into the package by adding panel metadata to `spk/php83/INFO`, bundling static assets under `spk/php83/files/ui/`, and ensuring ACLs limit access to package admins.
- [x] T017 [US2] Add DSM automation test `tests/integration/extension-selection/config-panel.sh` that calls the REST endpoints (via curl or DSM proxy) to simulate UI actions and verify responses.

**Checkpoint**: Administrators can manage extensions post-install entirely through DSM UI.

---

## Phase 5: User Story 3 – Safe operations & visibility (Priority: P3)

**Goal**: Surface dependency/conflict warnings, disk usage impact, restart messaging, and audit logs so admins can make informed decisions.

**Independent Test**: Attempt conflicting or disk-heavy extensions; confirm UI blocks unsafe actions, logs details, and communicates restart expectations.

### Implementation

- [x] T018 [US3] Extend `spk/php83/src/scripts/extension_config.sh` to calculate disk footprint, detect conflicts/dependencies, and return structured warnings consumed by both wizard and API.
- [x] T019 [US3] Display warnings/restart notices in `spk/php83/src/install-wizard/extension-selection.js` (e.g., modal confirmation before enabling heavy/conflicting modules).
- [x] T020 [US3] Surface the same warnings plus impact badges in `spk/php83/src/config-panel/extension-panel.js`, blocking Apply when violations remain.
- [x] T021 [US3] Hook `log-extension-event.sh` into `apply_extensions.sh` and REST responses, then document log location/format in `spk/php83/files/conf/extension_selection.json.sample` comments for support teams.

**Checkpoint**: Safety checks and observability meet governance expectations.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final refinements spanning multiple stories.

- [x] T022 Update developer docs (`specs/001-extension-selection/quickstart.md` and repository README if present) with wizard screenshot steps, API usage, and testing commands.
- [ ] T023 Perform end-to-end verification on DS920+ (install + UI toggles + log review) and capture release notes in `spk/php83/INFO` + change summary for package upload.

---

## Phase 7: PHP Source Integration

**Purpose**: Ensure official PHP 8.3 sources are downloaded, verified, and packaged inside the SPK.

- [x] T024 Create download helper `spk/php83/scripts/download-php-source.sh` that fetches php-8.3.x tarball and verifies SHA-256.
- [x] T025 Run helper to cache sources under `spk/php83/files/php-src/php-8.3.x.tar.gz` for inclusion in the SPK.
- [x] T026 Update `spk/php83/Makefile` (and install scripts if needed) so the tarball ships to `/var/packages/php83/source/` inside the package.
- [x] T027 Document the workflow in `specs/001-extension-selection/quickstart.md` (build + verification steps referencing the new script).

## Dependencies & Execution Order

- **Setup → Foundational**: T001–T003 must complete before manifest/scripts in T004–T007.
- **Foundational → User Stories**: T004–T007 block all user stories because wizard/UI reuse these scripts.
- **User Story Order**: US1 (Phase 3) delivers MVP and must finish before US2 (Phase 4) and US3 (Phase 5), though US2 and US3 can run in parallel once US1 establishes config persistence.
- **Polish**: T022–T023 run after desired user stories are complete.

## Parallel Execution Examples

- After Foundational tasks, T015 (UI build) and T013 (API backend) can progress in parallel because they touch different folders (`src/config-panel/` vs `src/scripts/`).  
- Within US1, T008 (JSON layout) and T009 (JS behavior) can be split between engineers once shared data formats are defined.  
- In US3, T019 (wizard warnings) and T020 (panel warnings) can run concurrently since they modify separate UI files.

## Implementation Strategy (MVP-first)

1. **MVP**: Complete Phases 1–3 so installers can choose extensions during installation. This satisfies baseline requirement and unlocks early testing on hardware.  
2. **Increment 2**: Deliver Phase 4 to support day-2 management via DSM UI.  
3. **Increment 3**: Ship Phase 5 safety enhancements plus Phase 6 polish/logging updates to lower operational risk.  
4. **Testing cadence**: After each increment, rerun integration scripts on DS920+ to ensure constitution Principle IV compliance.
