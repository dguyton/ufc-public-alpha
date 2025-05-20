# ASRock Fan Controls by BMC Chipset Generation
The Universal Fan Controller (UFC) applies BMC fan control schemas based on a combination of filters. Together, these factors determine the specific pattern of raw IPMI commands suitable for any given motherboard. For ASRock, this results in over a dozen different possible patterns of IPMI commands based on:
1. Motherboard manufacturer
2. BMC chipset
3. Motherboard model-specific permutations

UFC breaks down these rulesets primarily by BMC chip, but there are also sub-variants based on specific, known anomalies of certain motherboards. Below is a complete list of all possible logic permutations for ASRock server motherboards. They are identified by schema, e.g. "AST2300-v1" is a BMC fan control schema that is the 1st iteration of ASPEED AST2300 BMC chip schemas.

As mentioned [here](/documentation/bmc-and-server-architecture/fan-write-order.md), IPMI fan write order often differs from read order. When fans are addressed in IPMI commands by their individual fan header ID, all fans together, or by zone (group of fans), this is a non-issue. However, then utilizing the 'group' method of writing fan header information - when all fans must be addressed simultaneously in a single IPMI raw command - then it does matter. Since ASRock boards almost always only allow the group method, it is critical to understand each board's write order.

> [!IMPORTANT]
> The `ipmi_order_fan_header_names.sh` include file is loaded by the UFC Builder program, and contains the write-order logic for motherboards observing the 'group' style of fan control methodology (such as ASRock boards).

## Minimum Fan Speed
Many ASRock Rack server boards have a minimum fan speed requirement enforced by the BMC. Fans cannot be set to a fan duty below this level when it exists. Attempts to do so will cause the fan duty to be set to the minimum level.

- Beginning in 2019, some motherboards enforce a minimum fan speed of 20%.
- A few boards have a minimum fan speed of 30%.
- ASRock boards not subject to the 20% or 30% minimums usually enforce a minimum fan speed of 4%.

Any of these thresholds may be enforced on any given motherboard, and it is difficult to know ahead of time what any given board's minimum enforced fan speed is. Within this guide, when this information is known, it will be indicated.

When a minimum required threshold does exist, if any process attempts to set a fan speed below the minimum the request will be ignored. If the fan duty table for smart fan operations contains an invalid (too low) fan duty, it will be ignored and the minimum required value will prevail.

> [!TIP]
> A fan duty level of 0% is not allowed and will be interpreted as a request to set the given fan to Automatic or [Smart Fan](asrock-smart-fan-mode.md) mode.
>
> This means the BMC will control the given fan's speed via a built-in table of thermal thresholds and pre-determined fan speeds.

# AST2300 IPMI Schemas
ASRock motherboards with the ASPEED AST2300 BMC chip.

## AST2300-v1 (2014)
Dual CPU with CPU auto speed override, and no auto speed for other fans. Requires two separate IPMI commands. Reserved bytes at end of string for 8-byte total payload. 8x 4-pin headers. Minimal speed 0x04 may be set for non-CPU fans. 2-command strings required to set all fans. If value set to 0x00, it is treated as "minimal" fan speed (not minimum and not auto).

> [!WARNING]
> "Reserved" bytes are required reserved/header bytes expected by the BMC. Do not omit them.

### Included Boards
- EP2C606-4L/D16
- EP2C602-4L/D16
- EP2C602/D16
- EP2C606-4L
- EP2C602-4L
- EP2C602

### Override Flags
This BMC uses "override" flags for certain fans. Override flags function as follows:
- Byte value `0x00` means ignore CPU fan speed (i.e. do not override and use auto mode)
- Byte value `0x01` means accept CPU fan speed (i.e. do override auto mode and use provided CPU fan speed)

### IPMI Write Command Order
This BMC chipset requires a rather unorthodox means of sending fan control commands via IPMI. Due to the AST2300's small register, coupled with the large number of fans on certain EPYC motherboards utilizing this BMC, it is necessary to split fan write commands into two distinct IPMI raw commands. This is the only way to send separate fan speed commands to every fan header, as the BMC cannot handle receiving all the required fan header bytes in a single command.

When sending write commands, two separate IPMI raw commands must be sent in order to address all fans. Each IPMI command is eight bytes in length, of which six are the data payload.
- 8-byte total raw command payload
- 6 data payload bytes required per command line
- 2 command lines
- Each `raw` command is 8 bytes total, including command bytes

Line 1 addresses CPU fan 1 and 4 other fan headers:
```
ipmitool raw 0x3a 0x01 {cpu_1 override} {CPU_FAN1_1} {REAR_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3}
```

Line 2 addresses CPU fan 2 and the remaining 2 fan headers. 2 reserved bytes complete the 8-byte payload requirement:
```
ipmitool raw 0x3a 0x11 {cpu_2 override} {CPU_FAN2_1} {REAR_FAN2} {FRNT_FAN4} {reserved} {reserved}
```

### Read Current Fan Speeds
```
ipmitool raw 0x3a 0x02
```

Return CPU 1 Override Flag state and Fan ID Speed data in the following order:
```
{cpu_1 override} {CPU_FAN1_1} {REAR_FAN1} {FRNT_FAN_1} {FRNT_FAN_2} {FRNT_FAN3}
```

```
ipmitool raw 0x3a 0x12
```

Return CPU Override 2 Flag state and Fan ID Speed data in the following order:
```
{cpu_2 override} {CPU_FAN2_1} {REAR_FAN2} {FRNT_FAN4} {reserved} {reserved}
```

### Fan Names Reported by IPMI Sensors
- CPU_FAN1_1
- CPU_FAN2_1
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- FRNT_FAN4
- REAR_FAN1
- REAR_FAN2

## AST2300-v2 (2015)
Dual CPUs with auto speed capable for all fans. 6x 4-pin headers. Minimum speed of 0x04. Maximum speed 0x64. Dummy bytes at end of string for 8-byte total data payload.

### Included Boards
- C2550D4I
- C2750D4I
- C2750D4I+

### IPMI Write Command Order
8 data payload bytes required. 1 command line.

```
ipmitool raw 0x3a 0x01 {CPU_FAN1} {CPU_FAN2} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {reserved} {reserved}
```

1. CPU_FAN1
2. CPU_FAN2
3. REAR_FAN1
4. REAR_FAN2
5. FRNT_FAN1
6. FRNT_FAN2

## AST2300-v3 (2017)
Single CPU. Auto-speed capability for every fan. 6x 4-pin headers. Maximum speed 0x64. 8-bytes total data payload. Minimum speed 0x04. Intel C224 chipset.
Setting a fan speed position to 0x00 enables auto speed for that fan header.

### Included Boards
- E3C224D4I-14S

### IPMI Command Order
8 data payload bytes required. 1 command line.

```
ipmitool raw 0x3a 0x01 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {FRNT_FAN5}
```

### Fan names reported by IPMI sensors
1. CPU_FAN1
2. FRNT_FAN1
3. FRNT_FAN2
4. FRNT_FAN3
5. FRNT_FAN4
6. FRNT_FAN5

## AST2300-v4 (2017)
Single CPU. Auto-speed capability for all fans. 3x 4-pin headers. Maximum speed 0x64. 8-byte total data payload. Minimum speed 0x04. Intel C224/C226 chipset.
Setting a fan speed position to 0x00 will enable auto mode for that fan header.

### Included Boards
- E3C224D2I
- E3C226D2I

### IPMI Command Order
8 data payload bytes required. 1 command line.
Setting fan speed position to 0x00 enables auto speed mode. Minimum speed is 4%.

```
ipmitool raw 0x3a 0x01 {CPU_FAN1} {reserved} {REAR_FAN1} {reserved} {FRNT_FAN1} {reserved} {reserved} {reserved}
```

### Fan names reported by IPMI sensors
1. CPU_FAN1
2. REAR_FAN1
3. FRNT_FAN1

# ASPEED AST2400 IPMI Schemas
The vast majority of ASRock boards with the ASPEED AST2400 BMC chip only allow fan configuration via BIOS. This is - unfortunately - a step backwards from the AST2300 board functions.

## AST2400-v1 (2017)
Single CPU. 4-pin fans. 0x00 = auto speed is supported. Intel C232/C236 chipsets.

### Included Boards
- E3C232D2I
- E3C236D2I

### IPMI Auto Fan Mode
ipmitool raw 0x3a 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00

### IPMI Command Order
Fan names reported by IPMI sensors are:
1. CPU_FAN1
2. REAR_FAN1
3. FRNT_FAN1

When compiling IPMI fan write commands, they must be in this order:

```
ipmitool raw 0x3a 0x01 {CPU1_FAN1} {REAR_FAN1} {FRNT_FAN1} {reserved} {reserved} {reserved} {reserved} {reserved}
```

# AST2500 IPMI Schemas
ASRock generally restored and improved manual fan speed control in their server boards with the ASPEED AST2500 BMC chip. The AST2500 has either 8-byte or 16-byte fan data payload requirements, depending on the board. Earlier boards tend to be capable of only 8-bytes, while newer boards tend to require 16-byte payloads. Some boards have a hard limit of 8 or 16 bytes *including the command bytes* (command bytes + data bytes = 8 or 16 bytes total in the command line), while others (usually more recent boards) can process a full 16-bytes flotilla of fan header speeds.

> [!NOTE]
> Through early AST2600 chips, the maximum number of physical fans the ASPEED series can address is 16.

With the AST2500 series, things start to get more interesting with ASRock boards all the way around, in terms of fan control. With most of these boards, it is possible to do the following:
1. Set fan speeds manually for each fan header.
2. Set any given fan header to automatic ("[Smart Fan mode](asrock-smart-fan-mode.md)") mode.
3. Manipulate the temperature threshold tables used to set the Smart Fan fan speeds.

## Forcing Automatic Fan Mode
The AST2500 boards have a short-cut command in the event you wish to reset all fan headers back to their default mode of automatic fan speed control for all fans at once:

```
ipmitool raw 0x3a 0xdc
```

## AST2500 IPMI Command Byte Variability
There is some variation between AST2500 boards with respect to the exact IPMI raw command bytes used to set fan speeds manually. In spite of sharing the same BMC chip, there are slightly different generations of the AST2500 firmware produced by ASRock. Some earlier production models use the prior AST2400 BMC firmware model for IPMI raw commands used to manually control fans. The majority of AST2500 boards utilize a newer, revised set of instrucitons specific to the AST2500, but it appears for some reason there is variation in the early gen boards. This is the primary reason why there are multiple BMC schemas, especially for AST2500 boards.

## AST2500-v1 (2016)
Dual CPU. 7x 4-pin fans.

### Included Boards
- EP2C612 WS

### Fan Names
As reported by IPMI sensors.
- CPU1_FAN1
- CPU2_FAN1
- REAR_FAN1
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- FRNT_FAN4

### IPMI Command Order
IPMI raw mode command order (manual mode).

```
ipmitool raw 0x3a 0x01 {CPU1_FAN1} {CPU2_FAN1} {REAR_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {reserved}
```

### Select IPMI Commands
Set all fans to automatic fan speed control:

```
ipmitool raw 0x3a 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00 {reserved}
```

Set all fans to full speed:
```
ipmitool raw 0x3a 0x01 0x64 0x64 0x64 0x64 0x64 0x64 0x64 0x64
```

Set all fans to 50% speed:
```
ipmitool raw 0x3a 0x01 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32
```

Set all fans to automatic fan speed control:
```
ipmitool raw 0x3a 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v2 (2018)
Single CPU. 3x 4-pin fans. 16-byte data payload.

### Included Boards
- C422 WSI/IPMI
- X299 WSI/IPMI

### Fan Names
As reported by IPMI sensors.
- CPU_FAN1
- FRNT_FAN1
- FRNT_FAN2

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {13x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v3 (2018)
Single CPU. 6x 4-pin fans. 16-byte data payload.

### Included Boards
- D2143D8UM
- D2163D8UM

### Fan Names
As reported by IPMI sensors.
- CPU_FAN1
- SYSTEM_FAN1
- SYSTEM_FAN2
- SYSTEM_FAN3
- SYSTEM_FAN4
- SYSTEM_FAN5

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {CPU_FAN1} {SYSTEM_FAN1} {SYSTEM_FAN2} {SYSTEM_FAN3} {SYSTEM_FAN4} {SYSTEM_FAN5} {10x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v4 (2018)
Single CPU. 6x 6-pin fans. Auto speed control. Intel C242/C246.

### Included Boards
- E3C242D4U
- E3C246D4U
- C246M WS

### Fan Names
Fan names reported by IPMI sensors. These boards support a pair of 4-pin fans per 6-pin fan header. Normally, these will be opposing dual-axle fans. These type of fans are paired. Many boards with 6-pin fan headers report each fan's speed independently (e.g., as FAN_FANx_1 and FAN_FANx_2), but expect a single write command targetted at both fans in the pair, and apply the write command to each fan in the pair simultaneously. However, this board functions slightly differently. When reporting current fan speed, an average speed of the fan pair is reported. Write commands function as expected with this architecture, setting each fan in a pair to the same speed.
- CPU_FAN1
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- REAR_FAN1
- REAR_FAN2

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:
```
ipmitool raw 0x3a 0xd6 {CPU_FAN1} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {10x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v5 (2019)
Single CPU. 6x 6-pin fans. Auto speed control is available for all fans.

### Included Boards
- WC422D8A-2T
- WC422D8A-2T/U

### Fan Names
Fan names reported by IPMI sensors. These boards support a pair of 4-pin fans per 6-pin fan header. Normally, these will be opposing dual-axle fans. These type of fans are paired. Many boards with 6-pin fan headers report each fan's speed independently (e.g., as FAN_FANx_1 and FAN_FANx_2), but expect a single write command targetted at both fans in the pair, and apply the write command to each fan in the pair simultaneously. However, this board functions slightly differently. When reporting current fan speed, an average speed of the fan pair is reported. Write commands function as expected with this architecture, setting each fan in a pair to the same speed.
- CPU_FAN1
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- FRNT_FAN4
- FRNT_FAN5

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {FRNT_FAN5} {10x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v6 (2019)
Single CPU. 7x 6-pin fans. Auto speed control.

The 2nd data payload byte is unknown whether it is a reserved byte or a CPU override byte. It seems most likely to be a reserved byte. Possibly a placeholder created for a potential future configuration of a dual CPU board. It could possibly be a CPU fan override byte, but that would be a holdover from the early AST2300 board configurations, and seems unlikely to be used here. That method is not used in any other ASRock boards after 2014.

### Included Boards
- EPYCD8
- EPYCD8/R32
- EPYCD8-2T
- EPYCD8-2T/R32

### Fan Names
Fan names reported by IPMI sensors. Note these boards have 6-pin fan headers. This means the fan headers are designed to support dual-axle fans. These type of fans are paired, meaning there are two physical fans connected together and installed in an opposing fashion. These fans report two independent fan readings (e.g., FAN_FANx_1 and FAN_FANx_2), however when setting their fan duty, only one fan header is addressed with write commands (e.g. FAN_FANx). This is because the paired fans must be set to the same speed.

#### Fan Names Reported by Sensor Read
- CPU1_FAN1
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- FRNT_FAN4
- REAR_FAN1
- REAR_FAN2
- CPU1_FAN1_2
- FRNT_FAN1_2
- FRNT_FAN2_2
- FRNT_FAN3_2
- FRNT_FAN4_2
- REAR_FAN1_2
- REAR_FAN2_2

#### Fan Names Eligible for Fan Duty Write Commands
- CPU1_FAN1
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- FRNT_FAN4
- REAR_FAN1
- REAR_FAN2

> [!IMPORTANT]
> Be aware these motherboards reports more 'read' fan sensors than it is possible to 'write' to or set.

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:
```
ipmitool raw 0x3a 0xd6 {CPU1_FAN1} {reserved} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v7 (2019)
This schema is a bit of an oddball. These AST2500 boards use the older AST2300/AST2400 fan set command structure.

Single CPU. 6x 4-pin fans. Supports auto speed for all fan headers.

### Unique Characteristics
1. FAN1 = CPU fan.
2. 16-byte payload.
3. Minimum power is 4% (0x04).
4. Setting fan speed to 0x00 places fan into automatic fan mode.
5. "Auto" mode starts fans at 30% power.
6. BIOS versions after 2.60 do not allow IPMI fan control.

> [!CAUTION]
> This schema has some unusual qualities. Pay special attention to the unique characteristics noted above.
>
> In particular, note your board's BIOS version.

### Included Boards
- X470D4U

### Fan Names
Fan names reported by IPMI sensors.
- FAN1 (is also always the CPU cooling fan)
- FAN2
- FAN3
- FAN4
- FAN5
- FAN6

### Setting Fans to Auto Mode
To enable automatic mode for a given fan header, set its fan duty to zero (0x00).

### IPMI Command Order
IPMI command order to set fan speeds.

```
ipmitool raw 0x3a 0x01 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {reserved byte} {reserved byte}
```

IPMI command to read current fan speeds.

```
ipmitool raw 0x3a 0x02
```

## AST2500-v8 (2019)
Single CPU. 6x 6-pin fan headers. Supports auto speed for all fan headers. FAN1 = CPU fan. 16-byte payload. Minimum power is 4%.

These boards support a pair of 4-pin fans per 6-pin fan header. Normally, these will be opposing dual-axle fans. These type of fans are paired. Many boards with 6-pin fan headers report each fan's speed independently (e.g., as FAN_FANx_1 and FAN_FANx_2), but expect a single write command targetted at both fans in the pair, and apply the write command to each fan in the pair simultaneously. However, this board functions slightly differently. When reporting current fan speed, an average speed of the fan pair is reported. Write commands function as expected with this architecture, setting each fan in a pair to the same speed.

### Included Boards
- WC621D8A-2T

### Fan Names
Fan names reported by IPMI sensors.
- FAN1
- FAN2
- FAN3
- FAN4
- FAN5
- FAN6

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {10x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v9 (2020)
Single CPU. 6x 4-pin fan headers. Supports auto speed for all fan headers. FAN1 = CPU fan. 16-byte payload. Minimum power is 4%. 

> [!WARNING]
> Experimental. Fan control via IPMI on this board is not confirmed.

### Included Boards
- X470D4U2-2T

### Fan Names
Fan names reported by IPMI sensors.
- FAN1
- FAN2
- FAN3
- FAN4
- FAN5
- FAN6

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {10x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v10 (2021)
Dual CPU. 4x 6-pin fan headers. Supports auto speed for all fan headers. FAN1 = CPU fan. 16-byte payload. Minimum power is 4%.

These boards support a pair of 4-pin fans per 6-pin fan header. Normally, these will be opposing dual-axle fans. These type of fans are paired. Many boards with 6-pin fan headers report each fan's speed independently (e.g., as FAN_FANx_1 and FAN_FANx_2), but expect a single write command targetted at both fans in the pair, and apply the write command to each fan in the pair simultaneously. However, this board functions slightly differently. When reporting current fan speed, an average speed of the fan pair is reported. Write commands function as expected with this architecture, setting each fan in a pair to the same speed.

### Included Boards
- ROME2D16HM3

### Fan Names
Fan names reported by IPMI sensors.
- FAN1
- FAN2
- FAN3
- FAN4

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {12x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v11 (2022)
Single CPU. 3x 4-pin fan headers. Supports auto speed for all fan headers. Minimum power is 4%.

### Included Boards
- X570D4I-2T
- X570D4I-NL

### Fan Names
- FAN1 (CPU cooling fan)
- FAN2
- FAN3

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {13x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

### Special Fan Operations
Various other uncommon commands are available.

#### Reset All Fans
Reset all fans to default settings (equivalent to setting all fans to automatic mode):
```
ipmitool raw 0x3a 0xdc
```

#### Use Custom Curve
Set fans to use Custom Curve fan mode.

There is an option to create a custom fan curve in the BIOS. Setting any fan header to command mode 0x02 will cause that fan header to use the BIOS custom curve. For example, to set all fans to use the custom curve mode, you would enter the following IPMI command:
```
ipmitool raw 0x3a 0xd8 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02
```

#### Get Current Fan Modes
Returns the current fan mode for each fan, where:
- 0=auto
- 1=manual
- 2=custom curve

```
ipmitool raw 0x3a 0xd9
```

#### Get Current Fan Duties
Returns the current fan duty of each fan.

```
ipmitool raw 0x3a 0xd7
```

## AST2500-v12 (2022)
Single CPU. 7x 6-pin fan headers. Supports auto speed for all fan headers. FAN1 = CPU fan. 16-byte payload. Minimum power is 4%.

### Included Boards
- ROMED8-2T
- ROMED8-NL
- ROMED8-2T/BCM

### Fan Names
Fan names reported by IPMI sensors. These boards support a pair of 4-pin fans per 6-pin fan header. Normally, these will be opposing dual-axle fans. These type of fans are paired. Many boards with 6-pin fan headers report each fan's speed independently (e.g., as FAN_FANx_1 and FAN_FANx_2), but expect a single write command targetted at both fans in the pair, and apply the write command to each fan in the pair simultaneously. However, this board functions slightly differently. When reporting current fan speed, an average speed of the fan pair is reported. Write commands function as expected with this architecture, setting each fan in a pair to the same speed.
- FAN1
- FAN2
- FAN3
- FAN4
- FAN5
- FAN6
- FAN7

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {9x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

### Special Fan Operations
Various other uncommon commands are available.

#### Reset All Fans
Reset all fans to default settings (equivalent to setting all fans to automatic mode):
```
ipmitool raw 0x3a 0xdc
```

#### Use Custom Curve
Set fans to use Custom Curve fan mode.

There is an option to create a custom fan curve in the BIOS. Setting any fan header to command mode 0x02 will cause that fan header to use the BIOS custom curve. For example, to set all fans to use the custom curve mode, you would enter the following IPMI command:
```
ipmitool raw 0x3a 0xd8 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02 0x02
```

#### Get Current Fan Modes
Returns the current fan mode for each fan, where:
- 0=auto
- 1=manual
- 2=custom curve

```
ipmitool raw 0x3a 0xd9
```

#### Get Current Fan Duties
Returns the current fan duty of each fan.

```
ipmitool raw 0x3a 0xd7
```

## AST2500-v13 (2022)
Single CPU. 3x 4-pin + 3x 6-pin fans. Supports auto speed for all fan headers. 16-byte payload. Minimum power is either 4% or 20% depending on BIOS implementation (e.g. X570 series is 20%). No specific CPU fan, though it is normally presumed to be FAN1.

### Included Boards
- X570D4U
- X570D4U-2L2T
- X570D4U-2L2T/BCM

### Fan Names
Fan names reported by IPMI sensors. Note these boards have 6-pin fan headers, which are designed to support dual-axle fans. These type of fans are paired, meaning there are two physical fans connected together and installed in an opposing fashion. These fans report two independent fan readings (e.g., FANx_1 and FANx_2), however when setting their fan duty, only one fan header is addressed with write commands (e.g. FAN_FANx). This is because the paired fans must be set to the same speed.
- FAN1
- FAN2
- FAN3
- FAN4_1
- FAN4_2
- FAN5_1
- FAN5_2
- FAN6_1
- FAN6_2

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {10x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

## AST2500-v14 (2023)
Dual CPU. 8x 6-pin fan headers. Supports auto speed for all fan headers. FAN1 = CPU fan. 16-byte payload. Minimum power is 4%.

### Included Boards
- ROME2D32GM-2T
- ROME2D32GM-NL
- ROME2D16-2T
- ROME2D16-2L+
- ROME2D16-NL
- ROME2D16-2T/BCM

### Fan Names
Fan names reported by IPMI sensors. These boards support a pair of 4-pin fans per 6-pin fan header. Normally, these will be opposing dual-axle fans. These type of fans are paired. Many boards with 6-pin fan headers report each fan's speed independently (e.g., as FAN_FANx_1 and FAN_FANx_2), but expect a single write command targetted at both fans in the pair, and apply the write command to each fan in the pair simultaneously. However, this board functions slightly differently. When reporting current fan speed, an average speed of the fan pair is reported. Write commands function as expected with this architecture, setting each fan in a pair to the same speed.
- FAN1
- FAN2
- FAN3
- FAN4
- FAN5
- FAN6
- FAN7
- FAN8

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {FAN8} {8x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

#### Reset All Fans
Reset all fans to default settings (equivalent to setting all fans to automatic mode):
```
ipmitool raw 0x3a 0xdc
```

# AST2600 IPMI Schemas
ASRock Rack motherboards with ASPEED AST2600 BMC chip support up to 16 independent fan headers. These boards generally follow AST2500 style commands.

## AST2600-v1 (2023)
Single CPU. 7x 4-pin fans. Minimum manual speed 20%.

### Included Boards
- Z690D4U-2L2T
- W680D4U-2L2T
- W680D4U-1L
- Z690D4U
- W680D4U

### Fan Names
Fan names reported by IPMI sensors.
- FAN1
- FAN2
- FAN3
- FAN4
- FAN5
- FAN6
- FAN7

### IPMI Command Order
This schema requires the BMC to be explicitly set to allow manual fan speed control. If this pre-requisite command is not executed first, manual fan control will not work as expected.

```
ipmitool raw 0x3a 0xd8 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01
```

Once manual mode is established, to set fan speeds use the following syntax:

```
ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {9x reserved bytes}
```

### IPMI Set All Fans to Auto Mode
To abandon manual mode and set all fans to automatic mode, use the following command:

```
ipmitool raw 0x3a 0xd8 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```
