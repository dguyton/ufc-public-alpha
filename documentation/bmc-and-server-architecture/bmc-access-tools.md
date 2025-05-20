# Communicating with the BMC
There is often confusion regarding how to access BMC capabilities. While users may have heard of [Intelligent Platform Management Interface (IPMI)](/documentation/ipmi.md) and/or [Redfish](redfish.md), many are not familiar with what they are or how to use them.

Both IPMI and Redfish are [protocols](protocols.md). This means they are communication *methods*, rather than communication *applications*. In order to actually perform any action, both the BMC itself and the user-facing tool attempting communication with the BMC needs to understand the same protocol. This might sound obvious, but knowing what will work ahead of time can be a bit trickier than one might expect. It is not uncommon for hardware vendors to program BMCs with support for a limited sub-set of functionality for IPMI or Redfish. Furthermore, some features might be supported via one protocol or the other, but not both.

There are no guarantees as to what will or will not work from an end-user perspective. Not all IPMI and Redfish tools will work correctly with every BMC. User-facing access tools don't have a way of knowing which commmands will or will not be acceptec by the BMC. They will allow a user to attempt any command they support, without regards to supports on the receiving end by the BMC. The point being, these user-facing tools are normally not very sophisticated, and the need for a fair amount of back-and-forth experimentation is not uncommon. That said, what tools are out there for end users to communicate with a BMC?

Nearly every server motherboard manufacturer provides proprietary Command-Line Interface (CLI) or Web-based tools, such as:
  - Supermicro's IPMIview, a GUI-based tool for managing multiple servers
  - Supermicro's SuperDoctor, focuses on hardware status and system health
  - ASRock's ASRock Rack Server Management Utility, a proprietary tool provided for monitoring and managing multiple servers

These tools typically utilize either IPMI or Redfish as their back-end communications protocol, although in some rare instances, other protocols are used, including custom proprietary communciation methods.

## IPMI
IPMI is a legacy BMC communication protocol, making its use nearly universal. The final standard for IPMI - IPMI 2.0 - was released in 2004. The prior standard - version 1.5 - may be found on some very old server boards. IPMI versions prior to 1.5 should be considered obsolete and avoided.

### IPMI Tools for End Users
Several well vetted and freely available tools exist that allow end users to communicate with the BMC via IPMI. Below is a brief description of each and a cross-reference table mapping their compatibility with operating systems they may be run on. Note that these tools are command-line driven only. None of them include a GUI (Graphical User Interface). Most server motherboard manufacturerers maintain some sort of Web-based tool that allows end users to interact with the BMC. These tools typically rely on IPMI and/or Redfish protocols to communicate with the BMC, though this detail is not a concern for the user.

- [FreeIPMI](https://www.gnu.org/software/freeipmi/) : Collection of IPMI utilities and libraries for remote server management (e.g. ipmi-sensors, ipmi-config, ipmi-sel)
- [IPMItool](https://github.com/ipmitool/ipmitool) : Widely used, self-contained (no libraries) command-line utility for managing IPMI-enabled systems.
- [ipmiutil](https://sourceforge.net/projects/ipmiutil/) : Lightweight tool intended for power control, SEL management, sensor readings, event logging.
- [OpenIPMI](http://openipmi.sourceforge.net/) : Linux kernel-based IPMI device driver.

| Tool     |   IPMI   | Redfish |  Operating Systems  | Interface |
| -------- | -------- | ------- | ------------------- | ---------
| FreeIPMI | 1.5, 2.0 |   ---   | Linux, BSD          | CLI       |
| IPMItool | 2.0      |   ---   | Linux, Windows, BSD | CLI       |
| ipmiutil | 1.5      |   ---   | Linux, Windows, BSD | CLI       |
| OpenIPMI | 2.0      |   ---   | Linux               | CLI       |

### IPMI Compatibility Risks
These tools may not work correctly with some BMCs, as noted.
- FreeIPMI
  - Supports IPMI 1.5, 2.0
  - May not work well with proprietary BMCs implementing non-standard extensions or vendor-specific features.
- ipmitool
  - Supports IPMI 2.0 only
  - May not work well with proprietary BMCs implementing non-standard extensions or vendor-specific features.
  - ipmitool advanced features (e.g. SoL or Serial-Over-LAN console commands) may not work on older boards.
- ipmiutil
  - Supports IPMI 1.5 only
  - Greater compatibility with older BMC chips (pre-version 1.5).
- OpenIPMI
  - Supports IPMI 2.0 only
  - May not work well with proprietary BMCs implementing non-standard extensions or vendor-specific features.

## Redfish
Redfish is a modern API-based protocol intended to replace IPMI. Normally, a system vendor who chooses to add Redfish capability to a BMC chip will also create some sort of custom user-facing application. That application will simply use the Redfish protocol to communicate with the BMC.

There are very few user-facing tools allowing an end user to communicate with a BMC via Redfish that is not some sort of proprietary tool tied directly to a specific BMC implementation. A noteworthy exception to this rule is the [Redfish Utility](https://dmtf.github.io/python-redfish-utility/). Created and maintained by Distributed Management Task Force (DMTF) - the non-profit industry standards organization that created Redfish - this CLI-based utility runs in most Linux and Windows environments.

Redfish support is much more heavily skewed toward the BMC applications side of the equation, where several tools and/or libraries are designed to assist BMC manufacturers and system vendors with implementing Redfish in modern BMC hardware capable of supporting it. Two of the most well known are **bmclib** and **OpenBMC**. Both are described in more detail [here](redfish.md).
