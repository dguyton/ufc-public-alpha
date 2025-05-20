# How to Update Include Files
Guidance on updating the include files most likely to require modification for various reasons.

### `set_lower_fan_thresholds.sh`
This function adjusts the lower fan speed thresholds stored in the BMC's non-volatile memory.
- Not every board needs this.
- Only update this file if the board requires establishing a manual fan mode before the BMC will accept manual fan speed settings.

#### How to Update
Determine if any of the new manufacturer's [BMC fan speed threshold](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md) behaviors parallel an existing manufacturer-level use case.

Yes: Append the new manufacturer name to the case branch as appropriate.
```
case "$mobo_manufacturer" in # 1/
	existing-manufacturer-name|new-manufacturer-name)
		...
        ;;
esac # 1/
```

No: Create a new case branch to represent the new manufacturer. Follow the existing code examples to understand the formatting and required information.
```
case "$mobo_manufacturer" in # 1/
	manufacturer-name)
		...
	;;
...
```

Examine how many BMC fan schemas you have currently identified for the new manufacturer. There will most likely only be one unless you are adding a large number of motherboard models at the same time.
  - Only one BMC fan schema: There is no need for a 2nd level case statement, so you are finished here.
  - More than one BMC fan schema: Create a 2nd level/tier case statement under the new 1st level manufacturer case statement and configure code for the new BMC fan schemas as needed. Follow the existing code examples to understand the formatting and required information.

```
case "$mobo_manufacturer" in # 1/
	manufacturer-name)
	    case "$bmc_command_schema" in # 2/
	        bmc-fan-schema-v1)
	            # insert shell commands to enable manual fan control
	        ;;

	        bmc-fan-schema-v2)
	            # insert shell commands to enable manual fan control
	        ;;
	    esac # 2/
	...
```

### `validate_bmc_command_schema.sh`
Attempt to assign BMC command schema version (`$bmc_command_schema`) when not already assigned via a config file.

#### How to Update
1. Add the motherboard manufacturer when not already supported.

```
case "$mobo_manufacturer" in # 1/
        manufacturer-name)
            ...
        ;;
;;
```

2. Add support for a new quantifiable pattern of identifying related motherboard models.

```
case "$mobo_manufacturer" in # 1/
        manufacturer-name)
            ... # custom code to filter pattern
        ;;
;;
```

3. Assign BMC fan schema.

```
case "$mobo_manufacturer" in # 1/
        manufacturer-name)
		... # custom code to filter pattern

		bmc_command_schema="manufacturer-v1"
        ;;
;;
```

### `enable_manual_fan_control.sh`
This function executes a pre-requisite command to enable manual fan speed control. This step is required on some motherboards, but is not a universal requirement.
- Review the existing include file code structure. Focus on the nested `case` statements.

#### How to Update
At the bottom of the file, append a new section in the 2nd tier nested case statement.

```
manufacturer-name)
    case "$bmc_command_schema" in # 2/
        bmc-fan-schema-v1)
            # insert shell commands to enable manual fan control
            return
        ;;
    esac # 2/
```

### `validate_mobo_model.sh`
Validates the motherboard manufacturer brand, model, and generation based on objective hardware information.

From a customization viewpoint, this file serves two purposes:
1. Normalize motherboard manufacturer name
2. Assign the generation of the motherboard model, if applicable.
3. Incorporate optional special code or debug messages as desired.

The most important - and only necessary - portion of this process is the normalization of motherboard manufacturer names. Standard naming conventions are critical to ensure consistency throughout all core program executables and the imported functions (i.e., include files).

#### How to Update
**Step 1: Motherboard manufacturer name standardization.**

This step may be skipped if the default parsed manufacturer name is expected to equal the ideal name.

For example, "Dell" is already represented as "Dell" and therefore there is no need to modify it. However, a Dell brand motherboard may have it's manufacturer name detected as "Dell", "EMC", or "Dell/EMC." Therefore, there is a need to scan for the term "EMC" and replace it with the "Dell" brand, which is therefore the standardized manufacturer name for any motherboard manufactured by Dell, EMC, or Dell/EMC. This creates uniformity in further handling of these boards, as they all get treated as "Dell" boards henceforth from here.

> Raw motherboard manufacturer names are sorted by their _first name only_, as it appears in the raw hardware query metadata.

```
case "$mobo_manufacturer_first_name" in # 1/
        manufacturer-name)
            # insert
	;;
...
```

**Step 2: Determine motherboard generation**

Skip this step if it does not apply or is irrelevant to any branching decisions throughout UFC for the motherboard manufacturer (brand).

Look for the code block beginning with:

```
##
# Parse model/series/generation
##

case "$mobo_manufacturer" in # 1/
```

Add a new entry in the first tier `case` statement if necessary.

```
case "$mobo_manufacturer" in # 1/
	manufacturer-name)
		# insert shell commands to enable manual fan control
	;;
esac # 1/
```

** Step 3: Add special code blocks

Incorporate optional special code or debug messages in the same code block as Step 2 (above), as desired.

### `execute_ipmi_fan_payload.sh`
Specify IPMI commands necessary to implement a fan speed change.

Pre-requisites:
- You must understand the control methods (direct, group, zoned, or universal) supported by the motherboard. Many boards allow more than one method.
- The fan schema ID must exist or be [created](/documentation/universal-fan-controller/how-to.md#2-add-a-new-bmc-fan-schema).

#### How to Update
- Find the motherboard manufacturer's section.
- Add custom code required for each supported control method type.
- Be sure to incorporate exit code that traps invalid control methods.

1. When the motherboard's manufacturer is known, find the motherboard manufacturer's section. Create a new section under the first case statement for the new manufacturer.
2. Under the new manufacturer branch of the first `case` statement, add at least one BMC fan schema. Be sure to adhere to the caveats outlined in adding a new BMC fan schema [if you need to create one](/documentation/universal-fan-controller/how-to.md#2-add-a-new-bmc-fan-schema).
3. Enter the corresponding `raw` command lines based on manufacturer and model specifics. Examine pre-existing code to understand how this works. A framework is shown below.

```
case "$mobo_manufacturer" in # 1/
	manufacturer-name)
		...
		case "$bmc_command_schema" in # 2/ only group method is supported
			bmc-fan-schema-v1)
			...
		;;
	;;
...
```

### `set_all_fans_mode.sh`
This include file is responsible for the IPMI code used to trigger two pre-defined fan modes: Full and Optimal. Both mode types target all active fan headers. These fan modes are triggered when one of the following circumstances occurs:
1. Full mode use case 1: fans to maximum speed for fan calibration purposes
2. Full mode use case 2: graceful exit with request for full fan speeds
3. Full mode use case 3: fans to max speed due to an environment trigger
4. Full mode use case 4: some manufacturers require placing system in full fan mode before it is possible to control fans manually
5. Optimal mode use case 1: graceful exit with request for optimal fan speeds
6. Optimal mode use case 2: some manufacturers require placing system in optimal fan mode before it is possible to control fans manually

#### Additional Observations
- Some motherboard manufacturers have an "acoustic" fan operating mode which is equivalent to or nearly equivalent to the optimal mode concept.
- Some motherboards require specific commands to set Full or Optimal fan speed modes.
- Optimal/Acoustic fan speed mode may be regulated by the BMC or BIOS, or may be a contrived pre-set fan duty.

#### Exceptions
This process does not apply to a motherboard model when its supported fan control methods are 'direct' and/or 'group'. If this is the case, stop here as this file is irrelevant to the motherboard and will be skipped automatically.

#### How to Update
1. Determine the method by which a given motherboard initiates each mode. There are two possible methods.
   - Via a unique fan mode IPMI command; or
   - Through manual fan speed manipulation
2. When a specific fan mode or IPMI command is not applicable, the request will be branched by fan control method type.
3. Full and optimal modes may have different methods of activation (e.g. one may be a built-in fan mode and the other may require manual intervention).

The process is the same to update either fan mode to support the current motherboard.

1. Identify whether the Full or Optimal path will be updated.
2. Append new code to the include file to support the new motherboard manufacturer or model based on its characteristics.
3. The file already has examples for all possible scenarios. Adding another variant should be straight-forward to understand from reviewing the existing code.
4. For both the Full and Optimal fan mode routes, there are only two possible logic paths:
   - Specific IPMI command not related to manual control commands
     - Carve out a new branch in the approprate `case` statement level and insert custom IPMI command logic as necessary, following the protocol of the pre-existing implementations.
   - Normal IPMI fan control commands need to be utilized
     - No changes are necessary, as the process will default to branching based on the fan control method.

**Example code snippet:**
```
case "$mode" in # 1/
	full)
		case "$mobo_manufacturer" in # 2/ segment manufacturer specific special handling
			new-manufacturer-name)
				case "$bmc_command_schema" in # 3/
					new-bmc-fan-schema-version)
						run_command "$ipmitool raw {custom IPMI raw command sequence}"
					;;
				esac # 3/
			;;
		esac # 2/
	;;
esac # 1/
```
