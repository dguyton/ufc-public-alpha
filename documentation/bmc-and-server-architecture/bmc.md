# Baseboard Management Controller (BMC)
The Baseboard Management Controller (BMC) is a dedicated chip responsible for overseeing the management of various hardware components on a server motherboard. The BMC offers centralized communications (and therefore control) over various system hardware components on server motherboards. BMC chips are almost always included on on server motherboards. On other motherboard types, such as workstation and consumer boards, there typically isn't a BMC chip, and the BIOS is directly connected to other hardware components. These components may also be directly connected with each other to some extent. The point being that server boards tend to lean toward centralized command-and-control or management of communications between hardware components, whereas non-server boards tend not to do so and rarely have BMC chips.

The BMC is not useful in terms of computing tasks. It's sole purpose is to allow monitoring and management of the physical server environment.

# Why the BMC Matters
The purpose of the BMC is to allow controlling low-level server functions independently of any operating system on the server. The BMC does not monitor nor interfere with hardware components that are managed by the CPU. For example, PCI/PCIe rails, SATA ports, and USB ports. This means communication with storage devices, for example, don't involve the BMC. Neither does communicating with the CPU(s). 

You may think of the BMC as a helper. The purview of the BMC is limited to non-computational hardware components that don't involve computing. It relieves the CPU from the responsibility of monitoring and responding to temperature sensors, power functions, and other low-level hardware such as the [fan controller](#the-fan-controller).

BMC's are not meant for typical users. They are the domain of system administrators and procurement specialists. An exception being if for some reason a user wants or needs a server to perform some sort of action that involves low-level hardware not controlled by the CPU, storage devices, or another peripheral device (e.g. graphics card). For instance, fans attached to a GPU are most likely regulated by the GPU itself. However, regulating the speed and noise of fans connected to the motherboard's fan headers would be managed by the BMC.

## Video Hijacking
A bit of an oddball feature of the BMC is its native ability to intercept video output. One of the core capabilities of the BMC is snooping on the current video output. This allows remote users to see when an operating system has crashed or a server is stuck on an error during boot, to name just a couple of use cases related to this feature. In short, an intgral function of the BMC is to support remote KVM (Keyboard Video Mouse) capabilities, particularly in order to manage a server remotely for a number of reasons. By hijacking these human interface functions, a remote user may act as if they were in front of the server with a monitor, mouse, and keyboard hooked up to it directly. This provides a significant savings in labor and time for users managing multiple servers.

## Motherboard Architecture
The majority of server motherboards utilize a star topology design, or "hub-and-spoke" method of communication between hardware components. The BMC is in the center (the "hub" per se). Requests to and from hardware components (the "spoke") may be passed via various protocols to and from the BMC chip, which acts as a central clearinghouse to facilitate hardware requests from external software. From a usability perspective, this enables system administrators to interact with hardware on the server directly.

## Common BMC Chips
The most prevalent BMC chip manufacturers, in order of most-to-least common.

### ASPEED
By far the most ubiquitous 3rd party brand BMC chips, ASPEED chips are the most likely to permit manual fan speed control. The most common variants are their "AST-" line, such as AST2300, AST2400, AST2500, and AST2600. There are numerous similar iterations in between those, with slightly different model numbers. Generally speaking, the capabilities and architecture of ASPEED AST-series BMC chips are going to be relatively equal for chips within the same generation which means the first 2 model numbers after the "AST" (i.e. AST24xx for example, where AST2400 is the generation). Other naming conventions such as AST2150 and AST2350 tend to be more heavily customized and more restrictive. When considering the potential for manual fan control capabilities via IPMI, the AST2400 and AST2500 chips have the highest likelihood of allowing such behavior, when all other factors are equal.

### Nuvoton / Winbond
Nuvoton and Winbond are effectively the same company. Nuvoton is the more recent branding. The company was spun off from Winbond in 2008, and re-branded itself as "Nuvoton" at that time. Some of their BMC chips have the Nuvoton branding, some have the Winbond branding, and some could have both. Regardless, the important thing to know here is their names may be considered synonymous.

Nuvoton BMC chips are less common than ASPEED chips. They also tend to be permissive with regards to manual fan speed control. While most of their chips do allow it, even the same BMC chip model on different boards may or may not allow manual fan speed control on that particular board. There is a general lack of consistency, which makes predicting fan control compaitibilty more difficult, especially as compared to ASPEED chips.

### Intel
Similarly to Dell, Intel is known for including numerous proprietary components in their servers, as it allows them more control over every aspect of the server. Intel has its own line of BMC chips. Generally speaking, they are only found in Intel servers, but from a manufacturing perspective Intel is rather unique. Intel's philosophy is quite similar to Dell's, however Intel takes it to another level. While Dell incorporates its own custom and proprietary chips and an integrated firmware into their own servers, Intel takes this process a step further by also marketing and selling their BMC chips to other OEM manufacturers. This makes Intel the only server motherboard manufacturer who both creates their own proprietary BMC chips, and also markets them to others. Thus, Intel's BMC-like solution is an actual BMC chip, while Dell's solution is not.

### Renesas
A small BMC chip supplier. Very uncommon to encounter in the wild, but it does exist. They almost always support IPMI 2.0. Renesas was acquired by IDT in 2019. In terms of mainstream server manufacturers, Renesas BMCs are predominantly found in some Supermicro server boards. Due to their rarity, information on manual fan control support via IPMI is relatively inconclusive.

### Graphcore
Graphcore is a niche server manufacturer that produces machine learning IPU's (Intelligent Processing Units). The company also manages proprietary, custom BMC, aptly named after the company: [Graphcore BMC](/documentation/universal-fan-controller/non-supported-hardware/graphcore-bmc.md).

Graphcore's BMC chips support [IPMI](/documentation/ipmi.md) and the [RedFish](/documentation/redfish.md) standard.

## Accessing the BMC Remotely
Accessing the BMC and its capabilities requires the use of a compatible communications protocol. Which protocols may be utilized depends on the particular BMC chip and how the server manufacturer has designed the motherboard and programmed the portion of the BMC chip that is configurable. For more information on choosing a compatible protocol, see [BMC Protocols](protocols.md).
