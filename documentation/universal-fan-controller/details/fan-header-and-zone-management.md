# Fan Header & Zone Management
Robust monitoring and management of motherboard fans or "fan headers" (nod to the the term for the physical fan connector on motherboards) requires complex logic that is able to manage multiple abstraction layers.

**inventory → validate → assign → calibrate → enforce**

```
1. Inventory : Identify, label, and sort fan headers
2. Validate  : Confirm status and determine fan group relationships
3. Assign    : Pair fan headers to functional and task based requirements
4. Calibrate : Review and synchronize fan groups, functional fan assignments
5. Enforce   : Fail fast when fan management logic is compromised
```

Each core program (Builder, Service Launcher, and Service Runtime) owns distinct responsibilities with regards to managing the fan ecosystem in the server.

| Program Module | Focus |
|----------------|-------|
| Builder | Organize and categorize fan headers into functional/task groups/zones |
| Service Launcher | Validate fan system state on boot and flag deviations from defined specs |
| Service Runtime | Real-time system monitoring; adapt to unexpected changes with dynamic reconfiguration |

---

## Builder Initialization and Calibration Order

This ordering:
- Avoids establishing fan header/zone binary settings prematurely
- Separates inventory from calibration
- Prioritizes CPU fans
- Prevents inter-mixing validation and setting states

1. `inventory_fan_headers`
    - Enumerate and label all connected fan headers.

2. `inventory_fan_schemas`
    - Sets `fan_zone_binary`.
    - **Does not** set category-level zone binaries.

3. `validate_cpu_fan_headers`
    - Ensure at least one fan is marked as `cpu` duty category.
    - Flags misconfigured or missing CPU fans.

4. `inventory_category_fan_zones`
    - Assign fan headers to categories.
    - Builds category-level fan zone binaries (e.g., `cpu_fan_zone_binary`).

5. `calibrate_active_fan_headers`
    - Determines which fan headers are currently active.
    - Updates `fan_header_status` and `active_fan_header_binary`.

6. `enforce_cpu_cooling_priority`
    - Ensures active CPU fans exist.
    - Promotes alternate fans to CPU duty if needed.

7. `calibrate_active_fan_zones`
    - Sets `fan_zone_active_binary` (master active zone binary).
    - Updates category-specific binaries like `cpu_fan_zone_active_binary`.

---

## Launcher Execution Order

The Launcher applies the following fan header/zone management processes as part of its analysis phase.

1. `validate_fan_inventory`
    - Confirms physical fan headers match Builder-generated inventory.
    - Catches missing or added fans before continuing.

2. `validate_cpu_fan_headers`
    - Ensures CPU fan headers are correctly marked and present.
    - Prevents launch if no valid CPU fans exist.

3. `calibrate_fan_zones`
    - Validates that no fan zone appears in more than one non-excluded category.
    - Reconstructs all fan zone binary mappings:
        - `fan_zone_binary` (master)
        - `<category>_fan_zone_binary` (per duty category)

4. `calibrate_active_fan_headers`
    - Detects which fans are operational ("active").
    - Updates `fan_header_status` and `active_fan_header_binary`.

5. `enforce_cpu_cooling_priority`
    - Ensures CPU cooling is guaranteed.
    - May promote valid non-CPU fans into the CPU category temporarily.

6. `calibrate_active_fan_zones`
    - Depends on active fan headers being determined.
    - Finalizes zone activation:
        - `fan_zone_active_binary` (master)
        - `<category>_fan_zone_active_binary` (per category)

---

## Runtime Execution Order

Runtime</br>
└── suspicious_fan_management()</br>
    ├── validate_cpu_fan_headers        # 1. Confirm CPU cooling viability after header changes</br>
    ├── calibrate_active_fan_headers    # 2. Rebuild the active fan set after exclusions/inclusions</br>
    ├── calibrate_active_fan_zones      # 3. Reflect changes in active fan zone mapping</br>
    └── enforce_cpu_cooling_priority    # 4. Promote available fans if CPU cooling is compromised</br>

1. `validate_cpu_fan_headers`
    - Ensures CPU fan headers are correctly marked and present.
    - Prevents launch if no valid CPU fans exist.
    - Fail-fast principle: Immediately know if CPU safety is compromised.
    - If a re-inclusion occurs and brings a CPU fan back online, this will catch it.

2. `calibrate_active_fan_headers`
    - Detects which fans are operational ("active").
    - Updates the active set cleanly after any fan's status changes.
    - Updates `fan_header_status` and `active_fan_header_binary`.

3. `calibrate_active_fan_zones`
    - Finalizes zone activation:
        - `fan_zone_active_binary` (master)
        - `<category>_fan_zone_active_binary` (per category)
    - Depends on active fan headers being determined.
    - Once active fans are known, their zones must be synced, maintaining zone integrity.

4. `enforce_cpu_cooling_priority`
    - Ensures CPU cooling is guaranteed.
    - May promote valid non-CPU fans into the CPU category temporarily.
    - This ensures that post recalibration, the system responds to CPU fan loss by reassigning suitable non-CPU fans.
