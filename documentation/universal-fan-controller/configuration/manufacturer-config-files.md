# Customizing Motherboard Manufacturer Config Files (Walk-thru)
As mentioned in [Program Architecture and Design](program-design.md#configuration-files), the Universal Fan Controller (UFC) relies on a number of layers of configuration files to define many critical operating parameters. Some configuration files pertain to the characteristics of the motherboards themselves. Specifically, the manufacturer/brand and potentially the motherboard model. These levels of granularity in config files allow superior flexibility in customizing how UFC governs cooling fans on any given motherboard.

There aren't very many parameters that belong in the manufacturer specific configuration files. These files are intended to set the default for the most important variables that will almost always apply to every motherboard produced by the manufacturer. Including this information at this level of config file serves the following purposes:
1. Greater efficiency, by consolidating common parameters as high in UFC's [nested configuration file schema](program-design.md#nested-motherboard-config-files) as possible. This avoids redundancy in lower-level config files.
2. Prevent UFC installs from aborting because the end user forgot to declare critical, required variables that are constant across related motherboards.

## Mission Critical
While the user-defined [Builder configuration file](/documentation/configuration/builder-config-file.md) schema is focused on customizing how UFC governs server fan controls, motherboard related config files are first-and-foremost focused on setting parameters necessary for UFC to operate at all. Certain variables are required in order for UFC to run at all. If any are missing or unknown, the Builder cannot continue. Certain optional variables may also be specified in a motherboard manufacturer or model-specific configuration file. 

> [!NOTE]
> Critical parameters may be defined in any config file so long as it is part of the configuration chain loaded by the Builder.
>
> For example, even without a manufacturer or model-specific config file, a user could ostensibly add these crucial values to the user-defined Builder config file.
>
> This practice is strongly discouraged, but it is an option.

## Manufacturer Config Files
Every supported motherboard manufacturer has its own configuration file. These should be found as `/config/{manufacturer}/{manufacturer}.conf`. Under each manufacturer configuration directory, there may also be model-based configuration files. The filename location for these will follow this protocol: `/config/{manufacturer}/{MODEL}.conf` where the model name will be in ALL CAPS (preceding the _.conf_ file extension). The model filename may be an abbreviated version of the actual model name, being stripped of special characters.

As explained [here](program-design.md#builder-config-stacking-rules), when it exists, the manufacturer-level config file will be loaded first by the Builder, followed by the model config file (if one exists). The user-defined Builder config file (which must exist) will be loaded last. Each subsequently loaded configuration file may override parameters defined in the previous config file(s), if any.

## Required Variables
These variables are required in order for UFC to operate at all. They can be placed directly in the UFC versioned config file (user-defined), though this practice is strongly discouraged. The purpose of keeping these parameters in a shared motherboard manufacturer configuration file is to establish baselines for a range of motherboards produced by the same manufacturer, effectively establishing default values. When these defaults are inappropriate for a given server motherboard or a user's requirements, they may be overridden via either a motherboard model-specific configuration file or the user-defined Builder config file.

> [!NOTE]
> These variables pertain only to the Service Runtime program. They are passed from the Builder program during the dynamic _.init_ file creation process.

## Fan Control Methods
The "fan control method" describes the method by which a given server motherboard's BMC is capable of receiving IPMI commands. A motherboard always supports at least one, and may support more than one method. This value may be set at the manufacturer level or the motherboard level, depending on whether or not every server motherboard produced by the manufacturer utilizes the same method.

When more than one method is available, the choice boils down to user-preference. However, it is wise to implement a default mode either here or in the motherboard model config file so that there is a default. Best practice advice regarding this choice may be found [here](best-practices.md#default-fan-control-method).

Choices are:
1. Universal: all fans at once
2. Direct: fans may be controlled individually
3. Zone: fans are controlled by groups called 'zones'
4. Group: fans may be controlled individually, but commands must address all fans simultaneously as a group

```
fan_control_method="universal"
```

## IPMI Command Schema
This variable pertains to setting a default value for the IPMI fan command schema applicable to the current motherboard. BMC schemas are pre-defined sets of IPMI commands, specific to a given manufacturer. Each manufacturer may have multiple possible sets of IPMI commands that work with its motherboards. When that is the case, it is necessary to understand which schemas is supported by a given motherboard model. _Each motherboard model only supports one BMC schema_, while a manufacturer could support more than one.

```
bmc_command_schema="dell-v1"
```

Server motherboards produced by the manufacturer that support manual fan speed control via IPMI

A manufacturer-level config file may define a default BMC schema. This is generally prudent under either of two scenarios:
1. All known motherboards follow the same pattern of IPMI command structure.
2. Some boards require an alternate pattern of IPMI command structure, but there is a particular pattern that is predominant among most boards.

When a majority of boards produced by the manufacturer follow the same pattern of IPMI command structure, it makes sense to define that BMC schema in the manufacturer-level config file. When not the case, such as when the IPMI command pattern varies widely among motherboard models, it may be unwise to do so.

The following functions (subroutines) are impacted by the BMC schema choice:

- enable_manual_fan_control
- execute_ipmi_fan_payload
- set_all_fans_mode
- validate_bmc_command_schema

## Sensor Metadata
UFC expects `ipmitool` and possibly `lm-sensors` to be available for collecting various types of sensor information. **_lm-sensors_** is the program behind the `sensors` command (Ubuntu/Debian) and is the preferred method of reading CPU temperatures. If **lm-sensors** is not installed, either the `sensor` or `sdr` commands of `ipmitool` will be used instead.

`ipmitool` is required to fetch other data types - particularly fan metadata - and to manage [fan speed thresholds](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md).

The following values must be integers. Each field reference indicates the column number associated with the given data field.

------------------------------------------------

## IPMI `sensor` Output Mapping
Output from IPMI 'sensor' queries is mapped to several arrays. The IPMI 'sensor' command outputs various fan metrics. In order to parse this information, UFC needs to understand the relationship of output columns to the metrics it tracks.

> [!NOTE]
> The column values indicated below are _examples_ and are not fixed. They indicate corresponding column positions, and their values may vary.

### CPU Temperature Metrics
Output from IPMI 'sensor' queries pertaining to CPU temperatures is stored in this associative array: `ipmi_sensor_column_cpu[]`

#### CPU ID
The CPU ID column indicates the CPU ID as an integer. This column describes which CPU ID is related to the other data same output row. CPU IDs begin with either 0 or 1, depending on the motherboard manufacturer.

```
ipmi_sensor_column_cpu[id]=1
```

#### CPU Temperature
IPMI `sensor` column. Applicable to Service Runtime program only (passed through via Builder).

```
ipmi_sensor_column_cpu[temp]=4
```

### Fan Metrics
Defines mapping of output from IPMI `sensor` query column positions pertaining to fan metrics. Values are stored in this associative array: `ipmi_sensor_column_fan[]`

#### Fan Header Name
Fan header name column number. This is the field position of the output column displaying the name/ID of each fan header reported by the BMC. The value should almost always = 1.

```
ipmi_sensor_column_fan[name]=1
```

#### Fan Speed
Column number containing the rotational speed of each fan header.

```
ipmi_sensor_column_fan[speed]=3
```

#### Fan State
Column number containing the current status of each fan header.

```
ipmi_sensor_column_fan[status]=7
```

### Fan Thresholds
More IPMI sensor output field column mappings. These pertain to [BMC fan speed thresholds](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md#fan-speed-threshold-reporting-order).

#### Lower Fan Speed Thresholds
The *lower* fan speed thresholds comprise metadata for each fan.
> LNR: Lower Non-Recoverable
> LCR: Lower CRitical
> LNC: Lower Non-Critical

Their corresponding column values need to be entered like this:

```
ipmi_sensor_column_fan[lnr]=9
ipmi_sensor_column_fan[lcr]=11
ipmi_sensor_column_fan[lnc]=13
```

#### Upper Fan Speed Thresholds
The *Upper* fan speed thresholds comprise metadata for each fan.
> UNC: Upper Non-Critical
> UCR: Upper CRitical
> UNR: Upper Non-Recoverable

Enter their corresponding column values like this:

```
ipmi_sensor_column_fan[unc]=15
ipmi_sensor_column_fan[ucr]=17
ipmi_sensor_column_fan[unr]=19
```

> [!NOTE]
> Fan hysteresis is not currently utilized by UFC

### Fan Hysteresis
Field/column position in IPMI sensor output for [fan hysteresis](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md#fan-hysteresis).

```
ipmi_sensor_column_fan[hysteresis]=5
```

---

## IPMI `sdr` Output Mapping
Defines the mapping of output column positions from IPMI 'sdr' queries. The IPMI 'sdr' command outputs various fan metrics. In order to parse this information, UFC needs to understand the relationship of output columns to the metrics it tracks.

Output from IPMI 'sdr' queries is mapped to the `ipmi_sdr_column_cpu[]` array.

> [!NOTE]
> IPMI `sdr` is only used by UFC to track CPU ID and current temperature.
> 
> The column values indicated below are _examples_ and are not fixed. They indicate corresponding column positions, and their values may vary.

These variables pertain only to the Service Runtime program. They are passed from the Builder program during the dynamic _.init_ file creation process.

Output from IPMI 'sensor' queries pertaining to CPU temperatures is stored in this associative array: `ipmi_sdr_column_cpu[]`

### CPU Temperature
The ID column indicates the CPU ID as an integer. This column describes which CPU ID is related to the other data same output row. CPU IDs begin with either 0 or 1, depending on the motherboard manufacturer.

The IPMI `sdr` command provides an alternative method of reading CPU temperatures, as compared to IPMI `sensors` and the `sensors` (**lm-sensors**) command. IPMI has secondary priority for this purpose unless the **lm-sensors** program is not available. These field mappings should be included regardless as a failsafe measure.

```
ipmi_sdr_column_cpu[id]=1
```

### CPU ID
CPU ID column. Identifies the ID of the CPU to which other metadata on the same row is associated.

```
ipmi_sdr_column_cpu[temp]=4
```

---

## `sensors` (lm-sensors) Output Mapping
Defines the mapping of output column positions from the 'sensors' command (**lm-sensors** program). In order to parse this information, UFC needs to understand the relationship of output columns to the metrics it tracks.

Output from 'sensors' queries is mapped to the `ipmi_sensor_column_cpu_temp[]` array.

> [!TIP]
> `sensors` is an alternative to `ipmitool` for CPU temperature scanning.
>
> It has a much faster response time versus IPMI, and is the only CPU temperature tracking tool utilized by UFC that is able to track CPU temperature at both the physical (CPU die) level and individual core temperatures.

**lm-sensors** is significantly quicker than `ipmitool` at temperature polling.
1. lm-sensors CPU mode is ~10x faster than IPMI `sensor` CPU temperature queries
2. lm-sensors CPU mode is ~7.5x faster than its 'core' mode
3. lm-sensors 'core' mode is ~25% faster than IPMI `sdr`

### CPU Core ID Column
CPU core ID column for `sensors` command (**lm-sensors**).

```
ipmi_sensor_column_cpu_temp[core_id]=2
```

### CPU Core Temperature Column
Core CPU temperature column for `sensors` command.

```
ipmi_sensor_column_cpu_temp[core_temp]=3
```

### CPU Temperature Column
Physical CPU temperature column for `sensors` command.

```
ipmi_sensor_column_cpu_temp[physical]=4
```

### CPU High Temperature Threshold Column
Column number reference of the _high_ CPU / CPU core temperature threshold.

This is an objective limit based on the CPU manufacturer's specification.

```
ipmi_sensor_column_cpu_temp[high]=6
```

### CPU Critical Temperature Threshold Column
Column number reference of the _critical_ CPU / CPU core temperature threshold.

This is an objective limit based on the CPU manufacturer's specification.

```
ipmi_sensor_column_cpu_temp[critical]=9
```
