# Feature Specification: PHP Extension Selection Controls

**Feature Branch**: `001-extension-selection`  
**Created**: 2025-11-13  
**Status**: Draft  
**Input**: User description: "Je veux que lutilisateur puisse choisir les extensions à activer lors de linstallation de php 8.3, et quil puisse le faire également, après linstallation, dans une interface de configuration."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Guided install selection (Priority: P1)

As a Synology administrator installing the PHP 8.3 package, I can browse a catalog of available extensions, read brief descriptions/dependencies, and toggle which ones should be installed and enabled before the package finishes installing.

**Why this priority**: Extension selection during installation prevents rework and ensures the package is usable immediately after deployment.

**Independent Test**: Start the package installation wizard, select varying extension combinations (including defaults), and confirm the resulting package has the correct extensions enabled without needing the post-install UI.

**Acceptance Scenarios**:

1. **Given** the installation wizard is at the extension step, **When** the admin toggles an extension that is compatible with the target platform, **Then** the summary confirms it will be installed and enabled.
2. **Given** an extension requires another module, **When** the admin selects it, **Then** the UI automatically selects or prompts to enable the dependency before allowing the wizard to continue.

---

### User Story 2 - Post-install configuration panel (Priority: P2)

As the same administrator, I can open a DSM configuration interface after installation to review which extensions are active, change their status, and apply the changes without reinstalling the package.

**Why this priority**: Day-2 operations require flexibility to enable new functionality or disable unused modules as workloads evolve.

**Independent Test**: From DSM, open the configuration panel, adjust extension toggles, apply, and verify PHP CLI/FPM report the updated extension set.

**Acceptance Scenarios**:

1. **Given** PHP 8.3 is already installed, **When** the admin toggles an extension in the configuration UI and confirms, **Then** the system applies the change (including restart if necessary) and displays success or actionable failure feedback.
2. **Given** multiple extensions are changed at once, **When** the admin saves, **Then** the UI batches the updates, reports which ones succeeded, and highlights any that failed.

---

### User Story 3 - Safe operations & visibility (Priority: P3)

As an administrator managing production workloads, I want to see the impact of each extension change (disk footprint, required restarts, conflicts) so I can make safe decisions.

**Why this priority**: Visibility reduces accidental downtime and helps admins plan restarts or avoid incompatible extensions.

**Independent Test**: Attempt to enable a heavy or incompatible extension and check that the UI shows warnings, prevents unsafe combinations, and logs the decision.

**Acceptance Scenarios**:

1. **Given** an extension conflicts with another enabled module, **When** the admin tries to enable it, **Then** the UI blocks the change or forces the conflicting module off with a confirmation dialog.
2. **Given** an extension requires restarting PHP-FPM, **When** the admin saves the change, **Then** the UI communicates the pending restart and tracks completion status.

---

### Edge Cases

- Extension download or extraction fails mid-installation → installation should stop and offer retry with error details instead of leaving PHP partially configured.
- User disables a critical dependency that another enabled extension needs → system should warn and block the change until the dependent module is deselected.
- Configuration UI loses connectivity while applying changes → ensure rollback or clearly show partial success with steps to reconcile state.
- Low disk space prevents adding a new extension → warn the admin before attempting installation and keep PHP running with previous extensions.
- Simultaneous changes from multiple administrators → last save should warn about stale data and require refresh to prevent overwriting.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present a curated list of PHP 8.3 extensions compatible with Synology DS920+ (Gemini Lake) during installation, including descriptions, dependencies, and default status.
- **FR-002**: System MUST allow installers to enable or disable each listed extension within the installation wizard before the final confirmation step.
- **FR-003**: System MUST persist the installer’s extension selections and apply them automatically once the package is fully installed (modules copied, INI configured, services restarted).
- **FR-004**: System MUST provide a DSM-accessible configuration interface after installation where administrators can review, search, and toggle the same extension list.
- **FR-005**: System MUST validate extension dependencies and conflicts in real time, surfacing warnings and blocking unsupported combinations both during install and in the configuration UI.
- **FR-006**: System MUST queue necessary service restarts (CLI/FPM) triggered by extension changes and inform the user of expected downtime before proceeding.
- **FR-007**: System MUST log all extension selection changes (who, when, before/after state) for troubleshooting and support.
- **FR-008**: System MUST expose a default recommended extension set that can be applied with one action for quick installs.
- **FR-009**: System MUST provide roll-back guidance if an extension activation fails (e.g., revert to previous working set and display failure reasons).
- **FR-010**: System MUST ensure configuration states remain consistent even if the UI session ends early, persisting pending changes only after confirmation.

### Key Entities *(include if feature involves data)*

- **Extension Option**: Represents a single PHP module available in the package; attributes include name, description, compatibility flag, dependencies, conflicts, size impact, restart requirement, and default state.
- **Extension Configuration Profile**: Captures the user’s chosen set of enabled/disabled extensions, timestamps, actor identity, and notes about pending restarts; used both for install defaults and ongoing configuration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of administrators complete extension selection during installation without leaving defaults unchanged, indicating the list is understandable and actionable.
- **SC-002**: Post-install configuration interface loads the current extension status within 5 seconds and applies confirmed changes (including restarts) within 2 minutes for a batch of up to 10 extensions.
- **SC-003**: At least 95% of extension enable/disable operations succeed on first attempt, with clear remediation guidance provided for the remaining 5%.
- **SC-004**: Support requests related to enabling or disabling PHP extensions decrease by 60% within two release cycles after this feature ships, demonstrating improved self-service.

## Assumptions

- Only Synology administrators with package management rights can access the installation wizard and configuration UI.
- Extension catalog will initially mirror the curated set already shipped in the package; new extensions follow the same workflow.
- Service restarts triggered by extension changes are acceptable when communicated to the administrator and typically complete within a few seconds on DS920+ hardware.
