# Implementation Plan: PHP Extension Selection Controls

**Branch**: `001-extension-selection` | **Date**: 2025-11-13 | **Spec**: [`specs/001-extension-selection/spec.md`](./spec.md)
**Input**: Feature specification from `/specs/001-extension-selection/spec.md`

**Note**: This plan follows the workflow defined in `.specify/templates/commands/plan.md`.

## Summary

Deliver a Synology DSM 7 package experience where administrators choose which PHP 8.3 extensions install during the Package Center wizard and adjust the same list post-install via a DSM configuration panel. We will extend the spksrc recipe for PHP 8.3 to (1) expose extension metadata to the installer UI, (2) persist selections into package configuration, and (3) ship a DSM-native control panel that safely toggles modules while respecting dependencies, conflicts, and restart requirements.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: spksrc makefiles + POSIX shell scripts wrapping PHP 8.3 build artifacts  
**Primary Dependencies**: spksrc toolchain for DSM 7 Geminilake, Synology Package Center wizard hooks, DSM Service UI framework  
**Storage**: `/var/packages/php83/conf/extension_selection.json` (+ backup) drives INI fragments per research.md  
**Testing**: Shell-based unit tests inside spksrc build + DS920+ integration smoke tests via `synopkg` + `php -m`  
**Target Platform**: Synology DSM 7.x on DS920+ (Intel Celeron J4125 Gemini Lake)  
**Project Type**: Synology spksrc package (service scripts + DSM UI panel)  
**Performance Goals**: Wizard extension list renders <3s; post-install UI loads status <5s; batch toggle applies within 2 minutes for ≤10 extensions (per spec SC-002)  
**Constraints**: Must preserve upstream PHP defaults, reproducible spksrc builds, DSM-compliant service scripts, minimal downtime; opcache tuned for 4GB RAM with ability to scale down  
**Scale/Scope**: Single NAS admin concurrently; extension catalog limited to curated set shipped via package (<30 modules) but combinations must remain stable

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Upstream Parity** – PASS: Using official PHP 8.3 sources and only exposing upstream-vetted extensions; no DSM-only forks planned.  
- **II. Reproducible spksrc Builds** – PASS: All logic lives inside spksrc makefiles/scripts with pinned toolchain + checksums.  
- **III. Synology-first Integration** – PASS: Feature centers on DSM installer hooks and control panel compliance.  
- **IV. Test & Validate on Target** – PASS W/ ACTION: Need automated strategy for extension toggle verification on DS920+ (see Technical Context testing unknown).  
- **V. Documentation & Supportability** – PASS: Quickstart + UI descriptions will document workflows and rollback guidance.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
spk/php83/
├── Makefile                       # spksrc recipe extended with extension metadata exports
├── src/
│   ├── install-wizard/            # DSM install wizard pages + extension selector assets
│   ├── config-panel/              # DSM Control Panel module for post-install toggles
│   └── scripts/                   # preinst/postinst/preun/postun/service scripts
├── files/
│   ├── conf/extension_selection.json.sample
│   ├── ui/                        # static resources for DSM panel
│   └── bin/                       # helper CLIs for enabling/disabling modules
tests/
├── integration/extension-selection/  # hotplug + DSM UI smoke tests
└── unit/                           # script-level tests (where possible)

specs/
└── 001-extension-selection/
    ├── spec.md
    ├── plan.md
    ├── research.md
    ├── data-model.md
    ├── quickstart.md
    └── contracts/
```

**Structure Decision**: Extend existing (or newly created) `spk/php83` package definition with dedicated subdirectories for installer UI, configuration panel, and helper scripts; tests live under `tests/` mirroring integration/unit split; specification artifacts remain inside `specs/001-extension-selection`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |

## Phase 0: Outline & Research

### Research Tasks

1. **Storage medium for extension selections** – Completed via `research.md` (JSON in package conf dir).  
2. **Automated test strategy on DSM hardware** – Completed via `research.md` (spksrc shell tests + DS920+ smoke tests).  
3. **spksrc packaging best practices for extension metadata** – Completed (extend recipe with EXTENSION_OPTIONS + wizard manifest).  
4. **Package Center wizard integration pattern** – Completed (use WIZARD_UIFILES + wizard variables).  
5. **DSM configuration panel pattern** – Completed (ExtJS panel backed by local REST endpoint).

### Output

- Created [`research.md`](./research.md) summarizing each decision with rationale and alternatives.

## Phase 1: Design & Contracts

### Outputs

- Authored [`data-model.md`](./data-model.md) detailing `Extension Option` and `Extension Configuration Profile` entities plus state transitions.  
- Produced [`contracts/extension-config.openapi.yaml`](./contracts/extension-config.openapi.yaml) covering `GET /options`, `GET /profile`, and `PATCH /apply`.  
- Documented developer workflow in [`quickstart.md`](./quickstart.md).  
- Ran `.specify/scripts/bash/update-agent-context.sh codex` to capture stack info inside `AGENTS.md`.

### Constitution Check (Post-Design)

- **I. Upstream Parity** – STILL PASS: Data model ties options to upstream module list; no forks introduced.  
- **II. Reproducible spksrc Builds** – STILL PASS: All artifacts plan to live under `spk/php83` recipe with tracked manifests.  
- **III. Synology-first Integration** – STILL PASS: Contracts target DSM-local endpoint and DSM UI components.  
- **IV. Test & Validate on Target** – ACTION PLANNED: Quickstart + testing approach commits us to shell + on-device smoke tests; ensure Phase 2 tasks schedule these steps explicitly.  
- **V. Documentation & Supportability** – PASS: Quickstart + contracts serve as documentation deliverables.

## Phase 2: Implementation Planning (Preview)

1. **spksrc recipe updates** – add `EXTENSION_OPTIONS`, wizard metadata, and config template integration.  
2. **Installer wizard UI** – build DSM wizard JSON/JS assets sourcing manifest + handling dependency logic client-side.  
3. **Configuration service + panel** – implement local REST handler + ExtJS panel, wire to storage, enforce validation rules.  
4. **Runtime scripts** – ensure `preinst/postinst/service-setup` read stored selections, regenerate INI fragments, and queue restarts.  
5. **Testing + logging** – create shell-based unit tests, deploy to DS920+, run smoke matrix, capture audit logs per requirement.  
6. **Documentation polish** – finalize user-facing instructions (README/package description) referencing new controls.
