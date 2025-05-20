## `execute_ipmi_fan_payload`

| Builder | Launcher | Runtime |
|:-------:|:--------:|:-------:|
|   ✅   |   ✅   |   ✅   |

**Purpose**: Executes IPMI request to alter current fan duty (PWM %) of one or more fan headers.

## **Overview**

This subroutine:
- Consolidated function that processes the final compilation of IPMI raw commands to adjust fan speeds and sends the command
- Applies to all fan control methods
- Calls other subroutines to pre-process vendor specific criteria and validate group fan control method payloads

| Direct | Group | Universal | Zoned |
|:------:|:-----:|:---------:|:-----:|
| ✅ | ✅ | ✅ | ✅ |

## **Importance**
- This subroutine is the actual processor of fan speed change requests.

---

## **Dependencies**
Other subroutines must have been run first. See the fan write-order mapping process flowchart found [here](/documentation/universal-fan-controller/details/fan-write-order-mapping.md#fan-control-methods-process-flow).

## **Inputs**
Inputs are required for all fan control methods ***except for the Group method***.

| Variable/Array Name                |  Value                  | Purpose                            |
|------------------------------------|-------------------------|------------------------------------|
| `$1`                               | integer                 | Requested fan duty (PWM %)         |
| `$2`                               | integer                 | Target (fan ID, zone ID, or group) |

## **Outputs**
None (output is physical execution of fan speed changes).

## **How It Works**
1. Organizes IPMI command payload and data bytes based on fan control method
2. Validates fan control target and fan duty requested
3. Sends fan control command to BMC via IPMI

<details>
<summary><strong>Task Summary</strong></summary>

### **Task Summary**
This function performs the following tasks:

1. Validates the fan duty and target input.
1. Calls [`compile_ipmi_fan_payload`](/documentation/universal-fan-controller/details/subroutines/compile_ipmi_fan_payload.md) subroutine that performs the following tasks:
    1. maps fan IDs or zone IDs to IPMI write-order positions.
    1. Applies bounds checking on the fan duty request.
    1. Constructs IPMI raw command payloads.
1. Executes payload using ipmitool raw command.

</details>

---

## **Process Flow Diagram**
This diagram reflects how the script ensures alignment between the fan header inventory and the IPMI write sequence, with clear abort conditions when unsafe assumptions would be required.

```mermaid
flowchart TD
    %% Callbacks

    %% Extra relationships

    %% Links



%% start([Start Function])

    %% called by
    set_fan_duty_cycle[set_fan_duty_cycle]
    set_all_fans_mode[set_all_fans_mode]

    %% Nodes
    check_method{"Branch on fan control method"}
    validate_duty_param["Validate: fan duty not empty"]
    validate_target_type["Check: target is valid (fan ID or zone ID)"]
    validate_target_exists["Check: target exists in system"]
    map_fan_id["Map fan ID to IPMI write order"]
    validate_zone["Validate: zone is active"]
    sanitize_zone["Sanitize zone ID as target"]
    check_fan_duty_bounds["Clamp fan_duty to min/max limits"]
    to_hex["Convert fan duty to hex"]

    dispatch_mfg{"Manufacturer case block<br><a href="https://github.com/dguyton/universal-fan-controller/blob/main/documentation/universal-fan-controller/details/subroutines/compile_ipmi_fan_payload.md">compile_ipmi_fan_payload</a>"}

    fail_payload(["Fail: No IPMI command built"])
    run_final["Execute IPMI command"]
    finish([Return 0])

    %% Calls
    set_fan_duty_cycle --> start
    set_all_fans_mode --> start
    start --> check_method
    validate_duty_param --> validate_target_type
    validate_target_type --> validate_target_exists
    map_fan_id --> check_fan_duty_bounds
    validate_zone --> sanitize_zone
    sanitize_zone --> check_fan_duty_bounds
    check_fan_duty_bounds --> to_hex
    to_hex --> dispatch_mfg
    dispatch_mfg -->|matched| run_final
    dispatch_mfg -->|unmatched| fail_payload
    run_final --> finish

    %% Fan control methods
    check_method -->|Direct, Universal, or Zone| validate_duty_param
    validate_target_exists -->|Direct| map_fan_id
    validate_target_exists -->|Zone| validate_zone
    validate_target_exists -->|Universal| check_fan_duty_bounds
    check_method -->|Group| dispatch_mfg
```
