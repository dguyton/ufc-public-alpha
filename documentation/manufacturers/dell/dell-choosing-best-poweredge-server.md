# Selecting the Best PowerEdge Server
Many of Dell's PowerEdge servers are a great choice for Home Lab users. The question is, which one best suits your needs? It's important to understand which server models are good, and which should be avoided.

If you want the TLDR; version, check out the [Dell server buyer's guide](dell-server-buyers-guide.md). If you want to know the details, read on.
## iDRAC Version Guidelines
In general, lean towards iDRAC major release versions 7, 8, and 9. This will allow you a wide latitude in finding a server that is capable enough to meet your technical needs, while also providing a wide choice of server models that are capable of manual IPMI-based fan control, if that is a priority for you.

### Caution on iDRAC 6
iDRAC 6 - found on gen 10 and some gen 11 servers - will be running iDRAC 6. These servers should generally be avoided as while they may allow manual IPMI fan controls, they are not compatible with OpenBMC. This means your choice of IPMI tools will be more limited as compared with iDRAC 7+ servers. These generation servers are also typically under-powered by today's standards, even for rudimentary tasks.

### iDRAC 9 Has the Most Variations in IPMI Support
iDRAC 9 - found on gen 14, 15, 16, and 17 servers - has the [widest variation](dell-idrac-fan-control.md#the-four-chapters-of-idrac-9-ipmi-fan-support-2017---2025) of IPMI fan support capabilities, which makes it the most challenging iDRAC version to determine IPMI fan compatibility.

## The Goldilocks Models
Dell server generations 12, 13, and 14 are the sweet spot for home lab use. Not too modern. Not too old. These models are "just right." 

For basic computing needs, gen 12 provides a low cost entry point with modest computing power by today's standards. You'll gain all the benefits of enterprise quality hardware components and tools such as Dell's iDRAC controller, and you should be able to manually control case fans via IPMI if you desire this functionality. All of these models offer built-in automatic fan controls which typically default to an optimal cooling profile, meaning they will be as quiet as they can be without allowing the server to overheat.

## iDRAC Versions Supportive of Manual Fan Control
While you can [upgrade or downgrade](dell-idrac-swaps.md) within an iDRAC release, there are [limits](dell-idrac-limits.md). In general, server generations are confined to a single iDRAC major version's firmware builds, and in some cases a version range within the major version.

- Gen 10
	- iDRAC 6 introduced
	- Very few models support manual fan control
	- Permanently hard-coded to iDRAC 6 firmware
- Gen 11
	- iDRAC 6 (firmware up to version 2.85) is the upper limit
	- Permanently hard-coded to iDRAC 6 firmware
- Gen 12
	- iDRAC 7 only (iDRAC 8 and 9 not supported)
	- Strong support for IPMI fan control
- Gen 13
	- Most models support iDRAC 8 only (iDRAC 9 not supported)
	- Slim chance very late production models could support iDRAC 9, but not officially
	- Solid support for IPMI fan control
- Gen 14
	- Compatible with iDRAC 9, but upper limit of most models is below version 7.x
	- Highly supportive of downgrading
	- Best all-around generation for IPMI fan control
	- Limited upgrade potential (also typically redundant)
- Gen 15
	- iDRAC 9 versions up to 7.10.x
	- Downgrading typically feasible, but care must be exercised
	- Downgrading below minor version 4.00.00.00 may lead to instability (medium risk)
- Gen 16
	- Compatible with latest iDRAC 9 versions from 7.10.x onward
	- Downgrading below iDRAC 9 5.00.00.00 unstable and discouraged (high risk)
- Gen 17
	- Ships with late iDRAC 9 or early iDRAC 10 release
	- Impossible to downgrade for IPMI fan control (you WILL brick the server if forced)

## Gens 10 & 11
Server generations 10 and 11 should generally be avoided. They may work, but most likely won't; at least not without compromises. Fan control through IPMI is typically blocked by automated iDRAC algorithms and/or the BIOS. Disabling iDRAC may allow direct control via the [Baseboard Management Controller](/documentation/lexicon.md#bmc) (BMC), but doing so will disables other features.

## Gens 12 & 13
PowerEdge server generations 12 and 13 are also strong candidates for a home lab server. They utilize iDRAC 7 and 8 respectively. All gen 12 servers should support IPMI fan control out-of-the-box. 

Gen 13 servers are a bit trickier. Most will be fine out-of-the-box, however some of the very late model series in this generation could possibly have been updated with an early version of iDRAC 9 if you are acquiring a used gen 13 server, so be careful. In that case, you may need to downgrade it to iDRAC 8 or upgrade it to a higher version of iDRAC 9 supportive of manual fan control. However, the latter approach is unlikely to be successful without potentially undesirable side effects, if you're able to do it at all. I'd recommend downgrading to a high version of iDRAC 8 if you find yourself in this position. It's not worth the risk of [bricking your iDRAC controller.](https://www.reddit.com/r/homelab/comments/rf5cck/bricked_idrac_but_thankfully_i_got_fan_control/)

### Late Gen 13 Server Pitfalls
Attempting to upgrade it *might* work, but only on the newest gen 13's, some of which are probably robust enough to support iDRAC 9. 

In short, if you're considering a gen 12 server, you should be good-to-go. However, if you're contemplating a gen 13 server, be sure to cross-check the [list of Dell servers with fan control by server model](dell-fan-control-by-server-model.md) beforehand. If you're planning to proceed with a late model gen 13 server, your best bet is to focus on a late version of iDRAC 8. Attempting to force an [appropriate version of iDRAC 9](dell-idrac-fan-control.md#idrac-9-a-fan-control-odyssey) to work on it will be hit-or-miss, at the risk of bricking the controller hardware, and sluggish performance during boot and potentially other times. Frankly, it's not worth the risk IMHO.

## Gens 14: The Sweet Spot
The 14th generation of PowerEdge servers are the sweet spot for home lab users. They are the most modern of the PowerEdge server line which should readily support complete manual fan control via IPMI out-of-the-box or with minimal effort. These servers all come with iDRAC 9. You will need to confirm it has an [iDRAC version supportive of manual fan control](dell-idrac-fan-control.md#idrac-9-a-fan-control-odyssey), and if not that you can change it so that it does.

Gen 14 has what I refer to as the [Goldilocks server models](dell-idrac-fan-control.md#3-goldilocks-idrac-9-v3000000---v3323232).

> [!TIP]
> Before acquiring a particular server, consult the [Dell servers with fan control by server model](dell-fan-control-by-server-model.md) list to be certain it will work.

## Gen 15: Maybe
It may be possible to downgrade iDRAC 9 successfully on a handful of gen 15 models, but for most gen 15 servers it won't work. Cross-check the [list of Dell servers with fan control by server model](dell-fan-control-by-server-model.md) before proceeding.

## Gens 16+: No
No. Don't even think about it. Avoid.

Gen 16 server hardware requires iDRAC 9, but [not the iDRAC 9 you're looking for](dell-idrac-fan-control.md#dell-killed-the-fan-controller). These servers come with iDRAC 9, version 7.x. Downgrading them to a 3.x version that supports manual fan control is very risky. Why? The hardware in these servers was developed quite some time after iDRAC 9 3.32.32.32 - the last iDRAC 9 version to support manual control. You're looking at downgrading iDRAC on these servers *multiple* levels below their factory installed version of iDRAC 9. You're looking at potentially (and likely in many cases) breaking critical hardware compatibilities. Just don't do it.

> [!NOTE]
> There is a possibility you can downgrade iDRAC 9 to a working version on an XR11 model, but attempting to do so is risky and unlikely to succeed. Other gen 16 and all gen 17 models are a definitive NO.

## Deploying Power Hungry PCIe Cards
A number of Dell servers come with built-in auxiliary fans specifically assigned to cooling the PCIe slots. These fans are controlled in a special way (described [here](dell-idrac-graphics-card-max-fan.md)). They cannot be controlled in the same manner as other fans. They can only be enabled or disabled. If you are planning to purchase a Dell PowerEdge system and also plan to install any PCIe cards known to produce significant quantities of heat, it's worth considering focusing on purchasing a server with one of these 3rd-party PCIe fans. Some server models known to come with this fan are the PowerEdge R710, R720, and T150. Of these, I recommend sticking with the R720 for rackmount solutions.
