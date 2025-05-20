# HPE Servers and Manual Fan Control
Hewlett-Packard Enterprises (HPE) has a virtually identical IPMI command structure to Dell's PowerEdge servers.

1. Each fan can be managed individually.
2. All fans can be managed together with a single command.

## Consistency in IPMI Raw Commands
1. All numbers are in the 'raw' command are hexadecimal.
2. Fan duty speed range is 0-100. Convert 10-base integer to hex (i.e., 25% PWM = 0x19).
3. Fans may be managed either individually or all together.

## Manual Fan Speed Controls
Automatic fan control mode must be explicitly disabled before manual fan speed commands will work.

### Set Fan Duty for One Fan Header
Set the speed for a single fan only:

`raw 0x30 0x30 0x02 0x{fan_id} 0x{fan_speed}`

### Set Fan Duty for All Fan Headers
To set the speed for all fans simultaneously, substitute "0xff" for the fan ID.

`raw 0x30 0x30 0x02 0xff {speed in hex}`

## Automatic Fan Control Mode
To enable automatic fan control (also known as "Smart Fan Mode" for all fans, which will cause the BMC to manage all fans based on thermal profiles:

### Set All Fans to Auto
If desired at any point, the command is:

```
raw 0x30 0x30 0x01 0x01
```

### Disable Automatic Fan Speed Control
By default on boot-up, all fans are set to automatic fan speed control, meaning all fans are controlled by the BMC's built-in algorithms (thermal curves). To enable manual fan speed control, auto mode must first be disabled for all fans:

```
raw 0x30 0x30 0x01 0x00
```

> [!NOTE]
> Note the 3rd byte in the IPMI command denotes whether the target is all fans (0x01) or a single fan header (0x02).

### Set a Specific Fan to Auto
After all fans have had automatic fan speed control disabled, they may be controlled manually. However, there is also a special option to re-enable automatic fan control on an individual fan basis. To enable automatic fan speed control *for a particular fan ID only*, set its fan speed to zero (0).

```
raw 0x30 0x30 0x02 0x{fan_id} 0x00
```

