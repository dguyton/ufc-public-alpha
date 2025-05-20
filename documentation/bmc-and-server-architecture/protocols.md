# Communicating with the BMC

How does one communicate with the BMC and interact with low-level hardware components?

The short answer is: you need two (2) things:
1. A communications tool that understands one or more of the protocols the BMC understands; and
2. A human user interface to interact with the communications protocol.

## Protocols
The first of these is a bit easier to tackle. We can group BMC-compatible protocols into three (3) type groups:
1. Legacy
2. Modern
3. Proprietary

What do these types of protocols mean?

### Legacy Protocols
"Legacy" in this case means protocols that have been around for a long time. They are supported by virtually all server motherboards. It is likely these protocols will eventually be phased out, but for now they remain industry standards. It also does not require much work for hardware vendors and motherboard manufacturers to include compatibility with them, and removing their presence would be frowned upon by many system administrators due to the large number of existing remote management tools that utilize some or all of these protocols. Unless you plan on utilizing only cutting-edge motherboard designs, your ability to use any of these should be a safe bet.
- IPMI ([Intelligent Platform Management Interface](/documentation/ipmi.md))
	- An IP based protocol specifically designed for communicating with BMCs and similar devices
 	- Intended to be completely independent of the BIOS and operating system
  	- Referred to as an "out-of-band" communications protocol
  	- Released in 1998
  	- Showing its age, partly in the form of security concerns which prompted alternate protocols to be developed.
- SNMP ([Simple Network Management Protocol](https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol))
	- An universal protocol that is part of the global IP (Internet Protocol) standards
 	- The oldest protocol (circa 1988)
  	- Created/Invented by the IETF (Internet Engineering Task Force)
- SSH/SFTP (Secure SHell / Secure File Transfer Protocol)
	- Direct connections to a BMC through some sort of network interface
 	- Almost as old as SNMP (circa 1995)

### Modern Protocols
"Modern" in this case means any protocol that was developed after the legacy protocols. Obviously, motherboards manufactured prior to their introduction won't support them. It takes time for a new protocol to attain widespread adoption.
- Redfish
	- Arguably the most well-known modern protocol
	- Introduced in 2015, making it the youngest/newest protocol
 	- Modern architecture (RESTful API with human-readable JSON parameters)
- SMASH (Systems Management Architecture for Server Hardware)
	- Command line interface (CLI) based
 	- Invented by the DMTF (Distributed Management Task Force)
 	- Released in 2006
  	- Overall well thought out protocol, but adoption was limited. Now largely supplanted by Redfish.
- WS-Man (Web Services Management)
 	- Guidelines for protocol usage within the context of Web-based interfaces
	- Also invented by the DMTF
 	- Released in 2005
  	- More finicky and complex to implement compared to Redfish
- CIM (Common Information Model)
	- Relatively obscure today, but is the foundation for SMASH
 	- Also invented by the DMTF
  	- Released in 1999
  	- More finicky and complex to implement compared to Redfish

### Proprietary Protocols (Vendor Specific)
Proprietary protocols are specific to a particular motherboard manufacturer (vendor) or BMC chip brand. Examples include:
- RACADM: Dell's Remote ACcess ADMinistrative controller, a proprietary remote access protocol for their [iDRAC](/documentation/manufacturers/dell/dell-idrac.md) system
- iLO: Integrated Lights-Out is HPE's (Hewlett-Packard Enterprise) RESTful API
- IMM: IBM's 'Integrated Management Module' found on the IBM System X series, along with some newer model lines
- ISM: Intel Server Management, which manages Intel's proprietary BMC chips
- RIBCL (Remote Insight Board Command Language): HPE's proprietary communication language model used with their iLO API
- XCC: XClarity Controller (also known simply as XClarity), this is Lenovo's flavor of API-based server management

## User Interface
The next question is, how does one utilize a given protocol? This is where things can get a bit more complicated, as the user interface options available under any given circumstances may not clearly identify which underlying protocol is in use. In many cases, this likely doesn't matter. However, under some circumstances it may be necessary to know, particularly when dealing with 3rd party or open source solutions.

- **Web interface (GUI)**
	- For monitoring and controlling the server's hardware, including fan speeds, temperature readings, and more.
	- Interface is normally accessed via web browser connecting to the server's IP address, connecting to a specified port number.
	- May provide capabilities not available with some other protocols, such as IPMI (e.g. setting thermal curves for fan speed thresholds).
 	- All types of protocols may use this method. Proprietary methods in particular are highly likely to include a web interface provided by the motherboard or BMC vendor.
	- Examples that use this model: [Dell iDRAC web interface](/documentation/manufacturers/dell/dell-idrac.md), Supermicro's and Tyan's java-based tools
- **CLI (Command-Line Interface)**
	- Command-line drive tool via directly on the server (in-band) or remotely (out-of-band) via SSH (e.g. Putty).
	- For advanced users. Less common to find in use, or promoted by vendors.
 	- Documentation tends to be poor and/or difficult to find. Terminology may be confusing.
 	- Example: IPMI
- **API (Application Programming Interface)**
	- For automation and integration with other management tools, allowing third-party applications or scripts to interface with the middleware.
	- Examples that use this model: [Redfish](/documentation/bmc-and-server-architecture/redfish.md), [iDRAC](/documentation/manufacturers/dell/dell-idrac.md)
- **Remote KVM (Keyboard, Video, Monitor)**
	- Remote access over IP, simulating the presence of physical KVM (keyboard-video-mouse) devices that may be physically connected to the device or simulated virtually.
	- May be considered "back door" access to some extent because the operating system is normally blind to the existence of the KVM connection to the server.
- **One-way Monitoring**
	- Monitoring/Status alerts such as through email notifications, such as SNMP traps.
 	- Least common and least useful method.

## Choosing a BMC Communication Protocol
So, which is the best protocol to use? The answer to this question boils down to the hardware in play and personal preferences. However, it is posslbe to glean some strong recommendations based on how these protocols work and the tools currently available to implement them.

First break down the scenarios where manufacturers will force your hand. These are scenarios where you will be forced to use proprietary solutions at least some of the time, and you will likely be limited in your choices for non-proprietary protocols. Let's examine your options based on hardware manufacturer and/or BMC vendor.

### Recommended Protocols
When there is a choice, aside from manufacturer-specifc solutions, IPMI and Redfish stand out as the best universal choices for server management protocols.

#### IPMI
IPMI is ubiquitous. It works on modern servers and legacy or older servers. This makes it attractive from a compatibility perspective. However, implementing commands via IPMI is onerous. It provides limited and non-human friendly feedback (if any) when something goes wrong. It is command-line driven only. It is esoteric. Becoming an expert in IPMI usage requires a very good memory to recall specific hexadecimal values in the correct order, and which often vary from server to server (even from the same manufacturer). However, in spite of its cons it is a solid and well-vetted protocol for many use cases.

IPMI is well suited to infrequent server updates, or circumstances where wide-spread compatibility across different server manufacturers is paramount.

#### Redfish
Intended to replace IPMI, Redfish is a modern protocol for handling server management that addresses all the shortcomings of IPMI. The downsides to Redfish are that it is not universally supported, and it has a considerably larger footprint int erms of its use. Mastering Redfish requires the end user to have a grasp of multiple modern technologies and best practices (e.g. JSON structure). That said, Redfish is much more conducive to organized server management, such as when a user is responsible for coordinating changes across a swath of servers or making frequent adjustments.

Redfish is a more straightforward and easier to manage protocol (as compared with IPMI) when a large number of servers needs to be managed or monitored concurrently, and/or a limited number of server manufacturers will be monitored, where it is known in advance that all the servers in the population will support Redfish.

### Dell
When it comes to Dell/EMC servers, there is of course the obvious fact you're stuck with iDRAC in at least some capacity.

#### iDRAC: Dell's All-in-One Solution 
Dell arguably has the most sophisticated integrated server management ecosystem. The company has been developing its iDRAC platform since the initial release of iDRAC in 2008. The project started out as part of Dell's relentless drive to stamp out excess production costs, by bringing BMC-like needs and server management software in-house. In terms of control over the server environment, iDRAC more-or-less locks it down more thoroughly than any other siimilar solution. For a deeper dive into this vertical hardware control platform, see [Dell's iDRAC](/documentation/manufacturers/dell/idrac.md).

#### IPMI
IPMI is compatible with all Dell servers with iDRAC. Note however, that it must be explicitly enabled. This means you must first get into the iDRAC settings before IPMI can be utilized. IPMI functionality is disabled by default. Remember that iDRAC is both a firmware (software) and a hardware based solution. What you are enabling or disabling is whether or not the hardware portion listens to or ignores IPMI commands.

#### Redfish
Redfish is widely supported by Dell servers from iDRAC 8 onward, which encompasses generation 13 and later of Dell's servers. More information about Dell's server line-up may be found [here](/documentation/manufacturers/dell/dell-choosing-best-poweredge-server.md).

### HPE | IBM | Intel | Lenovo
While generally not as sophisticated or extensive as Dell's iDRAC, certain other manufacturers force similar solutions upon the user. HPE, IBM, Lenovo, and Intel are also known for using own proprietary management protocols in many of their servers. Like Dell, these manufacturers have created their own proprietary BMC chip for many of their server lines.

#### HPE's iLO
Supports IPMI universally. Supports Redfish in Gen10 and later server generations using iLO versions 5 and later.

#### IBM
IBM uses either 3rd party BMC chips or its own home-grown chips, depending on the server line. Servers utilizing IBM's Integrated Management Module (IMM) - found on the IBM System X series and potentially others - supports both IPMI and Redfish. Other IBM server support will depend on their BMC chip when it is not an in-house IBM branded chip.

#### Intel
Intel is unique in this space because in addition to its own proprietary protocol (Intel Server Management), the company also sells its BMC chips to others. Intel is the only manufacturer with its own custom BMC chips that also resells them, placing them in direct competition with ASPEED and Nuvoton. This means you may find non-Intel servers with Intel BMC chips and potentially also running ISM.

Intel BMC chips and its ISM firmware support IPMI and Redfish.

#### Lenovo
Lenovo supports both IPMI and Redfish, along with Lenovo-specific APIs from its XClarity Controller (XCO) platform.
