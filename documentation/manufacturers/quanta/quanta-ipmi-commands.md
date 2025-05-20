# Quanta Servers and Fan Control
Quanta is a small server manufacturer with a limited number of products.

Quanta server boards with Baseboard Management Controller (BMC) chipsets typically use one of the following BMC chipsets:
- Aspeed AST2400
- Aspeed AST2500
- Aspeed AST2600

## Quanta Server IPMI Commands
Quanta servers have some odd quirks related to manual fan control via IPMI commands:

IPMI commands differ based on whether the server has a 1U or 2U height rackmount server chassis.

### Quanta 1U Servers
Quanta's 1U servers typically contain six chassis fans and the CPU is passively cooled.

The following strange rules apply to 1U servers only:
1. Fan ID parameters in IPMI commands are offset by 1. For example, Fan ID 0 is expressed as position 1.
2. Fan duty cycle (PWM %) is expressed as the target value - 1.
3. Fan duty cycle range is 0x00 - 0x63 (0 - 99), which equates to actual fan duty of 1 - 100%.

The following IPMI command format affects manual fan duty speed control over a given fan header:

`ipmitool raw 0x30 0x39 0x01 0x10 {fan id + 1} {fan duty - 1}`

#### Setting Fan Duty Cycle
For example, to set the duty cycle (PWM %) for fan ID 0 to 100%:

```
ipmitool raw 0x30 0x39 0x01 0x10 0x01 0x63
```

Breaking it down, this means:
1. Address fan controller: 0x30 0x39
2. Set fan speed: 0x01 0x10
3. Fan ID 0: 0x01
4. Fan duty 100%: 0x63

> [!NOTE]
> Remember to subtract 1 from the desired fan duty speed.

As another example, to set the duty cycle (PWM %) for fan ID 1 to 50%:

```
ipmitool raw 0x30 0x39 0x01 0x10 0x02 0x31
```

### Quanta 2U Servers
Quanta's 2U servers typically contain four chassis fans and the CPU is passively cooled. Quanta's 2U servers follow a normal/typical protocol in terms of fan ID and fan duty. Fan IDs begin with 0. The duty cycle range is 0x00 - 0x64 (0 - 100). Astute observers will also notice there is a slight differentiation in the 4th byte of the IPMI raw command. On the 1U server variants, this byte is 0x10. On the 2U variants, it is 0x00.

The following IPMI command format affects manual fan duty speed control over a given fan header:

`ipmitool raw 0x30 0x39 0x01 0x00 {fan id} {fan duty}`

The following IPMI command format affects manual fan duty speed control over a given fan header:

`ipmitool raw 0x30 0x39 0x01 0x00 {fan id} {fan duty}`

#### Setting Fan Duty Cycle
For example, to set the duty cycle (PWM %) for fan ID 0 to 100%:

```
ipmitool raw 0x30 0x39 0x01 0x00 0x00 0x64
```

## Fan Speed Thresholds
Quanta servers support the standard protocol for the IPMI 'sensor thresh' command to set fan speed sensor thresholds. They utilize the same industry-standard methodology employed by Supermicro, ASRock, and Tyan.

### Valid Thresholds
The valid thresholds are:
- UNR: Upper Non-Recoverable
- UCR: Upper Critical
- UNC: Upper Non-Critical
- LNC: Lower Non-Critical
- LCR: Lower Critical
- LNR: Lower Non-Recoverable

### IPMI Set Sensor Threshold Order
The command and format to set new fan speed sensor thresholds follows the widest industry standard. The ordering is as follows:

`ipmitool sensor thresh <id> <threshold> <setting>`

This allows you to set a particular sensor threshold value, specified by name.

#### Set Lower Thresholds
`ipmitool sensor thresh <id> lower <lnr> <lcr> <lnc>`

#### Set Upper Thresholds
`ipmitool sensor thresh <id> upper <unc> <ucr> <unr>`


-------------------------------

get fan reading
ipmitool raw 0x04 0x2d 0x01

set fan 0 to duty speed
ipmitool raw 0x30 0x39 0x01 0x00 0x00 0x{$duty_speed}

set fan 1 to duty speed
ipmitool raw 0x30 0x39 0x01 0x00 0x01 0x{$duty_speed}

set fan {0-5} to {duty speed}
ipmitool raw 0x30 0x39 0x01 0x00 0x0{fan_id} 0x{duty_speed}

sensor thresh works the same as supermicro

settings are not retained after reboot
