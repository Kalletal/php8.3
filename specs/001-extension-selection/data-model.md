# Data Model – PHP Extension Selection Controls

## Entities

### Extension Option
- **Identifier**: `id` (stable slug, e.g., `pdo_mysql`)
- **Name**: Human-readable label shown in DSM UI
- **Description**: Short explanation of capabilities and use cases
- **Category**: Optional grouping (e.g., database, intl, graphics)
- **Default State**: Boolean for recommended install-on-first-run
- **Dependencies**: Array of other option IDs that must be enabled first
- **Conflicts**: Array of option IDs that cannot co-exist
- **Compatibility**: Flag noting Geminilake support status (e.g., unsupported on this hardware)
- **Disk Footprint**: Estimated size to surface warnings when space is low
- **Restart Required**: Enum (`none`, `php-fpm`, `php-cli`, `both`)
- **Status Metadata**: Derived fields such as last toggled timestamp or error note when activation failed

**Relationships**:  
- Many-to-one with `Extension Configuration Profile` (the profile references many options).  
- Dependencies/conflicts reference other `Extension Option` entries by `id`.

**Validation Rules**:  
- `id` must match `[a-z0-9_]+` and remain stable between package versions.  
- Dependencies must exist within the manifest; circular dependencies blocked.  
- Conflicts cannot overlap with dependencies.  
- Disk footprint must be >=0 MB.

### Extension Configuration Profile
- **Profile ID**: Always `default` for now, but modeled to allow future multi-profile support
- **Selected Options**: Set of option IDs currently enabled
- **Pending Changes**: Optional list capturing staged toggles before apply
- **Applied At**: Timestamp when last apply finished successfully
- **Applied By**: DSM account identifier invoking the change
- **Restart Actions**: Record of which services were restarted
- **Warnings/Errors**: Array with structured detail when apply partially fails

**Relationships**:  
- References `Extension Option` entries for enabled/disabled states.  
- Linked to audit logs for compliance (log structure defined in implementation).

**Validation Rules**:  
- Selected options must include all required dependencies and exclude conflicts before commit.  
- Pending changes must expire/clear after timeout or once applied.  
- Profiles must always reflect actual on-disk modules; drift detection triggers reconciliation.

## State Transitions

1. **Initial Install**  
   - Manifest loads default states → profile seeded with recommended extensions.  
   - Any wizard changes override defaults before first apply.

2. **User Edits in Configuration Panel**  
   - Pending changes captured → dependency/conflict validation runs.  
   - Once confirmed, system writes new profile, regenerates INI fragments, and restarts required services.

3. **Failure Handling**  
   - If enabling fails (e.g., disk space), revert profile to last applied state, mark warning/error, and prompt user to retry after remediation.

4. **Package Upgrade**  
   - Migrate profile by matching option IDs; new options adopt defaults, removed options drop from profile with audit log entry.
