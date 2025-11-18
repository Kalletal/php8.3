# Research Findings – PHP Extension Selection Controls

## Storage medium for extension selections

- **Decision**: Persist enabled/disabled extensions in `/var/packages/php83/conf/extension_selection.json` (with a `.bak` snapshot per apply) and generate PHP INI fragments at runtime from this file.  
- **Rationale**: Package-managed JSON keeps state colocated with other PHP config, is covered by Synology backup/export flows, and avoids coupling to DSM’s internal SQLite config DB. Regenerating INI fragments ensures upstream parity while still keeping user-specific choices.  
- **Alternatives considered**:  
  - DSM internal config DB via `synoservicecfg` – rejected because it requires privileged access, is undocumented, and complicates portability between NAS units.  
  - Directly editing `php.ini` – rejected because toggling becomes brittle and difficult to audit/rollback.

## Automated test strategy for extension toggles

- **Decision**: Run script-level unit tests in the spksrc toolchain using `pytest`-style shell harnesses, then execute integration smoke tests on a DS920+ (or emulator) via `synopkg install` + CLI toggles to confirm `php -m` matches requested extensions.  
- **Rationale**: spksrc builds already run on build hosts, so adding shell-based validation ensures scripts behave. Full trust, however, requires executing on target hardware per constitution principle IV. Using Synology’s `synopkg` CLI + `php -m` provides deterministic verification without custom tooling.  
- **Alternatives considered**:  
  - Only manual QA on NAS – rejected because it violates reproducibility/testing gates.  
  - Full DSM VM automation – not currently stable for Geminilake hardware acceleration and would slow the build pipeline.

## spksrc packaging best practices

- **Decision**: Keep all extension metadata inside the `spk/php83` makefile via new `EXTENSION_OPTIONS` variable, expose manifests through `WIZARD_UIFILES`, and rely on `service-setup` scripts for enabling/disabling modules post-install.  
- **Rationale**: Staying inside the spksrc recipe retains reproducibility (Principle II), ensures source control of extension defaults, and leverages upstream toolchain features like `PLIST` + `synopkg` wizard integration without inventing new pipelines.  
- **Alternatives considered**:  
  - Maintaining a parallel metadata store outside spksrc – rejected as it risks divergence and complicates builds.  
  - Injecting logic directly into DSM UI code – rejected to keep UI decoupled from build metadata.

## Package Center wizard integration pattern

- **Decision**: Use the standard DSM wizard multi-step UI by adding a new page defined in `INFO`/`WIZARD_UIFILES`, rendering checkboxes bound to the `EXTENSION_OPTIONS` manifest, and writing selections into `wizard_variable` for consumption by `preinst`.  
- **Rationale**: This leverages Synology’s supported wizard pipeline, enabling localized text/resources and ensuring compatibility with DSM updates. Capturing wizard values through environment variables is the documented path for customizing installs.  
- **Alternatives considered**:  
  - Customizing the wizard via post-install script prompts – rejected because Package Center discourages interactive scripts and provides poor UX.  
  - Skipping wizard integration and forcing defaults – contradicts the feature goal.

## DSM configuration panel pattern

- **Decision**: Ship a Control Panel entry backed by Synology’s Web UI (ExtJS) that calls a lightweight local REST endpoint (served by the package) which reads/writes `extension_selection.json`, enforces dependencies, and triggers service restarts.  
- **Rationale**: DSM modules commonly expose ExtJS panels communicating with localhost endpoints or CLI wrappers; this approach keeps UI responsive, allows multi-change batching, and integrates with DSM permissions.  
- **Alternatives considered**:  
  - Embedding all logic in shell scripts triggered via buttons – rejected because it offers no stateful UI, poor validation, and limited feedback.  
  - Building a standalone web UI outside DSM – rejected to honor Principle III (Synology-first integration).
