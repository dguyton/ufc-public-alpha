# Customizing Motherboard Model Config Files (Walk-thru)

--------------------------------------------

model-specific vars

<<>>


### Single Fan Group
True/False flag indicating whether or not all fans should be treated as belonging to the same group.

The main purpose of this flag is to inform 

> only_cpu_fans=true

logical fan group schemas
> fan_group_schema[0]="FAN0,FAN1,FAN2,FAN3,FAN4,FAN5,FAN6,FAN7,FAN8,FAN9"

logical fan group labels
> fan_group_label[0]="cpu"

## Optional Variables
These variables are necessary for UFC to operate, but there is some freedom to declare them either here or in the model-level config files. As a general rule, the litmus test should be, "Will these values be the same for most or all motherboards from this manufacturer?" When the answer to that question is, "Yes" then it is prudent to include this information in the manufacturer-level configuration. The purpose of keeping these parameters in a shared motherboard manufacturer configuration file is to establish baselines for a range of motherboards produced by the same manufacturer, effectively establishing default values. When these defaults are inappropriate for a given server motherboard or a user's requirements, they may be overridden via either a motherboard model-specific configuration file or the user-defined Builder config file.

> [!WARNING]
> _Required when **lm-sensors** program not installed._

> [!IMPORTANT]
> Review all variable descriptions carefully.
> 
> Under particular circumstances, certain variables listed below as _Optional_ are actually **Required**.

# Customizing Motherboard Model Config Files (Walk-thru)

### IPMI `sensor` Output Map
Defines the mapping of output column positions from IPMI 'sdr' queries. IPMI is typically not used for this purpose unless the **lm-sensors** program is not available. However, these field mappings should be included regardless as a failsafe measure.

The IPMI 'sdr' command outputs various fan metrics. In order to parse this information, UFC needs to understand the relationship of output columns to the metrics it tracks. These variables provide that mapping information. 


----------------------------------------------------------
### Fan Header ID
Fan header ID column number. This is the number of the output column displaying the name/ID of each fan header reported by the BMC. Must be an integer, pointing to the column number associated with this data field.

This should almost always = 1.

> `sdr_id_column`

### Current Fan Speed
Current fan speed column number. This is the name/ID of each fan header reported by the BMC. Must be an integer, pointing to the column number associated with this data field..

Speed is reported as an integer, representing current fan RPM.

> `sdr_speed_column`

### Current Fan Status
Current fan status column. This is the current status of each fan header reported by the BMC. Must be an integer, pointing to the column number associated with this data field.

> `sdr_status_column`

### CPU ID
CPU id column for ipmitool sdr output.

> `ipmi_cpu_id_column`

Must be an integer.
### CPU Current Temperature

CPU temperature sdr output column number for ipmitool.

> `ipmi_cpu_temp_column`

> [!NOTE]
> While **lm-sensors** is the preferred method of reading current CPU temperatures, if it is not installed, then **ipmitool sdr** will be used instead to collect this information.

Must be an integer.

## ipmitool Sensor Outputs
These fields pertain to parsing the output from the `ipmitool sensor` command.

For each respective parameter, indicate the appropriate column number for each line of `sudo ipmitool sensor` output corresponding to the given data field.

### Fan Header ID
Fan header ID column number. This is the number of the output column displaying the name/ID of each fan header reported by the BMC. Must be an integer, pointing to the column number associated with this data field.

This should almost always = 1.

> `ipmi_sensor_id_column`

### Current Fan Speed
Current fan speed column number. This is the name/ID of each fan header reported by the BMC. Must be an integer, pointing to the column number associated with this data field..

Speed is reported as an integer, representing current fan RPM.

> `ipmi_sensor_speed_column`

### Current Fan Status
Current fan status column. This is the current status of each fan header reported by the BMC. Must be an integer, pointing to the column number associated with this data field.

> `ipmi_sensor_status_column`

### Lower Critical Fan Speed Thresholds
Lower fan speed threshold field positions in IPMI sensor output.

There are three (3) LOWER fan speed thresholds stored in the BMC for each fan header. These values indicate a fan's speed is too slow, and appears to be operating out-of-bounds of the fan's normal operating speed range in RPMs. 

When a given fan falls below one of these values, it triggers alerting software in the BMC. Depending on which alert threshold is violated, the BMC may decide the system is in danger and that it is necessary to override the current fan speed programming and push all fans in all fan zones to maximum speed, in order to protect the system hardware from potential heat-related damage. This is the state referred to in this documentation in various places as, "panic mode" or "fan panic mode" of the BMC.

These threshold values are stored independently for each fan header. Thus, even if there are a mish-mash of fans installed in the same fan zone, each fan may have its own set of lower and upper critical fan speed thresholds. This is useful as it prevents the system from panicking when one fan is slower or faster than the others in the same fan zone, as this could be a normal and expected condition.

Out-of-the-box, server motherboards come with pre-defined values pre-coded into the BMC for these upper and lower fan speed thresholds. They may be set to arbitrary values considered conservative or the motherboard manufacturer may have hard-coded various levels to correspond with their expectations for how a particular motherboard is likely to be found in the field, such as bundled with a particular chassis commonly packaged with a known quantity of fans.

Regardless of your board's pre-existing circumstances, the PID fan controller setup program will take an inventory of these values, and depending on your settings may adjust them. 

The runtime program does not monitor these values in real-time. This is another good example of why any changes to your motherboard fans or fan settings not performed by the PID Fan Controller should prompt you to re-run the setup program, so that any relevant changes which will impact the runtime program are accounted for.

###### Lower Non-Recoverable (LNR)
The _Lower Non-Recoverable_ or **LNR** value is the lowest of the lower speed thresholds. When a fan's speed reaches this speed or lower, it is considered _non-recoverable_, meaning the fan has failed. If the given fan's speed breaches this level, the BMC will enter into panic mode.

> `lnr_field_column`

Must be an integer.

#### Lower CRitical (LCR)
The _Lower CRitical_ or **LCR** value is the middle of the lower speed thresholds. When a fan's speed reaches this speed or lower, it is considered _critical_, meaning for some reason the fan has slowed to the point of endangering the system, and the fan may be failing. If the given fan's speed breaches this level, the BMC will enter into panic mode.

> `lcr_field_column`

#### Lower Non-Critical (LNC)
The _Lower Non-Critical_ or **LNC** value is the highest of the lower speed thresholds. When a fan's speed reaches this speed or lower, it is considered _at risk, but not yet critical_, meaning for some reason the fan is exhibiting unusually slow speed behavior, but not quite to the point of potentially endangering the system. If the given fan's speed breaches this level, the BMC's panic mode will _not_ be triggered.

> `lnc_field_column`

### Upper Critical Fan Speed Thresholds
Upper fan speed threshold field positions in IPMI sensor output.

There are three (3) UPPER fan speed thresholds stored in the BMC for each fan header. These values indicate a fan's speed is too fast, and appears to be operating out-of-bounds of the fan's normal operating speed range in RPMs.

When a given fan rises above one of these values, it triggers alerting software in the BMC. Depending on which alert threshold is violated, the BMC may decide the system is in danger and it is necessary to override the current fan speed programming and push all fans in all fan zones to maximum speed, in order to protect the system hardware from potential heat-related damage. This is the state referred to in this documentation in various places as, "panic mode" or "fan panic mode" of the BMC.

This may seem counter-intuitive. Why would the BMC attempt to push all fans to their highest duty level if one ore more fans are spinning too quickly? Unfortunately, the BMC's logic is rather rudimentary. It essentially views the CPU and system fans in one of only two states: active or inactive. And, with regards to an _active_ fan header, the BMC sees that fan header as either operating within an acceptable range, or not. The "acceptable range" from the perspective of the BMC is any speed between the lower critical (LCR) and upper critical (UCR) values. As soon as any fan crosses either line, the BMC considers that fan to have failed, and takes evasive action to protect the system.

> The BMC monitors all active fan speeds in real-time. Therefore, if a fan's behavior causes the BMC to initiate its fan panic mode, and subsequently the fan speed falls back within its expected operating range, the BMC will discontinue panic mode and fan control will revert back to its previous state (e.g. PID fan controller will regain control). Typically, this occurs when one or more fans breach their lower critical thresholds, which causes all the fans to get spun up faster, when then pushes the fan speeds above the lower critical limits, which then de-activates the BMC's panic mode reaction. When the lower fan speed boundaries are set too low for a given fan, this will tend to cause a cycle of the BMC going in and out of panic mode repeatedly as the fan in question falls below the critical threshold, then recovers, then repeats, etc.

These threshold values are stored independently for each fan header. Thus, even if there are a mish-mash of fans installed in the same fan zone, each fan may have its own set of lower and upper critical fan speed thresholds. This is useful as it prevents the system from panicking when one fan is slower or faster than the others in the same fan zone, as this could be a normal and expected condition.

Out-of-the-box, server motherboards come with pre-defined values pre-coded into the BMC for these upper and lower fan speed thresholds. They may be set to arbitrary values considered conservative or the motherboard manufacturer may have hard-coded various levels to correspond with their expectations for how a particular motherboard is likely to be found in the field, such as bundled with a particular chassis commonly packaged with a known quantity of fans.

Regardless of your board's pre-existing circumstances, the PID fan controller setup program will take an inventory of these values, and depending on your settings may adjust them. 

The runtime program does not monitor these values in real-time. This is another good example of why any changes to your motherboard fans or fan settings not performed by the PID Fan Controller should prompt you to re-run the setup program, so that any relevant changes which will impact the runtime program are accounted for.

#### Upper Non-Critical (UNC)
The _Upper Non-Critical_ or **UNC** value is the lowest of the higher speed thresholds. When a fan's speed exceeds this speed or higher, it is considered _at risk, but not yet critical_, meaning for some reason the fan is exhibiting unusually fast speed behavior, but not quite to the point of potentially endangering the system. If the given fan's speed breaches this level, the BMC's panic mode will _not_ be triggered.

> `unc_field_column`

Must be an integer.

#### Upper CRitical (UCR)
The _Upper CRitical_ or **UCR** value is the middle of the upper speed thresholds. When a fan's speed exceeds this speed or higher, it is considered _critical_, meaning for some reason the fan speed has increased to the point of endangering the system, and the fan may be failing. If the given fan's speed breaches this level, the BMC will enter into panic mode.

> `ucr_field_column`

Must be an integer.

#### Upper Non-Recoverable (UNR)
The _Upper Non-Recoverable_ or **UNR** value is the lowest of the lower speed thresholds. When a fan's speed exceeds this speed or higher, it is considered _non-recoverable_, meaning the fan is spinning out of control and has presumably failed. If the given fan's speed breaches this level, the BMC will enter into panic mode.

> `unr_field_column`

Must be an integer.

### Fan Hysteresis Column
Field/column positition in IPMI sensor output for fan hysteresis data.

> `ipmi_fan_hysteresis_column`

Must be an integer.

### lm-sensors Output Field Mappings
`lm-sensors` is an alternative to `ipmitool` for CPU temperature scanning, with a much faster runtime.

### CPU ID Column
CPU id column for _lm-sensors_ command.

> `sensors_cpu_core_id_column`

Must be an integer.

### CPU Temperature Column
Physical CPU temperature column for _lm-sensors_ command.

> `sensors_cpu_core_temp_column`

Must be an integer.

### CPU Core Temperature Column
Core CPU temperature column for _lm-sensors_ command.

> `sensors_cpu_physical_temp_column`

Must be an integer.

### CPU High Temperature Threshold Column
Column number reference of the _high_ CPU / CPU core temperature threshold. This is an objective limit based on the CPU manufacturer's specification.

> `sensors_cpu_high_temp_column`

Must be an integer.

### CPU Critical Temperature Threshold Column
Column number reference of the _critical_ CPU / CPU core temperature threshold. This is an objective limit based on the CPU manufacturer's specification.

> `sensors_cpu_critical_temp_column`

Must be an integer.



--------------------------------------------

model-specific vars

<<>>


### Single Fan Group
True/False flag indicating whether or not all fans should be treated as belonging to the same group.

The main purpose of this flag is to inform 

> only_cpu_fans=true

logical fan group schemas
> fan_group_schema[0]="FAN0,FAN1,FAN2,FAN3,FAN4,FAN5,FAN6,FAN7,FAN8,FAN9"

logical fan group labels
> fan_group_label[0]="cpu"

## Optional Variables
These variables are necessary for UFC to operate, but there is some freedom to declare them either here or in the model-level config files. As a general rule, the litmus test should be, "Will these values be the same for most or all motherboards from this manufacturer?" When the answer to that question is, "Yes" then it is prudent to include this information in the manufacturer-level configuration. The purpose of keeping these parameters in a shared motherboard manufacturer configuration file is to establish baselines for a range of motherboards produced by the same manufacturer, effectively establishing default values. When these defaults are inappropriate for a given server motherboard or a user's requirements, they may be overridden via either a motherboard model-specific configuration file or the user-defined Builder config file.

> [!WARNING]
> _Required when **lm-sensors** program not installed._

> [!IMPORTANT]
> Review all variable descriptions carefully.
> 
> Under particular circumstances, certain variables listed below as _Optional_ are actually **Required**.
