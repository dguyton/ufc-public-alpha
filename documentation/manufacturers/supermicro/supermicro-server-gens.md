# Supermicro Fan Control Compatibility by Server Line & Generation
Supermicro is one of the most well-known manufacturers of server hardware. Many of their server motherboards support manual fan speed controls. Whether or not any give board does depends on the motherboard generation and its BMC chipset.

## A1 Series Motherboards
The Supermicro A1 series are server-class Intel Atom CPU based motherboards with the ASPEED AST2400 BMC chip and 4-pin fan headers.

# Supermicro B Series Motherboards
## B2 | B3 | B11 | B12
Series B boards are entry-level server and workstation motherboards, many of which contain a BMC chip. This does not mean it's possible to control the fans for all of these boards that do have a BMC, but it is likely possible for some.

# Supermicro C Series Motherboards
## C7 | C9
Series C motherboards are intended for cloud-computing and data-center applications. Most if not all of these include a BMC chip and may allow manual fan control.

# Supermicro H Series Motherboards
## H11 | H12 | H13
Series H motherboards are high-performance server boards designed for enterprise and data-center use. Many support multi-CPU configurations.

# Supermicro M Series Motherboards
## M11 | M12
Series M boards feature compact form factors and are designed for micro-servers and edge computing. These boards may or may not contain a BMC, but many of them do.

# Supermicro X Series Motherboards
The sweet spot for Supermicro server boards are generations X9 through X12.

X-series board generations usually share certain characteristics. However, there are exceptions, which are typically early releases of the generation.

X-Series Typical BMC Chip
- X10: ASPEED AST2400
- X11: ASPEED AST2500
- X12: ASPEED AST2600
- X13: ASPEED AST2600

X-Series Typical Supported Sensor Thresholds
- X10 and X11: These boards typically support six sensor thresholds for fan speeds:
    - Lower Non-Recoverable
    - Lower Critical
    - Lower Non-Critical
    - Upper Non-Critical
    - Upper Critical
    - Upper Non-Recoverable
- X12 and X13
    - Some newer boards, particularly those with the AST2600 BMC, have a simplified threshold system, sometimes supporting only the Lower CRitical (LCR) threshold. This change reflects an evolution in hardware monitoring and control mechanisms, focusing on a more logical approach and eliminating unnecessary or redundant thresholds.

## X8 Boards
X8 boards have limited manual fan control support. For the majority of X8 boards, fan speed is not user-configurable, though indirect fan speed management is frequently possible. The BIOS is the only means of controlling fans on most X8 boards. When this is the case, the fans remain in automatic mode and will be adjusted by the BIOS based on temperature sensor readings.

Some X8 boards may work with X9 fan control parameters. And some will work with the i2C protocol, but not with IPMI.

> [!NOTE]
> On X8 boards, it is technically possible to control individual fan speeds using the chipset registry. On X9 and later boards, fans can only be controlled manually via zones (groups).

### Potential i2C Workaround with Nuvoton W83795G Boards
There is an advanced method of controlling fans on Supermicro X8 gen boards with this BMC. [This Python script on GitHub](https://gist.github.com/timemaster67/3d8b703d15e65063c61d194c0d357e1d) demonstrates a real-world application utilizing this method. Implementation of this solution is beyond the scope of this guide, as it requires custom programming with i2C (i2C-i801), and is not compatible with IPMI. Also, it purports to allow _individual_ fan control on these boards. It is mentioned here for the benefit of anyone still using these X8 boards who may inclined to figure out a complete solution utilizing this script.

Examples of related X8 board models with the Nuvoton W83795G:
- X8DTH-F
- X8DTi-F
- X8DTL-iF
- X8DTL-3f
- X8DTL-iF

### X8 Boards Following X9 Protocol
The following model X8 boards may work with gen X9 fan control protocols:
- X8DTH-6
- X8DTH-6F
- X8DTH-i
- X8DTH-iF

## X9 Board Characteristics
- Fan speed adjustments are possible
- 3 fan modes
	- Full
	- Standard
	- Heavy I/O
- Fan speed range is 0-FF (0-255) in hex, representing 0-100%
- Fan speeds manipulated by pre-defined and fixed groups of fans called fan zones
- Typically Nuvoton WPCM450 or WPCM450R BMC chipset
- IPMI command to set fan mode
    - Byte 1: 0x30 = cooling (fan controller)
    - Byte 2: 0x45 = fan mode control
    - Byte 3: 0x01 = set
    - Byte 4: 0x?? = mode number to assign
- IPMI command to set speed for a specific fan zone
    - Byte 1: 0x30 = cooling (fan controller)
    - Byte 2: 0x91 = fan zone control
    - Byte 3: 0x5a = ?
    - Byte 4: 0x03 = ?
    - Byte 5: 0x00 or 0x01 = zone ID (0 or 1)
    - Byte 6: 0x00 - 0xff = speed (1-255) which is %age scale 1-100
- IPMI command to get current fan mode ( 0 | 1 | 2 | 4 ): `raw 0x30 0x45 0x00`
    - Note: the motherboard seems to retain last fan mode on cold boot; not sure about warm boot
- X9 boards will allow setting a speed fan duty of 0 (0%). However, this does not equate to a command to, "stop the fan spinning." Rather, it instructs the BMC to set fans in the given fan zone to their minimum fan speed without stalling the fans.
- X9 boards have fixed ceilings for upper fan speed thresholds
    - Input values are automatically rounded to nearest multiple of 25
    - Upper Non-Recoverable (UNR) maximum value is 19,150 RPM
    - Max value without triggering a rollover is 19,162, as it will be rounded down to 19,150. However, values at 19,163 and higher will get rounded up, triggering a rollover (resets to 0 and counts up from there).

### Notes on Particular X9 Boards
- X9SCL
  - Fan control possible only via BIOS
- X9SCL-F
  - FANA is for add-on card and is controlled by system temperature; control in BIOS only

### Renesas SH7757
A small number of Supermicro X9 server motherboards use the Renesas SH7757 as their BMC. These boards have unknown compatibility. Note that standard Supermicro X9 commands that work with other X9 boards that utilize Nuvoton or ASPEED BMC chips do not work with the Renesas SH7757. Examples of impacted board models include:
- X9DRW-3F
- X9DRW-iF
- X9DRG-QF

## X10 board Characteristics
- Fan speed adjustments are possible
- Usually 4 fan BIOS modes
	- Full
	- Standard
	- Optimal
	- Heavy I/O
- May lack the "Optimal" fan mode
- Fan speed range is 0-FF (0-255) in hex, representing 0-100%
- Fan speeds manipulated by pre-defined and fixed groups of fans called fan zones
- Typically ASPEED AST2400 BMC chipset; a few use Nuvoton WPCM450

## X11 | H11 Board Characteristics
- X11 boards support Intel Skylake and Cascade Lake series
	- 14nm platform, circa 2015-2016
	- LGA 1151 and LGA 2066
	- i3, i5, i7, some Celeron and Pentium processors
- H11 boards support first generation AMD EPYC processors (Naples, 7001 series)
- PCIe 3.0 support
- Manual fan speed adjustments are possible
- BIOS fan modes are generally
	- Full
	- Standard
	- Optimal
	- Heavy I/O
- May lack the "Optimal" fan mode
- Fan speed range is 0-64 in hex (0-100 integer)
- Fan control is by fan "zones"
	- A "zone" is a logical grouping of fans
	- Fan speed control commands are sent to a given fan zone
	- All fans in the same zone respond in kind to the fan zone speed command
	- Fan metadata is reported on an individual fan level
	- Fan zone groupings are pre-defined and cannot be changed
- ASPEED AST2400 or ASPEED AST2500 BMC chip (mostly AST2500)

## X12 | H12 Board Characteristics
- X12 boards support Intel Xeon processors
- H12 boards support second and third generation AMD EPYC processors (Rome, 7002; and Milan, 7003 series)
- PCIe 4.0 support
- Manual fan speed adjustments are possible
- Fan modes are generally
	- Full
	- Standard
	- Optimal
	- Heavy I/O
- Fan speed range is 0-64 in hex (0-100 integer)
- Fan speeds manipulated by pre-defined and fixed groups of fans called fan zones
- ASPEED AST2500 or ASPEED AST2600 BMC chipset
- Most X12 boards work with this model of IPMI fan control: `ipmitool raw 0x30 0x70 0x66 0x01 {fan zone} {fan duty}'
- Different fan threshold behavior
- Supermicro x12 boards only have four:
    - Low NR (lower non-recoverable)
    - Low CT (lower critical)
    - High CT (upper critical)
    - High NR (upper non-recoverable)
- "ipmitool sensor thresh" command reportedly does not work on X12 boards (not confirmed)
    - Meaning an alternative tool must be used, such as lm-sensors

### Particular X12 Boards
The following X12 boards have three (3) fan zones:
- X12DPG-QT6

The following X12 boards allow manual fan control, but require the application of X10 fan control logic:
- H11SSL-i
- H11SSL-C
- H11SSL-NC
- H12SSL-i
- H12SSL-C
- H12SSL-CT
- H12SSL-NC

## X13 | H13 Board Characteristics
X13 is the first generation of Supermicro motherboards purported to allow directly addressable fan sensors. If true, it may be possible to implement fan speed changes at the individual fan header level. This would be a first for Supermicro, which in the past has almost never officially supported this method. If true, then in theory, the IPMI raw command format should be something like this:

`raw 0x30 {ox??} {ox??} {ox??} {fan_sensor_id} {fan_duty}`

Where "fan_sensor_id" would be equivalent to something like (for example): 0x41 = FAN1 or 0x43 = FAN3

- Mostly ASPEED AST2600 BMC chipset (some early boards have the AST2500)
- Manual fan speed adjustments are possible with most boards
- Fan modes are generally
	- Full
	- Standard
	- Optimal
	- Heavy I/O
- Fan speed range is 0-64 in hex (0-100 integer)
- Fan speeds manipulated by pre-defined and fixed groups of fans called fan zones
- Support DDR5 memory and PCIe 5.0
- Fans may also be controlled indirectly by setting custom temperature thresholds
- X13 boards: fan speed thresholds only support Lower Critical (LCR) - others not reported or report as "n/a"

## X14 | H14 Board Characteristics
- Do not support manual fan control
- Fans may also be controlled indirectly by setting custom temperature thresholds
- ASPEED AST2600 BMC chipset
