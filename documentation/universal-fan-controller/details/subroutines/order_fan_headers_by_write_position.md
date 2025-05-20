## `order_fan_headers_by_write_position`

| Builder | Launcher | Runtime |
|:-------:|:--------:|:-------:|
|   ✅    |    ❌    |   ❌    |

**Purpose**: Maps BMC/IPMI write order to known fan headers, ensuring proper manual fan control under _direct_ and _group_ methods. Required for translating fan inventory to correct raw write command payloads.

## **Overview**

This subroutine:
- Maps each fan header name and ID to its correct write position in IPMI command payloads.
- Supports [_direct_](link) and [_group_](link) fan control methods only.
- Generates output arrays that allow translation between fan inventory and expected BMC write sequence.

| Direct | Group | Universal | Zoned |
|:------:|:-----:|:---------:|:-----:|
| ✅ | ✅ | ❌ | ❌ |

**Required** for direct and group fan control methods.

> [!WARNING]
> This subroutine must be called before any control command construction. Do not assume the order of base fan header variables (such as `fan_header_id[]` and `fan_header_name[]` arrays) reflect IPMI write positions unless explicitly ordered using this function.

## **Importance**
Without this information, manual fan control with motherboards utilizing _direct_ or _group_ fan control methods cannot be implemented.

The fan write order determines how PWM bytes are packed into all subsequent raw control commands, ensuring that each fan receives the intended value regardless of how headers are ordered in config files.

Execution of this subroutine has the following effect on the main program and overall process flow:
- Success: Direct and group manual fan control methods are possible.
- Failure: If fan control method is direct or group, UFC cannot continue, and the main program must be aborted.

<details>
<summary><strong>Downstream Impact</strong></summary>

> ### Direct Fan Control Method
> - IPMI read fan header IDs are mapped to their assigned IPMI write fan header position.
> - Provides individual fan header look-up mappings.
> - `$ipmi_write_position_fan_id[]` array may be required by fan duty command execution subroutines under some circumstances.
> 
> ### Group Fan Control Method
> - Stores fan name or special byte type for each IPMI data byte, in sequential write-position order.
> - Stores fan id for each write position that is a fan header name.
> - Used to create write order template with fan IDs, since this info is static.

</details>

---

## **Dependencies**

Ensure `ipmi_order_fan_header_names` has been run before calling this subroutine.

## **Inputs**

- `ipmi_fan_write_order[]` — Array of fan header names (from `ipmi_order_fan_header_names`)
- `reserved_fan_name[]` — Mapping of reserved placeholders (must be loaded from config)
- `fan_header_name[]` and `fan_header_id[]` — Populated from inventory process
- `ipmi_payload_byte_count` — Required downstream when using group fan control method

## **Outputs**
Creates the following mappings:

| Array                              | Key                     | Value                  | Purpose |
|------------------------------------|-------------------------|------------------------|---------|
| `ipmi_write_position_fan_name[]`   | Write position          | Fan name or reserved word | Maps write position to fan name |
| `ipmi_write_position_fan_id[]`     | Write position          | Fan ID                 | Links write position to fan ID (required by Group fan control method) |
| `ipmi_fan_id_write_position[]`     | Fan ID                  | Write position         | Maps fan ID to write slot (required by Direct fan control method) |

<details>
<summary><strong>Example</strong></summary>

```bash
# map sequential fan write position to fan name for direct and group method fan control
ipmi_write_position_fan_name[write position]="fan name"
ipmi_write_position_fan_name[3]="FANB"

# map sequential fan write position to fan ID for group method fan control
ipmi_write_position_fan_id[write position]="fan id"
ipmi_write_position_fan_id[3]=1

# map fan header write positions use with the direct fan control method
ipmi_fan_id_write_position[fan id]="write position"
ipmi_fan_id_write_position[1]=3
```

</details>

---

## **Why This Matters**
Under ideal circumstances, the fan ID order during IPMI read commands is identical to the fan ID order during IPMI write commands. However, this is not always the case. It is not uncommon for the write order to be different from the read order. Fan sensor reading tools may arrange and report fan header names in a different order than that expected by the BMC when it receives fan header write commands. Therefore, the correct order must be known ahead of time (the template). Regardless of how the fans are ordered on IPMI sensor read operations, the write command order cannot deviate from the sequence expected by the BMC implementation for the specific motherboard model. Even different boards from the same manufacturer may have different fan write-order sequences.

<details>
<summary><strong>Fan ID Position vs. Write Order Position</strong></summary>

> ### Fan ID Position vs. Write Order Position
> UFC supports multiple different fan control methods, one of which -- the _group_ method -- requires the highest density of descriptive metadata in order for UFC to manually control the fans. This is because the group fan control method requires ALL fan headers to be addressed simultaneously with every IPMI command directed to the fan headers. This makes manual fan control significantly more complex, compared to other fan control methods.
>
> A disadvantage of the group fan control method is that all fans must have their fan duty speed updated simultaneously. This means that even fans which should not have their current fan duty changed must still be updated. Therefore, more sophisticated logic is required to actively manage the fans, such as maintaining a record of the fan duty each fan header is currently set to. This ensures no fan header is left out when the group command is compiled.

</details>

---

## **How It Works**
1. Map discovered fan headers to their write order expected by the BMC.
2. Create look-up arrays that will allow the main program in use to send IPMI fan speed write commands to the intended fan header(s).
3. Handle special reserved data payload bytes -- for example, CPU override flags -- when required by the motherboard.
4. Template cannot have empty position entries. Every position in the output array must be a valid fan header name or a recognized reserved word.

<details>
<summary><strong>Task Summary</strong></summary>

### **Task Summary***
This function performs the following tasks:

1. Validate inventoried fan names against write-order array
2. Process fan headers in write order expected by BMC
3. Assign write position to each fan ID/name
4. Pad write order group fan control method with reserved word placeholders, as specified in fan write-order schema

</details>

---

## **Process Flow Diagram**
This diagram reflects how the script ensures alignment between the fan header inventory and the IPMI write sequence, with clear abort conditions when unsafe assumptions would be required.

```plaintext
+-------------------------------+
| Check $fan_control_method    |
| → direct or group?           |
+-------------------------------+
            |
            v
+---------------------------------------+
| Verify ipmi_fan_write_order[] exists |
+---------------------------------------+
            |
            v
+---------------------------------------------+
| For each write_position in template array: |
+---------------------------------------------+
            |
            v
+-------------------------------+
| Is fan_name empty?           |
| → Yes: bail (template error) |
+-------------------------------+
            |
            v
+--------------------------------------------+
| Is fan_name in inventory or reserved word? |
| → No: Track missing                        |
+--------------------------------------------+
            |
            v
+----------------------------------------+
| Control method = direct or group?     |
| → direct: update fan_id ↔ position    |
| → group:  update fan_name ↔ position  |
+----------------------------------------+

[AFTER LOOP]
            |
            v
+------------------------------------------------+
| Check if any inventoried fans missing in       |
| template?                                      |
| → Yes: Critical warn + bail (template error)   |
|     [Duplicates are acceptable]                |
+------------------------------------------------+
            |
            v
+----------------------------------------------------------+
| Check if any template fans missing in inventory?         |
| → Yes and group method?                                  |
|     → Can DUMMY placeholder be used?                     |
|         → Yes: Fill missing with DUMMY                   |
|         → No: Critical error + bail                      |
+----------------------------------------------------------+
```
