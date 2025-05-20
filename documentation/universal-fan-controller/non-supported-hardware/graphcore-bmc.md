# Graphcore BMCs
Graphcore makes machine learning IPU's (Intelligent Processing Units). While UFC doesn't officially support motherboards with Graphcore BMC chips, it should be possible to at least incorporate monitoring with it, though some customization would be required. It is less clear whether setting fan speeds manually is possible, particularly via IPMI commands. Compatibility has not been tested as of December 2024.

## Unique Approach
Graphcore servers include a proprietary BMC (Baseboard Management Controller) commands for hardware management. 

Based on the OpenBMC platform, Graphcore's BMC utilizes a novel approach to server management, supporting REST, Redfish, and IPMI command interfaces. 

> [!NOTE]
> Graphcore maintains an [online manual](https://docs.graphcore.ai/projects/bmc-user-guide/en/latest/index.html) for its current BMC implementation

While lacking overt details from an IPMI command perspective, the online manual does contain a fairly comprehensive list of [IPMI command operations](https://docs.graphcore.ai/projects/bmc-user-guide/en/latest/ipmi-commands.html) and some examples of sensor query command output. However, it lacks details of specific command bytes for fan sensors or IPMI functionality, and neglects to confirm IPMI command structure. See [Select Raw Command Bytes](#select-raw-command-bytes) for a snapshot of commands potentially relevant to UFC (untested/not confirmed).

### Communicating with the Graphcore BMC
Various hardware features, such as temperature and fan controls, may be managed via the Redfish (REST API) interfaces, IPMI, and custom Graphcore utilities, such as `ipum-utils`. For IPMI-specific tasks, commands should allow sensor monitoring and adjustments, but detailed proprietary extensions may require assistance from Graphcore's support resources to figure out.

## Supported IPMI Commands
A complete list of supported IPMI commands may be found [here](https://docs.graphcore.ai/projects/bmc-user-guide/en/latest/ipmi-commands.html). 
- "sdr" parameters
- "sensor" parameters
	- Command is "sensor_list"
	- Returned values correspond to critical high and low values, and warning high and low values
	- Threshold labels are non-standard
		- CRIT_HIGH
		- CRIT_LOW
		- WARN_HIGH
		- WARN_LOW

### Example Sensor command output
The Graphcore BMC reports fan speeds for each fan header.
<pre>
$ ipmi-utils sensor_list
NAME                                VALUE  CRIT_HIGH  WARN_HIGH   CRIT_LOW   WARN_LOW      SCALE       UNIT
fan0_0                              16319      18356      17522       7471       8405          0       RPMS
fan0_1                              15264      16911      16142       5040       5670          0       RPMS
</pre>

## Fan Sensor Organization and Naming Convention
Much like the unique architectural design of its BMC, Graphcore's case fan implementation methodology is also unusual and bucks industry standards. For instance, each fan "module" consists of two fan rotors: one high-speed and one low-speed. High-speed fan rotors are named with a “0” suffix, while the low-speed fan rotors are named with a “1” suffix.

These "modules" are treated similarly to Supermicro's fan "zone" system found on many of its server boards, though Graphcore's fan "modules" always consist of a fan pair (low/high speed rotor combo). Each fan module is treated as a single fan from a fan header perspective. Essentially, Graphcore expects every fan header to be 6-pin.
- Supports maximum of 5 physical fan "modules" and 10 fan speed sensors
- Fans are grouped into fan "modules"
	- Similar to Supermicro's fan "zones," but Graphcore refers to them as "modules"
- Integer based IDs only, utilizing a 2-digit fan ID format
- Each pair of fans belongs to a single module
	- First digit of fan ID is fan module number
	- Second digit of fan ID is fan number within the module
	- Each module is limited to a maximum of two (2) fan headers
	- The high-speed fan rotor is always fan 0
	- The low-speed fan rotor is always fan 1

### Fan Nomenclature
- Fan headers are numbered incrementally using only integers, beginning with 0, and organized in pairs
- Nomenclature format: `{fan zone #}_{fan header #}`
- The fan zone is between 0 and 4
- Each fan header number is always 0 or 1 (denoting which fan in the pair, high or low speed)
- There is a maximum of 10 possible fan headers in total

### Examples
- fan ID "fan0_0" means "high speed fan of fan module 0"
- fan ID "fan0_1" means "low speed fan of fan module 0"
- fan3_0 and fan3_1 both belong to fan module 3
- fan0_0 is "module 0, fan 0"
- fan0_1 is "module 0, fan 1"
- fan4_1 is "module 4, fan 1"

## Extremely High Fixed Fan Speeds
As a proprietary BMC, Graphcore expects fans to operate within a precisely pre-determined speed range, depending on their power input level (fan duty). I find this to a very odd approach, but the Graphcore ecosystem is unlike most server ecosystems, especially when it comes to IPMI management of its servers. At 40% and above power applied to the fans, the Graphcore BMC expects the fans to be within +/- 5% of particular speeds. A chart of these speeds can be found [here](https://docs.graphcore.ai/projects/bmc-user-guide/en/latest/fan-pwm.html). Based on these pre-ordained levels, the fans have an implied top-end of 30,000 RPM (technically 29,942 RPM, to be exact) and are presumably rated as 26k or 27k. This is an insanely high figure for most servers.

### Expected Fan PWM Speed Mapping
The Graphcore expects all fans to be capable of the same maximum fan speed. It makes rough equations between fan duty cycle (% PWM) and its expectation of fan speed at that power level. The BMC then adds and subtracts a 5% buffer above and below the expected speed, and presumes any given fan should be within that range.

For example, the highest fan speed (100% PWM) is expected to be 28,516 RPM. However, adding 5% to it yields 29,942 RPM. Thus, the BMC will by default expect the absolute top range of 100% PWM to be 29.942 RPM. Any reading higher than that will cause the BMC to believe the given fan is spinning faster than it should be (out of range).

Graphcore's BMC has built in "low" and "high" fan speed modes. These modes equate to pre-determined PWM percentages, notwithstanding the aforementioned maximums.

> [!WARNING]
> Graphcore BMCs use fixed PWM → RPM tables with ±5% mechanical tolerance instead of hysteresis.
> 
> See the [Graphcore BMC user guide](https://docs.graphcore.ai/projects/bmc-user-guide/en/latest/fan-pwm.html) for more information.

## Built-in Thermal Triggers
The Graphcore BMC has some built-in protections which will cause automatic server shutdown when either of these circumstances occur:
1. Air inlet temperature exceeds 50 degrees Celsius
2. Exhaust air temperature exceeds 80 degrees Celsius

## IPMI Raw Command Bytes
| Function                               | NetFn | Command |
| -------------------------------------- | ----- |:-------:|
| set sensor event                       | 0x04  | 0x00 |
| get sensor event                       | 0x04  | 0x01 |
| get device SDR info                    | 0x04  | 0x20 |
| get device SDR                         | 0x04  | 0x21 |
| get sensor hysteresis                  | 0x04  | 0x25 |
| set sensor threshold                   | 0x04  | 0x26 |
| get sensor threshold: hex command      | 0x04  | 0x27 |
| get sensor reading                     | 0x04  | 0x2d |
| warm reset                             | 0x06  | 0x03 |
| cold reset                             | 0x06  | 0x02 |
| get device id                          | 0x06  | 0x01 |
| get system GUID                        | 0x06  | 0x08 |
