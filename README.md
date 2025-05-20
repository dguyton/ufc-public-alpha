# Overview
The Universal Fan Controller (UFC) is a stand-alone fan management utility for Linux servers, written in BaSH (Bourne Again SHell).

UFC monitors and adjusts fan speeds in real-time to maintain optimal CPU and disk storage temperatures while minimizing fan noise. It employs a two-tiered approach: a simple rule-based method for CPU cooling, and a more advanced [P.I.D. controller](/documentation/universal-fan-controller/pid-explained.md) logic model for device temperature regulation.

Originally developed for enthusiast home lab users repurposing enterprise hardware, UFC addresses the limitations of [basic fan control solutions](/documentation/universal-fan-controller/simple-no-bueno.md) by delivering precise, automated thermal management.

UFC is intended to run on headless Linux servers, and operates in the background as a **systemd** service. After the initial setup and configuration process, it requires no manual intervention and is fully automated.

> [!TIP]
> This document is an overview of the Universal Fan Controller project.
>
> See the bottom of this page for a list of links to more detailed documentation.

# Unique Features
UFC differentiates itself from most other P.I.D. based fan controllers through these features:
- Wide range of compatible hardware
- Supports single and multi-zone fan systems
- Supports direct fan and zone-based fan controllers
- Automatic hardware detection and analysis
- Prioritizes CPU cooling over disk/chassis temperature management
- Failed fan detection
- Automated configuration
- Extensive logging capabilities
- Persistence between system reboots
- Failsafe mode for hardware protection
- Cleans up after itself
- Thorough documentation

For more details, see the full list of [Program Features](/documentation/universal-fan-controller/program-features.md) and [Program Goals](/documentation/universal-fan-controller/program-goals.md).

# Use Cases | Target Audience
UFC was envisioned, designed, and built to run on Linux operating systems, on enterprise-class hardware. Specifically, server-grade motherboards typically found in an enterprise environment, such as a network or data center. It is **not** suitable for standard desktop environments.

### Primary Use Cases
- General purpose rack-mount servers in a home lab environment
- Maintaining minimal or optimal ambient air temperatures for
	- Mechanical storage devices (hard drives, tape drives, etc.)
	- Solid state storage devices (SSDs, m.2, or PCIe based)
	- Graphic cores and graphics cards

### Not Intended For
- Data centers
- Temperature-controlled environments where noise is not an issue
- Desktop or workstation computers
- Appliances, such as Linux-based networking appliances (e.g. network routers)
- Proprietary, non-standard, task-specific motherboards (e.g. alarm system control panels)

### May Not Work Well With
- Non-x86 based devices

# Minimum System Requirements
1. Supported server-class motherboard
2. Compatible Linux based operating system (e.g. Debian based)
3. Operating system must have access to server hardware
4. Required pre-requisite programs installed
5. Ability to modify base .config file and run Builder from a command line

## Supported Operating Systems
Linux.

UFC should work well out-of-the-box with little or no modifications on most Debian-based Linux operating systems. Please pay particular attention to UFC's [Design Architecture](/documentation/universal-fan-controller/design-architecture.md) before installing and attempting to run the programs. UFC is a multi-part system that requires a specific order-of-operations to implement correctly.

## Supported Motherboard Manufacturers
- AsRock
- Asus $^1$
- Dell
- Gigabyte $^1$
- HP/HPe
- Hyve $^1$
- IBM
- Intel
- Lenovo
- NEC $^1$
- Quanta $^1$
- Sun Microsystems $^1$
- Supermicro
- Tyan $^1$

$^1$ Limited support at this time<br>

## Non-supported Hardware Types
- Motherboard manufacturers not explicitly mentioned above
- Graphics card daughter-boards
- Blade servers
- [Graphcore](/documentation/manufacturers/non-supported-hardware/graphcore-bmc.md) BMCs

## Program Prerequisites
These programs are open-source and readily available. Most come pre-installed on most Linux based operating systems.

#### Required
- [ipmitool](https://github.com/ipmitool/ipmitool)
- awk

#### Recommended
These 3rd party programs are strongly recommended. Some of these programs - when not present - can or will substantially reduce the range of capabilities of the Service programs.
- [lm-sensors](https://github.com/lm-sensors/lm-sensors)
- logger $^2$
- postfix or sendmail
- smartctl $^3$
- hddtemp $^3$

$^2$ Required to enable log reporting in system log (syslog)</br>
$^3$ One or the other is required or program functionality will be severely limited<br>

## Program Design
The Universal Fan Controller is a modular fan speed management ecosystem comprised of three (3) independent, task-focused programs, and a bastion of complementary supporting subroutines, templates, and configuration profiles.

## Core Components
The core components are:
1. Builder - single shot broad configurator based on user declared configuration variables
2. Service Launcher - single shot environment-conscious configurator on system start-up
3. Service Runtime - continuous loop responsible for fan management 

UFC uses a modular design centered around a separate, stand-alone configuration and setup tool run once called the **Builder**, and a bifurcated **Service** platform that runs continuously. The latter consists of an independent mini-setup tool (*Service Launcher*) utilized at system startup to establish environmental constraints in real-time, and the business end of the system (*Service Runtime*) performing the actual fan monitoring and control tasks.

More detailed information may be found in [Design Architecture](/documentation/universal-fan-controller/program-design.md).

> [!NOTE]
> You may need access to technical documentation about your hardware.
> 

## Daemonized Processes
The UFC Builder is a stand-alone SHell script that must be run from the command line. The Builder takes care of the initialization process of the Service programs: the Launcher and Runtime programs. The Service programs (Launcher and Runtime) both run unattended in the background as systemd daemon services. 

Only one daemon service is operating at any given time. When the server is booted, the Service Launcher is triggered during the server's start-up sequence. The Launcher completes its tasks and initiates the Service Runtime program, which runs in perpetuity until the server is shutdown or restarted.

# Programming Language and Customization
UFC is designed for Linux-based platforms and written entirely in *Bourne again SHell* or **[BaSH](https://datahacker.blog/linux/bash/bash-bourne-again-shell)**, a common **SHell** programming language variant.

The code is designed to be POSIX-compliant for portability, while taking into consideration the level of complexity required for some features. This means UFC's SHell code is *mostly* compliant with the POSIX standard. Regardless, some customization would likely be required to port it to an alternative platform/programming language.

## Why SHell?
SHell is a ubiquitous programming language found by default on all Linux and UNIX based systems. This makes it well suited to hardware and system-level management utilities such as the Universal Fan Controller.

UFC does require a small number of pre-requisite programs, but they are readily available on any given flavor of Linux. Outside of these common utilities, UFC is self-contained. While some portions of UFC's code could have been consolidated by incorporating various off-the-shelf programs, an effort was made to avoid the use of complex additive programs maintained by another party, as this would have created an undesirable dependency. Furthermore, most such programs are siloed to certain operating system variants, and thus relying on such support would have in turn made UFC less portable.

Related details, including a complete list of required pre-requisite programs UFC expects, may be found in the [Program Requirements](/documentation/universal-fan-controller/program-requirements.md) and [Design Architecture](/documentation/universal-fan-controller/program-design.md) documentation pages.

## Testing
UFC was developed and tested on headless Ubuntu servers. It has been through end-to-end stress-testing across multiple Ubuntu server implementations, on different hardware (including different motherboards, hard drives, and solid-state drives).

UFC has undergone primary testing on Supermicro server motherboards.

Additional testing and constructive feedback to the author's GitHub page is encouraged. You are also free to use, modify, and publish your own changes, subject to UFC's licensing agreement.

## How Stuff Works
1. [Program Requirements](program-requirements.md)
2. [Program Architecture & Design](program-design.md)

## Is UFC for me?
1. [Supported Hardware](supported-hardware-manufacturers.md)
2. [Selecting a server motherboard](choosing-server-mobo.md)

## Administrivia
1. [Best Practices](best-practices.md)
2. UFC's [Program Goals](program-goals.md)
3. UFC [Roadmap](roadmap.md)
4. Current version [Release Notes](release-notes.md)
5. Program [History](history.md)
6. [Lexicon](lexicon.md) of freqently used terms
7. [Do's & Don'ts](dont-do-this.md)

## Tech Stuff
1. Select [Technical Details](tech-details.md)
    - Global variable naming syntax
    - How metadata is tracked
3. [Frequently Asked Questions (F.A.Q.)](faq.md)
4. [Troubleshooting](troubleshooting.md)
