# How To
The Universal Fan Controller (UFC) was designed using a modular architecture. This article describes how to add on various features and functionality to expand UFC's capabilities.

How-To...
1. [Activate SSD Support](#1-activate-ssd-support)
2. [Add a New BMC Fan Schema](#2-add-a-new-bmc-fan-schema)
3. [Add New Motherboard Manufacturer](#3-add-new-motherboard-manufacturer)
4. [Add New Motherboard Model](#4-add-new-motherboard-model)
5. [Specify Fan Zones](#5-specify-fans-in-each-fan-zone)
6. [Update Include Files](/documentation/universal-fan-controller/how-to/how-update-include-files.md#how-to-update-include-files)

---

## 1. Activate SSD Support
To include SSDs as valid disk storage devices, follow the instructions on modifying the Builder configuration file, found [here](best-practices.md#activating-ssd-support).

---

## 2. Add a New BMC Fan Schema
BMC fan schemas are explained in the  [here].
<<>>
BMC fan schemas are custom sets of IPMI instructions. They are a blueprint of IPMI commands tailored to a specific motherboard manufacturer, and apply to one or more motherboard models. BMC fan schemas are commonly referred to as "BMC schama IDs" or "fan schema IDs" in UFC's documentation and in remarks embedded in various places within the code.


These schemas are based on known characteristics of a motherboard's manufacturer and model. Some manufacturers only have one BMC fan schema for all of their motherboard models, but many have more than one. Fan schemas are closely tied to the BMC chip on any given motherboard.

For example, two motherboard models from the same manufacturer could have different BMC chips, but may or may not require different fan schemas. Imagine one has an ASPEED AST2300 BMC chip and the other has an ASPEED AST2400. It's possible both boards may be able to use the same IPMI commands to control fans. If that is true, then only one BMC fan schema is needed. However, if the required command sets differ, then they would need separate fan schemas.

To designate a new BMC fan schema:
1. Update related functions so they understand the new fan schema and do not reject it as unknown. This defines the application of the new fan schema.
2. Create or update configuration (.conf) files related to the motherboard manufacturer and/or models to incorporate the use of the new BMC fan schema. You may optionally choose to update the Builder configuration file instead, though this practice is normally discouraged.

> [!CAUTION]
> To add a new BMC fan schema, its corresponding manufacturer must be supported. If it is not, you must first [add support](#add-support-for-new-motherboard-manufacturer) for it.

### Update Functions Related to Fan Schemas
Update the following include files (functions) as needed:
1. [set_lower_fan_thresholds.sh](#set_lower_fan_thresholdssh)
    - Only update this file if the board requires establishing manual fan mode before the BMC will accept manual fan speed settings (not every board needs this).
2. [execute_ipmi_fan_payload.sh](#execute_ipmi_fan_payloadsh)
3. [set_all_fans_mode.sh](#set_all_fans_modesh)

### Create or Update Config Files
Create or update configuration (.conf) file(s) for the motherboard manufacturer and/or motherboard models to incorporate the use of the new BMC fan schema. This involves assigning the new fan schema in the most appropriate location, which can be placed in any of these config files:
1. [Motherboard manufacturer](/documentation/configuration/manufacturer-config-files.md)
    - Set the default BMC fan schema for all motherboards from the manufacturer, if prudent.
2. [Motherboard model](/documentation/universal-fan-controller/configuration/model-config-files.md)
    - Set the default BMC fan schema for a specific motherboard model.
    - This method is preferred.
3. [Builder](/documentation/configuration/builder-config-file.md)
    - Force the Builder to use a particular BMC fan schema, ignoring the setting from other config files.
    - This method should be considered a **last resort** as it is dangerous for several reasons. Notably, if the selected BMC fan schema ID is not found by the Builder to be correlated with the motherboard manufacturer, the Builder will abort with an error.

> [!TIP]
> It is OK to assign the BMC fan schema in more than one place.
> Just make sure the last config file in the sequence updates the BMC schema parameter with the correct information as it will take precedence.

---

## 3. Add New Motherboard Manufacturer
Motherboard manufacturer-specifc configuration files are `.conf` extension files found in the directory `/config/manufacturer/`

Here is the process to create a new one in order to support a new motherboard manufacturer:
1. Create new sub-directory under `/config/manufacturer/`
    - Directory name must match the first word of the manufacturer brand name and must be lowercase
2. Make a copy of the manufacturer template file `/config/manufacturer-template.conf` and copy it into the `/config/manufacturer/{new-manufacturer-name}/{new-manufacturer-name}.conf` sub-directory.
3. Load the file into a suitable text editor.
4. Customize the copied file per the instructional guidance on [editing manufacturer configuration files](/documentation/configuration/manufacturer-config-files.md).
5. Remove unnecessary or irrelevant information.
6. Un-comment any relevant lines, and/or edit them accordingly.

> [!NOTE]
> It may be helpful to examine the related function `validate_mobo_model` to better understand how the motherboard manufacturer/brand name is parsed (locate the include file `validate_mobo_model.sh` in the Builder's include files source directory).

Proceed with the following steps:
1. Check [the list](supported-hardware-manufacturers.md) of supported and non-supported motherboard manufacturers.
2. Add the motherboard manufacturer name to the list of "Supported Motherboard Manufacturers"
3. Check whether or not the newly supported manufacturer name is present in the [Non-Supported Motherboard Manufacturers](supported-hardware-manufacturers.md#non-supported-motherboards) list on the same page. If so, remove it.
4. Update the include files indicated below.

### Update Related Functions
Review the following include files and update them as necessary to recognize and support motherboards from the new manufacturer. This means adding small sections of code to allow UFC to understand how to configure the new motherboard manufacturer's boards:
1. [set_lower_fan_thresholds.sh](#set_lower_fan_thresholdssh)
2. [validate_bmc_command_schema.sh](#validate_bmc_command_schemash)
    - Modifying this file should be considered an advanced method and is only applicable under particular circumstances:
      - There is more than one possible BMC command schema for the same motherboard manufacturer.
      - At least some motherboard models can be quantified by a measurable pattern.
    - This function is able to assign BMC fan schema when one is not assigned via other means, and the criteria above are met.
3. [validate_mobo_model.sh](#validate_mobo_modelsh)
4. [enable_manual_fan_control.sh](#enable_manual_fan_controlsh)
    - Optional. Update only when necessary (depends on motherboard behavior).
5. [execute_ipmi_fan_payload.sh](#execute_ipmi_fan_payloadsh)
    - Mandatory. The most important file to update. Here you will specify the IPMI commands necessary to implement a fan speed change.
6. [set_all_fans_mode.sh](#set_all_fans_modesh)

---

## 4. Add New Motherboard Model
Adding support for a motherboard model not already supported (by a specific pre-existing model `.conf` file) can be handled with or without a custom motherboard-model specific configuration file. However, a manufacturer-specific sub-directory and configuration file are required at a minimum.

An independent configuration file for each motherboard model is not always required, but is always recommended.

### Pre-requisites
A manufacturer-level configuration file must exist. If one does not, [create it](#add-support-for-new-motherboard-manufacturer) first, then return to this section.

### Motherboard Manufacturer NOT Known to UFC
- Setup a new motherboard manufacturer [must be created first](#how-to-setup-support-for-a-new-motherboard-manufacturer), then start over this 'How To' section.
- Make a copy of the motherboard model template specific to the manufacturer, if one exists.
- Create a new model .conf file following instructions in section 1 above.

### Create New Model Config File
Create a new motherboard model configuration (`.conf`) file.
1. If there is one, locate the manufacturer-specific model config template. If not, locate the generic template: `/config/model-template.conf`
2. Copy the model template to (or within, if applicable) the manufacturer sub-directory `/universal_fan_controller/config/manufacturer/MODEL.conf`
3. Load the file into a suitable text editor.
4. Customize the copied file per this [guidance on editing model config files](/documentation/universal-fan-controller/configuration/model-config-files.md).
5. Remove unnecessary or irrelevant information.
6. Un-comment any relevant lines, and/or edit them accordingly.
7. Save the file.
8. Determine the BMC fan schema command model necessary to support the motherboard model.
9. If the BMC fan schema is declared in the motherboard manufacturer configuration file as the default fan schema, stop here as you are done.
10. Decide on a name for a new BMC fan schema to support the new motherboard model, and [create it](#add-a-new-bmc-fan-schema).
11. Add a variable declaration statement in the new motherboard model configuration file referencing the new BMC fan schema ID.

---

## 5. Specify Fans in Each Fan Zone

<<>>

`fan_group_category` = type

`fan_group_label` = name or label of fan group schema
- indexed array
- value = label/name; human-readable; may contain spaces

`fan_group_schema` = groupings of related fan header names
- indexed array
- array index position is fixed and correlates to its fan group label
- value = delimited list of fan header names; common delimiters expected
- acceptable delimiters: `,.:;|/\-`

how setup fan zone ids?
- when fan control method = zone, then the fan groups are considered zones
- in other words, if FANx where x = integer means all those fans should be considered zone 0, then fan group 0 would need to have assigned to it all of those fan header names
