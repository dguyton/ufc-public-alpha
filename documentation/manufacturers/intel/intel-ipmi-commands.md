# IPMI Commands for Selected Intel Server Motherboards

## Intel M20NTP Server Family

### Get Fan Current Speeds
```
ipmitool raw 0x30 0x8D
```

### Set Manual Speed for All Fans
`ipmitool raw 0x30 0x8c {PWM value}`

Example: Set all fans to 50% fan duty:
```
ipmitool raw 0x30 0x8c 0x32
```

### Set All Fans to Automatic Mode (Thermal Manager)
Set all fans to a particular mode available to the Thermal Manager. This is a form of automatic fan speed control that impacts all fan headers. However, rather than a true automatic mode, the user is able to specify the mode type (of choices known to the Thermal Manager).

Note the 4th byte is the selector.

#### Performance Mode
More intensive than Acoustic mode, but less than full power. Should fluctuate between roughly 50-70% PWM.

```
ipmitool raw 0x30 0x89 0xff 0x44 0x10 0x01 0x01 0x01 0x03
```

#### Acoustic Mode
Intel's "quiet" mode. Equivalent to Supermicro's "Optimal" setting. Should hover around 30% PWM with possible bursts to near 50% if temperature sensors get too high.

```
ipmitool raw 0x30 0x89 0xff 0x40 0x10 0x01 0x01 0x01 0x03
```

## Intel pGFx BMC
The pGFx is a BMC chip manufactured by Intel. It supports universal (all fans at once) and zoned fan control methods. This chip is found on some Intel boards and some Tyan Computer boards as well.

With regards to zones, there typically two fan zones: Zone 0 and Zone 1. Where 'Zone 0' contains CPU fans and/or fans dedicated to CPU cooling, and 'Zone 1' contains all other fans, such as those assigned to cooling peripherals.

### Set Manual Speed for All Fans
`ipmitool raw 0x30 0x30 0x02 {PWM value}`

Example: Set all fans to 50% fan duty:
```
ipmitool raw 0x30 0x30 0x02 0x32
```

### Set Fans in Zone x to Speed

`raw 0x30 0x70 0x66 0x01 {zone id} {fan duty}`

For example, to set Zone 1 fans to 75% PWM fan duty:
```
ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x4b
```

## Intel S500BC Motherboard
The CPU fans and top case fan have a minimum speed of 40%. Attempting to set these fan speeds < 40 will result in the BMC entering emergency mode (all fans are set to 100% until next reboot). The other fans may be set to anything in the full range of 0-100%.
