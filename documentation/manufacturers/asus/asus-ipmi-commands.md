# Asus Server Fan Control via IPMI
There are three predominant IPMI control styles for Asus server motherboards. Each board that supports manual fan control via IPMI supports one of these methods.
- Version 1: Universal and individual fan controls
- Version 2: Zoned control
- Version 3: Similar to v1, with differing IPMI commands

## Asus IPMI Fan Control Style v1
- Works with boards such as the Asus KMPP-D32
- Automatic fan mode or manual mode
- Universal manual fan control (all fans at once)
- Individual manual fan control (set each fan independently)

### Disable auto fan mode / Enable manual fan mode
IPMI command format (demonstrated with **ipmitool**):

```ipmitool raw {LUN/NetFn} {fan controller} {auto mode command} {turn auto mode off}```

Actual command:
```
ipmitool raw 0x30 0x30 0x01 0x00
```

### Enable auto fan mode / revert to auto control
IPMI command format (demonstrated with **ipmitool**):
```ipmitool raw {LUN/NetFn} {fan controller} {auto mode command} {turn auto mode on}```

Actual command:
```
ipmitool raw 0x30 0x30 0x01 0x01
```

### Set fan speeds (universal mode)
```{NetFn} {Fan control} {manual fan control} {fan id} {fan duty}```

Fan ID `0xff` = "all fans"

Set all fans to 50% fan duty:
```
ipmitool raw 0x30 0x30 0x02 0xff 0x32
```

### Set fan speeds (individual mode)
```{NetFn} {Fan control} {manual fan control} {fan id} {fan duty}```

Set all fan ID 2 to 50% fan duty:
```
ipmitool raw 0x30 0x30 0x02 0xff 0x32
```

---------------------------------------------

## Asus IPMI Fan Control Style v2
- Works with boards such as the Asus Z11PA-D8
- Automatic fan mode or manual mode
- Zoned manual fan control (fans are controlled collectively by group)

### Auto fan control
```
ipmitool raw 0x30 0x70 0x66 0x00
```

### Manual fan control of zone
```ipmitool raw 0x30 0x70 0x66 0x0<Zone ID> <Duty Cycle>```

-----------------------------------------

## Asus IPMI Fan Control Style v3
- Works with boards such as the Asus C422 PRO/SE (workstation board)
- Similar behavior to ASRock Rack boards.
  - 8 fan speed bytes must be specified even when there are no corresponding fan headers for those positions.
  - Payload bytes 4-11 are the fan speed settings, in sequential order by Fan ID.
  - IPMI fan related commands must address the entire group of fans at the same time.
- Fan duty speed must be set for all fans simultaneously, even when not changing the current fan duty for a given fan.
- A fan speed of zero (0) will set the fan to automatic mode (controlled by BIOS or BMC using thermal profiles).

### Automatic Fan Control
Fans may be controlled automatically (via BIOS or BMC thermal profiles) or manually. The default is automatic. Fans must have auto mode _disabled_ before they can be controlled manually. Otherwise, IPMI requests to control fans will be ignored.

For auto/manual mode, the command byte 0x00 = auto mode and 0x01 = manual mode.

#### Enable automatic fan control for all fans
```
ipmitool raw 0x30 0x70 0x66 0x00
```

#### Disable automatic fan control / Enable manual fan control, for all fans
```
ipmitool raw 0x30 0x70 0x66 0x01
```

### Manual Fan Control
Before fans may controlled manually, the automatic mode must be disabled. Once this is done, each fan ID must have its speed set together. In other words, all fan speeds need to be sent in a single command, at the same time. This is true even when the intent is to not change a given fan's current speed. It is also possible to they set a specific fan to automatic mode in the same manner, by assinging its fan speed as zero (0x00).

```ipmitool raw 0x30 { command = 0x05 } { channel/action } {fan0} {fan1} {fan2} {fan3} {fan4} {fan5} {fan6} {fan7}```

- 1st byte (0x30) is Cooling function in BMC.
- 2nd byte (0x05) is command to control PWM fan speed.
- When manual mode is specified, 8 bytes must follow, specifying fan speeds for each of the 8 fans on the board.

#### Set Fan ID 1 to automatic mode (0% fan duty) and all other fans to 30% fan duty:
```
ipmitool raw 0x30 0x05 0x01 0x16 0x00 0x16 0x16 0x16 0x16 0x16 0x16
```

#### Set all fans to 50% fan duty (32h = 50):
```
ipmitool raw 0x30 0x05 0x01 0x32 0x32 0x32 0x32 0x32 0x00 0x00 0x00
```

#### All fans may be also be returned to automatic mode this way (alternative to method described above):
```
ipmitool raw 0x30 0x05 0x00
```
