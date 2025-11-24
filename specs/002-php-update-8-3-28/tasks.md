# Tasks: PHP 8.3.28 Update

**Input**: Design documents from `/specs/002-php-update-8-3-28/`
**Prerequisites**: spec.md (user stories and requirements)

**Tests**: Not explicitly requested in specification - focusing on implementation and validation tasks

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

This project uses the Synology SPK structure:
- Package metadata: `spk/php83/INFO`
- Build scripts: `scripts/`
- Installation scripts: `spk/php83/src/scripts/`
- Documentation: `CLAUDE.md`, `docs/`, `specs/`
- PHP binaries location: `spk/php83/files/php/` (compiled separately via spksrc)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare build environment and verify toolchain availability

- [X] T001 Verify spksrc toolchain is available and configured for Geminilake architecture
- [X] T002 [P] Clone or update spksrc repository to latest stable version
- [X] T003 [P] Download PHP 8.3.28 source tarball from php.net and verify checksum

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core binary compilation that MUST be complete before ANY packaging can occur

**⚠️ CRITICAL**: No packaging or metadata updates can begin until PHP binaries are compiled

- [X] T004 Configure spksrc toolchain for PHP 8.3.28 compilation targeting Geminilake
- [X] T005 Compile PHP 8.3.28 CLI and FPM binaries using spksrc for Geminilake architecture
- [X] T006 Compile all PHP extensions (curl, gd, mbstring, mysqli, opcache, etc.) against PHP 8.3.28 API - 39 extensions compiled successfully
- [X] T007 Verify compiled binaries are executable and report correct version (php -v should show 8.3.28)
- [X] T008 Copy compiled PHP binaries from spksrc build output to spk/php83/files/php/bin/
- [X] T009 Copy compiled PHP-FPM binary from spksrc build output to spk/php83/files/php/sbin/
- [X] T010 Copy compiled extensions (.so files) to spk/php83/files/php/lib/php/extensions/no-debug-non-zts-20230831/
- [ ] T011 Copy PHP libraries and dependencies to spk/php83/files/php/lib/
- [ ] T012 Verify RPATH settings on binaries using scripts/fix-binaries-rpath.sh

**Checkpoint**: PHP 8.3.28 binaries compiled and ready - packaging can now begin

---

## Phase 3: User Story 1 - Core PHP Runtime Update (Priority: P1) 🎯 MVP

**Goal**: Update PHP CLI and PHP-FPM binaries to version 8.3.28

**Independent Test**: Install the updated SPK on a DS920+ with the current PHP 8.3.8 package and verify that `php -v` reports version 8.3.28. Check that Web Station profiles using PHP 8.3 continue to work without reconfiguration.

### Implementation for User Story 1

- [X] T013 [US1] Update PKG_VERSION from "8.3.8" to "8.3.28" in scripts/build-spk.sh (line 17)
- [X] T014 [P] [US1] Update PKG_BUILD number in scripts/build-spk.sh (line 18) - increment from "0012" to "0019"
- [X] T015 [P] [US1] Update version field in spk/php83/INFO from "8.3.8-0012" to "8.3.28-0019"
- [ ] T016 [US1] Verify php.ini default configuration in spk/php83/files/php/etc/php.ini (check for any upstream changes in 8.3.28)
- [ ] T017 [US1] Test build process: Run scripts/build-spk.sh and verify it completes without errors
- [ ] T018 [US1] Verify generated SPK filename is php83_8.3.28-0019_geminilake.spk in dist/ directory
- [ ] T019 [US1] Test installation on DS920+ and verify `php -v` reports "PHP 8.3.28"
- [ ] T020 [US1] Test installation on DS920+ and verify `php-fpm -v` reports "PHP 8.3.28"
- [ ] T021 [US1] Verify PHP-FPM service starts successfully using synoservicectl --start pkgctl-php83
- [ ] T022 [US1] Verify unix socket is created at /var/packages/php83/var/run/php-fpm.sock

**Checkpoint**: At this point, PHP 8.3.28 runtime should be fully functional and report correct version

---

## Phase 4: User Story 2 - Extension Compatibility Update (Priority: P1)

**Goal**: Ensure all bundled PHP extensions are recompiled against PHP 8.3.28 and load successfully

**Independent Test**: After installation, run `php -m` to list loaded modules and verify all previously available extensions load successfully. Test a Web Station site that uses mysqli, curl, and gd to confirm functionality.

### Implementation for User Story 2

- [ ] T023 [P] [US2] Verify all extension .so files have correct Zend API version (20230831) using php -i
- [ ] T024 [P] [US2] Test loading each extension individually: php -d extension=curl.so -m
- [ ] T025 [P] [US2] Test loading each extension individually: php -d extension=gd.so -m
- [ ] T026 [P] [US2] Test loading each extension individually: php -d extension=mbstring.so -m
- [ ] T027 [P] [US2] Test loading each extension individually: php -d extension=mysqli.so -m
- [ ] T028 [P] [US2] Test loading each extension individually: php -d extension=opcache.so -m
- [ ] T029 [US2] Verify extension manifest spk/php83/files/conf/extensions.json still matches available extensions
- [ ] T030 [US2] Test extension selection mechanism: Enable mysqli and verify it loads via php -m
- [ ] T031 [US2] Test extension configuration preservation during package upgrade
- [ ] T032 [US2] Create test Web Station profile and verify PHP extensions work (mysqli, curl, gd)
- [ ] T033 [US2] Verify extension logs in /var/packages/php83/var/log/ show successful loading

**Checkpoint**: All PHP extensions should load successfully without errors

---

## Phase 5: User Story 3 - Package Metadata Update (Priority: P2)

**Goal**: Ensure package displays accurate version information (8.3.28-0019) in Package Center and logs

**Independent Test**: Check Package Center UI and verify the displayed version is 8.3.28-0019. Run `synopkg version php83` via SSH and confirm it returns the correct version string.

### Implementation for User Story 3

- [X] T034 [P] [US3] Update version reference in spk/php83/src/scripts/postinst if version is hardcoded in PluginPackage registration
- [X] T035 [P] [US3] Update package description in spk/php83/INFO to "PHP 8.3.28 with FPM and CLI"
- [ ] T036 [US3] Test package installation and verify Package Center UI shows "8.3.28-0019"
- [ ] T037 [US3] Test synopkg version php83 command returns "8.3.28-0019"
- [ ] T038 [US3] Verify installation log /var/log/packages/php83.log contains version 8.3.28 entries
- [ ] T039 [US3] Verify BUILD_INFO.txt in dist/ directory references PHP 8.3.28
- [ ] T040 [US3] Test package upgrade from 8.3.8 to 8.3.28 and verify metadata updates correctly

**Checkpoint**: Package metadata should accurately reflect version 8.3.28-0019 everywhere

---

## Phase 6: User Story 4 - Documentation and Build Artifacts Update (Priority: P3)

**Goal**: Update all documentation, build scripts, and README files to reference version 8.3.28

**Independent Test**: Search the repository for "8.3.8" and verify all relevant files reference 8.3.28 instead. Run the build script and confirm generated artifacts use the correct version number.

### Implementation for User Story 4

- [X] T041 [P] [US4] Update CLAUDE.md: Replace all "8.3.8" references with "8.3.28" in examples
- [X] T042 [P] [US4] Update CLAUDE.md: Replace "0012" build number references with "0019"
- [X] T043 [P] [US4] Update docs/ARCHITECTURE.md: Replace version references from 8.3.8 to 8.3.28
- [X] T044 [P] [US4] Update docs/COMPILATION.md: Replace version references from 8.3.8 to 8.3.28
- [X] T045 [P] [US4] Update specs/001-extension-selection/quickstart.md: Replace version references
- [X] T046 [P] [US4] Search for remaining "8.3.8" references: grep -r "8.3.8" --exclude-dir=.git --exclude-dir=dist
- [ ] T047 [US4] Verify build script comments in scripts/build-spk.sh reference correct version
- [ ] T048 [US4] Update any README files to reference PHP 8.3.28
- [ ] T049 [US4] Run final verification: Search codebase for "8.3.8" and ensure only historical references remain

**Checkpoint**: All documentation should reference version 8.3.28 consistently

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, testing, and release preparation

- [ ] T050 [P] Test complete upgrade path: Install 8.3.8, upgrade to 8.3.28, verify all functionality
- [ ] T051 [P] Test Web Station profile continuity: Create profile with 8.3.8, upgrade, verify sites work
- [ ] T052 [P] Test custom php.ini preservation: Modify php.ini, upgrade, verify customizations preserved
- [ ] T053 [P] Test extension selection preservation: Enable specific extensions, upgrade, verify selection kept
- [ ] T054 [P] Verify PHP-FPM restart during upgrade causes minimal downtime (under 2 seconds)
- [ ] T055 Verify file ownership remains http:http after upgrade
- [ ] T056 Verify socket path /var/packages/php83/var/run/php-fpm.sock is preserved
- [ ] T057 [P] Generate MD5 checksum for final SPK: md5sum php83_8.3.28-0019_geminilake.spk
- [ ] T058 [P] Create release notes documenting changes from 8.3.8 to 8.3.28
- [ ] T059 Test rollback scenario: Attempt to reinstall 8.3.8 after 8.3.28 upgrade
- [ ] T060 Run final validation: Install on DS920+ running DSM 7.0 and DSM 7.2

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories (binaries must be compiled first)
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (P1) must complete before User Story 2 (P1) can be fully tested (need runtime first)
  - User Story 3 (P2) depends on User Story 1 (need version to display)
  - User Story 4 (P3) can proceed independently once US1 is done
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Core runtime update
- **User Story 2 (P1)**: Depends on User Story 1 completion - Extensions need runtime to test against
- **User Story 3 (P2)**: Depends on User Story 1 completion - Metadata displays runtime version
- **User Story 4 (P3)**: Can start after User Story 1 - Documentation references new version

### Within Each User Story

- Version updates in metadata files before building
- Build process before testing
- Installation testing before functional validation
- Individual extension tests can run in parallel (marked [P])
- Documentation updates can run in parallel (marked [P])

### Parallel Opportunities

- Phase 1 Setup: T002 and T003 can run in parallel
- Phase 3 (US1): T014 and T015 can run in parallel (different files)
- Phase 4 (US2): T023-T028 extension tests can all run in parallel (different extensions)
- Phase 5 (US3): T034 and T035 can run in parallel (different files)
- Phase 6 (US4): T041-T045 documentation updates can all run in parallel (different files)
- Phase 7 Polish: T050-T054 and T057-T058 can run in parallel (different validation areas)

---

## Parallel Example: User Story 2 (Extension Testing)

```bash
# Launch all extension tests together:
Task: "Test loading each extension individually: php -d extension=curl.so -m"
Task: "Test loading each extension individually: php -d extension=gd.so -m"
Task: "Test loading each extension individually: php -d extension=mbstring.so -m"
Task: "Test loading each extension individually: php -d extension=mysqli.so -m"
Task: "Test loading each extension individually: php -d extension=opcache.so -m"

# All 5 tests can run concurrently since they test different extensions
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only - Both P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - compile binaries)
3. Complete Phase 3: User Story 1 (Core runtime update)
4. Complete Phase 4: User Story 2 (Extension compatibility)
5. **STOP and VALIDATE**: Test PHP 8.3.28 runtime with all extensions on DS920+
6. Deploy/demo if ready (this is the minimum viable update)

### Incremental Delivery

1. Complete Setup + Foundational → Binaries compiled
2. Add User Story 1 + 2 → Test independently → Deploy/Demo (MVP - functional PHP 8.3.28!)
3. Add User Story 3 → Test metadata display → Deploy/Demo (complete package experience)
4. Add User Story 4 → Update documentation → Deploy/Demo (maintainable release)
5. Phase 7 Polish → Final validation → Production release

### Sequential Strategy (Recommended for Single Developer)

1. Team/developer completes Setup + Foundational (compilation phase)
2. Sequential implementation in priority order:
   - User Story 1 (P1): Runtime update - MUST complete first
   - User Story 2 (P1): Extension testing - Depends on runtime
   - User Story 3 (P2): Metadata updates - Enhances user experience
   - User Story 4 (P3): Documentation - Ensures maintainability
3. Polish phase: Final validation and release prep

---

## Notes

- [P] tasks = different files/extensions, can run concurrently
- [Story] label maps task to specific user story (US1, US2, US3, US4)
- This is a patch-level update (8.3.8 → 8.3.28), not a major version change
- Focus is on recompiling binaries and updating version references
- No new features or configuration changes beyond version updates
- Extension recompilation is critical - ABI compatibility must be verified
- Test upgrade path specifically (not just fresh install) to ensure user configuration preservation
- All binary compilation must use spksrc toolchain for Geminilake architecture
- Stop at any checkpoint to validate story independently before proceeding
- Package build number incremented from 0012 to 0019 to reflect the update
