## `function name`

| Builder | Launcher | Runtime |
|:-------:|:--------:|:-------:|
|   ✅    |    ❌    |   ❌    |

**Purpose**: 

## **Overview**

This subroutine:
- abc

| Direct | Group | Universal | Zoned |
|:------:|:-----:|:---------:|:-----:|
| ✅ | ✅ | ❌ | ❌ |

## **Importance**

<details>
<summary><strong>Downstream Impact</strong></summary>

> ### 
> -

</details>

---

## **Dependencies**
Ensure `` has been run before calling this subroutine.

- Bash 4.2+ (associative arrays required)
- `ipmitool` must be installed and available in `$PATH`
- The following subroutines must be sourced prior to use:
  - `load_motherboard_schema`
  - `get_fan_id_from_header`
- Assumes the following variables have been initialized:
  - `fan_headers[]` (array of discovered fan headers)
  - `fan_control_method` (string: "group" or "direct")

## **Inputs**

- `[]` — Array of (from ``)

## **Outputs**
Creates the following mappings:

| Array                              | Key                     | Value                  | Purpose     |
|------------------------------------|-------------------------|------------------------|-------------|
| `[]`                               | ?                       | ?                      | Description |

<details>
<summary><strong>Example</strong></summary>

```bash
```

</details>

---

## **Why This Matters**

<details>
<summary><strong>something important</strong></summary>

> ###
>

</details>

---

## **How It Works**
1. 

<details>
<summary><strong>Task Summary</strong></summary>

### **Task Summary***
This function performs the following tasks:

1.

</details>

---

## **Process Flow Diagram**
This diagram reflects how the script ensures alignment between the fan header inventory and the IPMI write sequence, with clear abort conditions when unsafe assumptions would be required.

```plaintext
```


```mermaid
graph TD
  Start[Start]
  
  Start --> CheckIfWeProceed{Is control method Direct or Group?}
  
  CheckIfWeProceed -- No --> CleanExit[Clean exit]
  CheckIfWeProceed -- Yes --> IsListPreDefined{Is $ipmi_fan_write_order array pre-defined?}

  IsListPreDefined -- Yes --> CallOrderFanHeaders1
  IsListPreDefined -- No --> CheckManufacturerList{Is motherboard-specific order known?}

  CheckManufacturerList -- Yes --> CallOrderFanHeaders1[order_fan_headers_by_write_position]
    click CallOrderFanHeaders1 "https://github.com/dguyton/universal-fan-controller/blob/main/documentation/universal-fan-controller/details/subroutines/order_fan_headers_by_write_position.md" "Go to ipmi_fan_write_order documentation"

  CheckManufacturerList -- No --> ApplyDefaultOrderingLogic[Apply default ordering logic]

  CallOrderFanHeaders1 --> ValidateFanOrder1{Is write-order list now populated?}

  ValidateFanOrder1 -- Yes --> End
  ValidateFanOrder1 -- No --> ApplyDefaultOrderingLogic

  CallOrderFanHeaders2 --> ValidateFanOrder2{Is write-order list now populated?}
    click CallOrderFanHeaders2 "https://github.com/dguyton/universal-fan-controller/blob/main/documentation/universal-fan-controller/details/subroutines/order_fan_headers_by_write_position.md" "Go to ipmi_fan_write_order documentation"

  ValidateFanOrder2 -- Yes --> End[Return write map]
  ValidateFanOrder2 -- No --> Fail[Fail & Bail]

  ApplyDefaultOrderingLogic --> CheckForManufacturerFormula[Check for manufacturer-specific schema]

  CheckForManufacturerFormula --> CallOrderFanHeaders2[order_fan_headers_by_write_position]
```

