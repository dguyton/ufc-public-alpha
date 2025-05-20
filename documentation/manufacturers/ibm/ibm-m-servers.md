# IBM Server Model Nomenclature

## IBM System x Series
IBM launched a line of servers in the late 2000's the company dubbed the X Series. servers circa late 2000s to mid 2010's typically have a 2-part model designation. The first portion denotes the actual model (e.g., IBM 3650). The second portion - when present - is typically in the format "Mx" where M = "model" and is followed by an integer denoting the "model" number. However, substituting the word "generation" for "model" is more apt. The integer indicates the iteration or (usually) generation of the server model. For example, the IBM 3650 M3 is a 3rd generation server in the IBM 3650 server series.

- Mx where x = generation
- Exhibits consistent behavior for the most part, with a couple of edge cases
- Fan headers are referred to as "zones" however in IBM parlance, a "zone" is a pair of counter-rotating fans controlled as a direct/individual fan
- Each fan is a dual-fan (6-pin) which seems to be why IBM refers to them as "zones" (each zone = a fan pair)
- Fans report their status and speed individually
- When sending a new fan duty command to a fan, the command must be sent to the "zone" or fan pair. Fans cannot be addressed individually. Rather, the pair of fans in the same zone are sent the same command at the same time. The BMC must receive fan commands addressed to the fan _zone_ (fan ID {x} without).
    - For example, fan zone 1 may appear in fan metadata as reporting FAN1_0 and FAN1_1 status, however when sending a command to either fan, one would need to address their shared zone (zone 1), and send the fan duty command to fan zone 1 (e.g. you would send a write or set command to FAN1). The fan controller will attend to setting the actual fan speed (RPM) appropriately for each fan, based on the requested fan duty (PWM %).

### IMM vs BMC
IBM has its own, proprietary Baseboard Management Controller (BMC) platform, called "Integrated Management Module" or IMM. From an architectureal standpong, its design and intent are similar to [Dell's iDRAC](/documentation/manufacturers/dell/dell-idrac.md).

### Manual Fan Control
Some, but not all of the IBM 3xxx series servers are capable of manual fan control. Much often depends on the server generation. Like many manufacturers, IBM has a tendency to tweak BMC settings and internal controls from one generation to another, for various reasons.

Fan related metadata in particular varies widely. For example, the 3520 series servers have four (4) 4-pin fans, which appear on sensor readings as "FAN{x}" where x = fan number (1 through 4). The 3650 series on the other hand, has 3 pairs of fans utilizing 6-pin architecture. The 3650's fans appear in sensor readings may appear in the format "FAN {x}A Tach,FAN 1B" or "FAN 1A,FAN 1B" where the integer aligns with a respective fan pair ("zone").

### Minimum Fan Speed
The System x 3xxx series has a minimum fan speed setting of 1% PWM (but see "Acoustic" mode description below). If the fan speed is set to zero (0), this is interpreted by the IMM as "set fan speed automatically."

### IPMI Raw Commands
The System x 3650 server series models (M1 - M5) all use the same raw IPMI command format to manually set fan speeds (by fan zone).

`raw 0x3a 0x07 {zone_id} {speed} {override}`

Where the "override" byte must be set = 0x01 in order to override (or force manual) fan speeds, while setting it = 0x00 will cause the given fan to be operated automatically. If automatic mode is engaged, the request for a given manual fan speed setting will be ignored.

### Automatic Fan Speed Mode
Either of two settings in an IPMI raw command pertaining to fan speed will cause the fan(s) in question to enable automatic fan speed mode.

1. Setting the fan override mode = 0x00 (off). When override mode is turned off, it means automatic mode is enabled and the BIOS will send fan speed adjustment commands to the BMC based on thermal sensors.
2. If the fan speed in an IPMI raw command is set to = 0 then regardless of the override mode setting, it will be disabled and automatic fan speed mode will be enabled.

### "Acoustic" Fan Speed Mode
If one sends an IPMI command to the server that simultaneously instructs it to:
1. Disable automatic fan speed control; and
2. Set fan speed of a fan zone to 0%

Then this will trigger what the IMM refers to as "Acoustic mode," another built-in fan speed setting. _Acoustic_ mode sets the fan zone to a fixed 40% PWM level.
