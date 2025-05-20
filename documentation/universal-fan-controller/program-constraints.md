# Program Constraints
UFC has specific hardware and operating system (OS) requirements, as well as some functional constraints.

The Universal Fan Controller (UFC) is a [flexible](program_features.md) and [modular](design_architecture.md) fan controller intended to monitor and manage the cooling requirements of server-oriented motherboards that support manual case fan speed manipulation. Some non-server motherboards may be compatible with this program, however such systems are uncommon and fall outside UFC's target audience.

Generally speaking, the following characteristics of any given system are required in order to run UFC:
1. Server-class motherboard
2. Motherboard firmware and middleware must support manual fan control
3. Motherboard contains a [Baseboard Management Controller](https://www.servethehome.com/explaining-the-baseboard-management-controller-or-bmc-in-servers/) (BMC) chip
4. Motherboard manufacturer is on the [Supported Motherboard Manufacturers](supported-hardware-manufacturers.md) list
5. Linux operating system
6. OS supports BaSH (or you're willing to modify code to work with another SHell variant)
7. [Required software tools](#software-requirements) are pre-installed

## Hardware Constraints
Your hardware may not be supported. The following checks are recommended before you attempt to install and run UFC.

1. Determine if your motherboard manufacturer is supported by cross-referencing it with this list: [Supported Motherboard Manufacturers](supported-hardware-manufacturers.md)
2. Verify your motherboard contains one of the following BMC chip:
	- ASPEED AST2050
	- ASPEED AST2300
	- ASPEED AST2310
	- ASPEED AST2400
	- ASPEED AST2500
	- ASPEED AST2600
	- Nuvoton WPCM450 / Winbond WPCM450
3. Confirm OS is Linux (e.g., Ubuntu, Debian, CentOS) and supports the following:
	- BaSH (Bourne again SHell) programming language
	- **systemd** (required for service management)
	- **ipmitool** (needed for IPMI protocol communication)
4. Verify your motherboard's middleware supports IPMI 2.0 protocol. If it only supports IPMI 1.5, UFC is likely to work, but may not.
5. Ensure your motherboard allows manual control of CPU and case fan speeds.
	1. If you have a Dell server motherboard, review the [Dell caveats](#Dell) before proceeding.
6. You can cross-check the [Fan Control Compatibility Chart](fan_control_compatibility_chart.md) for more details.
7. If support is unknown or unconfirmed, proceed with caution, recognizing UFC may not be a viable solution.

## Functional Limitations
- UFC is [not compatible](supported-hardware-manufacturers.md#non-supported-motherboards) with every motherboard
- If you wish to change parameters for an existing implementation of UFC, you must re-run the Builder in order to do so
- When swapping out fans, re-run the Builder
- UFC is not designed to function in virtualized containers and is unlikely to function at all in such environments (attempting to do so ***will result in unpredictable behavior***)
- Combining or "mixing" different types of data storage devices may lead to unpredictable errors (see [Segmenting Mixed Device Ecosystems](best-practices.md#Segmenting-Mixed-Device-Ecosystems) and [Excluding SSDs](best-practices.md#Excluding-SSDs))
 
## General Hardware Limitations
Even with a compatible BMC chip, it is possible this program will not run at all or work correctly with your motherboard. This program depends on the following capabilities:

1. Supportive functional capabilities of BMC chip
	1. If the BMC chip will not allow IPMI to control fan speeds, UFC will be ineffective or completely non-functional (some monitoring and reporting functions may still work).
	2. Most BMC chips allow their functions to be customized to some extent by the motherboard manufacturer. Thus, identical BMC chips installed in different motherboards may require different IPMI commands to elicit the same behavior, or in some cases behaviors may be disallowed.
2. Choices made by the motherboard manufacturer with regards to:
	- Which functions of the BMC are exposed to middleware software (e.g. ipmitool, OpenBMC, FreeIPMI)
	- Whether or not the IPMI 2.0 protocol is supported
	- Allow manual fan speed control outside the BIOS
	- Locking out some portions of BMC control (e.g. some Dell iDRAC firmware versions, HPE iLO and Lenovo XClarity are other examples of firmware that may restrict access)
	- Restricting access to certain BMC functions, such as fan control, due to proprietary firmware limitations.

## Manufacturer-Specific Hardware Limitations
UFC will work with most motherboards that contains a compatible BMC and supports IPMI 2.0. Not all motherboards include a BMC chip, nor do all server boards. Do not presume your board has a BMC chip unless you have confirmed this by cross-referencing your manufacturer's supported motherboard models with an authoritative list. Specific motherboard manufacturer compatibility is tracked [here](supported-hardware-manufacturers.md), but you will need to perform further validation with regards to a specific motherboard model.

### AsRock Rack
- AsRock Rack server boards allow individual fan control, but commands must be sent to all fans simultaneously. This means while fans can be controlled individually, they cannot be targetted individually via IPMI commands.
- Support for isolated individual fan control in UFC is on the roadmap of future enhancements

### Dell
Support for Dell motherboards is adversely affected by their [iDRAC](lexicon.md#idrac) version. Due to an unfortunate decision by Dell with regards to its proprietary iDRAC controller software, many Dell systems are incompatible with non-BIOS based fan controllers, such as UFC. See the article [Dell iDRAC Limits](/documentation/manufacturers/dell/dell-idrac-limits.md) to learn more details.

### Supermicro
Supermicro was the base case when UFC was conceived. The first prototype was built for Supermicro boards only. Supermicro and ASRock boards are the most widely supported by UFC.

- **May** work with some X8 boards
- **Does** work with X9, X10, and X11 motherboards
- **Should** work with H11, H12, and X12 boards
	- Supermicro X12 board support is considered _experimental_
- Supermicro H13, X13, X14, and later boards are _not supported_ at this time
- H12 boards **should** work
	- some H12 boards use the same BMC chip as X11 boards, and some use the same chip as X12 boards
