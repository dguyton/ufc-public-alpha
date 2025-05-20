# IPMI Raw Fan Control Commands
A collection of miscellaneous IPMI ```raw``` command syntax reference for manual control of fan headers, by BMC model and motherboard manufacturer. The information below is for educational purposes only and is not exhaustive.

## IPMI Raw Command Syntax

### 8-bits in a Byte
While some values are stored internally within the BMC as 16-bit (or even 32-bit with some modern BMC chips), IPMI command bytes are always only 8-bits. There seem to be two reasons why:
1. Legacy behavior. Early BMC chips only had 8-bit registers.
2. Need (or lack of). There's a limited number of possible commands, and hence no point in greater capacity for input values.

The first byte is an amalagamation of the LUN (Logical Unit Number) and NetFn (Net Function), like so:

```{ [NetFn (6 bits)] + [LUN (2 bits)] }```

The LUN comprises the first 2 least significant bits in the first (8-bit) byte of the RAW command, giving it an equivalent decimal value of 0 to 3. The more significant 6 bits (bits 2-7) represent the NetFn, giving it an effective value range of 0-63.

Combined, the LUN and NetFn manifest the first byte in the payload. The full RAW command therefore looks like this:

```raw {net_fn|LUN} {command} [data] ```

Example:
``` ipmitool raw 0x30 0x00 0x01 0x01 0xff```

Breaking it down:
- LUN = 0x00 (0)
  - Send this raw payload to main BMC processor
- NetFn = 0x30 (48)
  - Addressing function 0x30 (48)
- Command = 0x00 (0)
  - Command instruction reference 0x00 (0)
- Data = 0x01 0x01 0xff
  - send the following data payload to the function's command: 0x01 0x01 0xff

#### LUN Explained
The purpose of the LUN is to indicate to whether the command should be directed to the main BMC process tree, or a sub-process. The concept is similar to network routing, where the LUN acts like a destination address. The vast majority of RAW commands (including fan related commands) are addresed to the main BMC process, which is LUN 0. Therefore, most of the time, the LUN = 0 and has no effect on the 1st byte of the RAW commmand. In other words, most of the time the 1st byte is synonymous with the NetFn (i.e., NetFn + 0 = NetFn).

#### NetFn Explained
The 1st byte of the IPMI 'raw' command is often erroneously referred to in documentation as the "NetFn" byte. However, this is technically incorrect. While most of the time the first byte in the RAW command will equal the NetFn, as previously mentioned (see LUN section immediately above) the LUN is typically equal to 0 (zero).

The NetFn (Net Function) is the address within the BMC of the device the RAW command should be sent to. Or put another way, it is the destination ID to which the RAW command should be sent to. Internally, the BMC is divided up into functional areas. When a command is received, the BMC needs to figure out which process where to route it to. Figuring that out requires a combination of the LUN and NetFn.

#### The Command Byte
The command byte immediately follows the LUN and NetFn values, making it the 2nd byte in the RAW instruction payload.

#### Channels
Another common reference in many literary works regarding the BMC is the concept of a "channel." This term may be a bit over-used in many contexts, as it is not a standard BMC data byte.

In BMC parlance, a "channel" refers to singling out a specific communication path - usually a specific device - as part of an IPMI command. The "channel" byte is not something that is required or used by default. The function addressed by the NetFn byte will determine whether or not a *channel* byte is expected in the payload. One may think of it in the context of fine-tuning the process address to which the command data payload is being directed. For instance, when sending a command request to the fan controller, the function (the fan controller communication process in the BMC) may expect the first data byte to indicate the fan header ID to which the fan request is targetted. Therefore, that particular function - in this example - expects the first data byte to act as a "channel" meaning a fine-tuning of the ultimate target of the raw command.

Whether or not the first data byte is a "channel" per se, is wholly up to the function to which the command has been sent.

## BMC Manufacturers
There are just a few common BMC manufacturers, as it is a very specialized product. Some companies - such as Dell, HPE, IBM, and Intel - have manufactured their own BMC chips at one time or another. The former are general purpose, and allow some custom programming by server motherboard vendors. Intel is unique in the sense it has historically been both a BMC 3rd-party supplier to other server manufacturers, and utilized it's home-grown BMC chips on its own proprietary server boards.

### ASPEED
ASPEED is the gold standard for 3rd-party BMC chips and the most popular brand.

### Nuvoton / Winbond
Nuvoton is an independent, publicly traded (Taiwan stock exchange) company that produces 3rd-party BMC chips. Nuvoton was spun-off from Winbond in 2008. The names may be considered synonymous with one another with regards to understanding which BMC chips are related.

### Graphcore
[Graphcore BMC](/documentation/universal-fan-controller/non-supported-hardware/graphcore-bmc.md) is a propritary, highly specialized BMC designed for Graphcore's servers only and (to the author's knowledge) is not distributed to outside hardware vendors. The Graphcore BMC supports both IPMI (2.0) and [Redfish](redfish.md).

## Server Manufacturers
These server manufacturers have produced their own BMC chips at one time or another.

### IBM and Lenovo
Lenovo acquired IBM's PC business in 2004, and IBM's server business in 2014. As a result, there is some co-mingling of parts in Lenovo servers manufactured after the acquisition. Like Intel, at one time IBM poured considerable resources into creating its own BMC chips, before eventually abandoning this effort and adopting ASPEED's AST line for use in their servers. The point being, IBM and Lenovo servers may contain a proprietary IBM (of which there were several versions over the years) or an ASPEED ASTxxxx line chip.

#### Unique Features of IBM/Lenovo Servers
Regardless of which BMC is in use, IBM servers are known to frequently handle fan management a bit differently than most server brands. Below is a synopsis of some characteristics 
-	IBM uses 6-pin fans, which are reported as 2 fans when read
-	IBM refers to each set of 2 reported fans a "zone"
-	Fan nomenclature is confusing as fans are actually controlled directly
  -	Fan reads appear as distinct values (one per physical fan)
  -	However, when addressing write commands to the fans, they are controlled in pairs by fan ID (i.e., 1 write command affects related pair of 2 fans)

### Intel
Intel's BMCs generally allow five forms of fan control:
1. Automatically controlled via thermal algorithms in the BMC
2. Deferring automatical control to the BIOS, which sends commands to the BMC based on its thermal algorithms
3. Pre-defined fan cooling "modes"
4. Setting all fans to a specified fan duty level (PWM)
5. Setting a single fan to a specified fan duty level (PWM)

#### Get Fan Duty Cycle (All Fans)
Intel's `get` command for current fan duty cycles is a bit odd. It returns data for all fans, indicating each individual fan's current PWM setting (0-100), but also makes a point to inform you of the highest PWM among all the fans.

``` ipmitool raw 0x30 0x00 0x01```

Returns current PWM values as text string. Response bytes:
1.	{completion code; 0x00 = normal}
2.	{number of supported fans}
3.	{maximum PWM among all fans}
4.	{FAN 0 PWM}
5.	{FAN 1 PWM}
6.	{FAN x PWM bytes} (repeated as necessary)

### Quanta
- get fan reading
```ipmitool raw 0x04 0x2d 0x01```
- set fan 0 to duty speed
```ipmitool raw 0x30 0x39 0x01 0x00 0x00 0x{$duty_speed}```
- set fan 1 to duty speed
```ipmitool raw 0x30 0x39 0x01 0x00 0x01 0x{$duty_speed}```
- set fan {0-5} to {duty speed}
```ipmitool raw 0x30 0x39 0x01 0x00 0x0{fan_id} 0x{duty_speed}```
- sensor thresh works the same as supermicro
- settings are not retained after reboot

