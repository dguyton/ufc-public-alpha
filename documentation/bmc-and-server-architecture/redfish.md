# Redfish API

Redfish is a modern and robust Application Programming Interface (API) based server-management platform designed specifically to supersede and replace the [Intelligent Platform Management Interface (IPMI)](/documentation/ipmi.md) protocol with a more flexible and consistent set of standards. Built from the ground-up and sharing nothing with its predecessor, Redfish is intended to replace IPMI and is not natively backwards compatible. The two protocols can, however be run concurrently on the same Baseboard Management Controller (BMC) chip. There is nothing within either protocol's standards that preclude this, although naturally the BMC chip itself must be configured to support either, or both.

## Re-inventing the Wheel
Redfish brings substantial improvements to the table over IPMI. From an architectural standpoint, Redfish is more robust, scales much more readily, and is less prone to security vulnerabilities. This is all because Redfish applies a modern API model toward processing command instructions to the BMC, and output from those commands. While it is primarily a communications protocol, it also adds structure to the BMC and how it manages data. This latter point is a feature largely absent from IPMI standards.

Through its API, Redfish provides a cleaner environment to scale up new features, and makes it easier for both the BMC and related user-facing applications to determine which features in the BMC are available and accessible to users and/or other parts of the system.

## Redfish Implementation
A system vendor desiring to add Redfish capability to a BMC chip will need to either create some sort of proprietary implementation of the Redfish API standards or incorporate an off-the-shelf solution such as [bmclib](#bmclib) or [OpenBMC](#openbmc).

### bmclib
[bmclib](https://github.com/bmc-toolbox/bmclib) is a concise, cross-platform library-based tool built on the Go programming language. Compatible with IPMI 2.0 and Redfish, **bmclib** is a drop-in library of tools to support creating custom interfaces that will interact with a BMC chip via Redfish or IPMI.

### OpenBMC
[OpenBMC](https://github.com/openbmc/openbmc) is an open-source firmware stack for BMCs intended to assist developers coding the BMC chip itself. OpenBMC is not a tool you directly run to manage hardware. Rather, it replaces the proprietary firmware (embedded software) that typically runs on a BMC. OpenBMC assists the system with managing hardware and enables users to manage hardware remotely. 

OpenBMC provides the underlying software environment that enables the BMC chip to manage system hardware, perform remote monitoring, logging, power control, and offer other out-of-band management capabilities.
 
It allows users (and systems) to interact with the BMC's hardware using IPMI or Redfish.

#### User Interaction with OpenBMC
Users (and systems) may access the BMC's capabilities via interfaces that understand Redfish or IPMI (e.g. Web-based tool provided by motherboard vendor, or [3rd party tools](/documentation/bmc-and-server-architecture/bmc-access-tools.md#ipmi-tools-for-end-users), such as **ipmitool**).

OpenBMC also allows a custom interface to be built on top of OpenBMC and hard-coded into the BMC firmware, though this practice is uncommon. The benefit of this approach is that all of the software supporting the BMC's tasks is contained within the BMC itself. Everything from receiving and processing commands to the end user interface are centralized. This also makes the user interface readily and instantly available on power-up. A disadvantage to this approach is that in order to make any changes to the BMC management ecosystem - including the user interface - requires a firmware update.
