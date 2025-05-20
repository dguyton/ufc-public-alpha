# Gigabyte Servers and Fan Control
Gigabyte server boards with Baseboard Management Controller (BMC) chipsets typically use one of the following BMC chipsets:
- Aspeed AST2150
- Aspeed AST2300
- Aspeed AST2400
- Aspeed AST2500

Of those BMC chipsets, generally speaking, only the AST2500 variety allow manual fan control via IPMI, and not all of these boards support it.

Some Gigabyte server boards support a limited form of IPMI fan control, where fan speeds cannot be tweaked to specific speeds at will. Instead, fan speeds may be pre-determined in conjunction with temperature triggers. For example, when a temperature sensor reaches TEMP_1, a given fan is set to FAN_SPEED_1. Under this schema, each fan header is mapped to [three independent temperature triggers](https://www.reddit.com/r/homelab/comments/mxmmkx/gigabyte_wrx80su8ipmi_ipmi_fancontrol). Each trigger is assigned a different tempertaure and different fan duty (PWM %).

## GSM Platform (GIGABYTE Server Management)
In 2018, GIGABYTE’s proprietary multiple server remote management software platform, the GIGABYTE Server Management (GSM).

GSM is very similar to Dell's iDRAC (Integrated Dell Remote Access), Hewlett-Packard Enterprise's iLO (Integrated Lights-Out), and IBM's IMM (Integrated Management Module) proprietary firmware implementations. Each functions in a nearly identical fashion. They control communications to and from the BMC and other hardware components. GSM is compatible with both IPMI and the [Redfish](/documentation/bmc-and-server-architecture/redfish.md) (RESTful API) protocols.

GSM acts as a gatekeeper and my limit the ability to control various aspects of the server's hardware. It filters user-initiated commands to the underlying chips and firmware, such as IPMI commands, before they are allowed to pass to the BMC.

### GSM Controllers
Gigabyte has created several different implementations of web-based and command line driven end-user access controls to the GSM firmware. These GSM user-facing interfaces (mentioned below) are capable of monitoring fan speeds, but cannot be used to manipulate fan speed settings.
•	GSM Agent
•	GSM CLI Utility
•	GSM Server Manager Utility
•	GSM Mobile
•	GSM Plugin

### GSM and the BMC
The *GSM Server*, *GSM Agent*, and *GSM CLI Utility* all have the ability to communicate with the BMC chip directly. *GSM Mobile* and *GSM Plugin* on the other hand, must go through the GSM Server application n order to talk to the BMC chip.

Gigabyte's nomenclature can be confusing. The firmware/hardware GSM itself is the **GIGABYTE Server Management Server** (GSM Server). Yet there is a Windows utility and an embedded utility available via an HTTP connection, both of which are called the *GSM Server Manager*.

#### GSM Agent
Gigabyte's user-facing software that allows an end user to communicate with and utilize the GSM firmware via the operating system installed on the server. GSM Agent is a **monitoring tool only** and does not allow fan control.

#### GSM Mobile
Remote server management application available for Android and iOS based devices.

#### GSM Plugin
VMware Vcenter plugin.

### GSM Related IPMI Commands
This is how IPMI commands need to be structured in order to control fans on a server with GSM.

Fan ID must be known. This is normally equivalent to the order in which fan header information is displayed in IPMI sensor readouts or how the **sensors** command (lm-sensors program) displays fan information.

#### Set Fan Control

```ipmitool raw 0x3c 0x16 0x02 {fan ID} {fan duty 1} {fan duty 2} {fan duty 3} {temp 1} {temp 2} {temp 3}```

For example, to set temperature triggers and fan duties for Fan ID 1:
```
ipmitool raw 0x3c 0x16 0x02 0x01 0x14 0x32 0x64 0x14 0x50 0x5f
```

#### Get Fan Control
To get the current fan duty settings and temperature triggers for a given fan, query by Fan ID like so:

`ipmitool 0x3c 0x16 0x03 {fan ID}`

This command will return the current settings for the specified fan ID:

`ipmitool raw 0x3c 0x16 0x02 {fan ID}`

Such as this example for Fan ID 1:

```
ipmitool 0x3c 0x16 0x03 0x01
```

Which returns a text string:

`{fan ID} {fan duty 1} {fan duty 2} {fan duty 3} {temp 1} {temp 2} {temp 3}`

Such as this example for Fan ID 1:

`01 0a 32 64 14 50 5f`

Which means the current state of Fan ID: 0x01 (1) is:
- Temp Trigger 1: 0x14 (30 degrees C)
- Fan Duty 1: 0x0a (10%)
- Temp Trigger 2: 0x50 (80 degrees C)
- Fan Duty 2: 0x32 (50%)
- Temp Trigger 3: 0x5f (95 degrees C)
- Fan Duty 3: 0x64 (100%)

## ASPEED AST2500 Based Boards (Without GSM)
Most non-GSM controlled Gigabyte server boards with the ASPEED AST2500 BMC chip will support the standard IPMI fan control command structures. These Gigabyte server boards usually support universal (all at once) and individual fan control, similar to most Dell server motherboards.

#### Target Specific Fan
`ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01 {fan duty} {fan id}`

#### Target All Fans
`ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01 {fan duty} 0xff`

The "0xff" fan header ID = all fans.

#### Examples
Set all fans to 30% fan duty.
```
ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01 0x1e 0xff
```

Set all fans to 50% fan duty.
```
ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01 0x32 0xff
```

Set Fan ID 2 to 100% fan duty.
```
ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01 0x64 0x02
```

### Automatic Fan Mode
Another option is to enable automatic fan control, meaning the fan speeds will be managed by the BMC itself based on its internal thermal algorithms. The BMC monitors various hardware temperature sensors and adjusts fan speeds accordingly. This method generally has the BMC controlling CPU fans separately from system fans, but it does not otherwise distinguish fan commands on a per-fan basis.

#### Enable Automatic Fan Control Mode
```
ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x00
```

#### Disable Automatic Fan Control Mode
When disabled, the BMC will not attempt to control the fans unless a fan speed threshold is violated (i.e., emergency mode activated).

```
ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01
```
