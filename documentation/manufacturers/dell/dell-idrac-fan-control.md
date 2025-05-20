# Dell Server Fan Control
Server case fan speeds can be managed in one or more ways. Which methods are available depends on how access to the motherboard's fan control is exposed from a control perspective, but you can be certain one of them will be enabled by default on every server.
1. Monitored and manually adjusted by the BIOS, based on thermal sensor input. The BIOS has its own built-in rules for this task. It may or may not be possible for a user to modify related settings in the BIOS.
2. Fixed speed levels that may be manually selected in the BIOS or by sending related commands to the BIOS through other means (e.g. IPMI commands, iDRAC web interface). These fixed fan speed settings are normally very limited (perhaps 4 choices at the most) and tend to favor "full speed" or in some cases, "optimal speed" unless a user changes the setting. Regardless, the options are limited and one must choose from pre-selected levels that cannot be modified.
3. Automatic fan speeds controlled not by the BIOS, but through some sort of middleware. iDRAC is an example of firmware capable of doing this.

## Manual Fan Speed Control via IPMI Commands
The "holy grail" for home lab users in terms of managing fan speed and ambient noise is the ability to control server cooling fan behavior through software. One of the most common methods is to utilize [Intelligent Platform Management Interface](/documentation/lexicon.md#ipmi) (IPMI) - an industry standard computer sub-system that provides management and monitoring capabilities independently of a server's operating system.

If you're accustomed to using IPMI for manual fan control with other server brands, Dell's way of doing things may seem odd at first. For example, you cannot message the [Baseboard Management Controller](/documentation/lexicon.md#bmc) (BMC) directly. Commands addressed to the BMC must be routed through Dell's proprietary iDRAC controller. 

Four factors determine whether or not manual fan control via IPMI is possible on a Dell PowerEdge server:
1. Server generation
2. Dell's proprietary hardware controller (iDRAC)
3. Understanding how manual fan control works on Dell servers
4. Accepting risk factors

## What is iDRAC?
*iDRAC* stands for ***integrated Dell Remote Access Controller***.

Thinking about how Dell PowerEdge (PE) servers are constructed, iDRAC acts as a gatekeeper to other portions of the system. This is why it's necessary to explicitly allow IPMI access. By default, iDRAC blocks IPMI messages from getting past the iDRAC controller, and this is also why it's first necessary to utilize the HTTPS iDRAC interface in order to start using IPMI in any capacity.

iDRAC is a hardware/software (controller/firmware) platform that serves multiple roles in server management. One of its more important roles is as a remote system access gatekeeper. The controller sits physically between a dedicated and/or shared network interface and other hardware components, such as the Baseboard Management Controller (BMC).

As a hardware device, iDRAC contains proprietary software - commonly referred to as firmware - that regulates its behavior. This firmware has four primary responsibilities:
1. Gate remote access to the server hardware
2. Facilitate remote monitoring and task requests
3. Monitor hardware devices
4. Execute pre-defined automation instructions based on hardware behavior

## iDRAC vs. BMC
The Baseboard Management Controller (BMC) chip is what actually communicates with the on-board fan controller - the physical device on a motherboard that controls all fans by modulating their applied voltage. Raw IPMI commands are routed through the iDRAC and to the BMC for execution. 

Dell has never supported or condoned manual fan speed control via IPMI.

Dell's formal position on fan controls has always been that CPU and chassis cooling fans should be managed by an independent monitoring process in the BIOS, and/or preferably as an independent control hardware device. This is one of many factors that led to Dell's creation of iDRAC controllers and the DRAC controllers that preceded them. Dell has at times Dell provided system administrators with granular or stepped fan controls via the iDRAC web (HTTPS) interface, but the related functions which can be manipulated by an end user are limited, and their scope varies widely by server generation and iDRAC version. Most PowerEdge servers hide these functions from end users and use algorithms behind the scene that follow pre-ordained behavior patterns which cannot be changed.

> [!TIP]
> In spite of these limitations, manual fan control via IPMI is available on most Dell PowerEdge servers manufactured between 2008 and 2019. 

## iDRAC History
Released in 2008 with the 11th generation of PowerEdge servers, Dell's [iDRAC](/documentation/lexicon.md#idrac) versioning began with version 6 (iDRAC 6). This is because the "i" in "iDRAC" stands for "***i***ntegrated." Prior to iDRAC 6 there was DRAC 5, which came with Gen 10 servers (2006 - 2008).

## Server Generations and iDRAC Major Versions
Introduced in 2008 with Gen 10 PowerEdge servers, iDRAC 6 was the first iDRAC controller, replacing [DRAC](/documentation/lexicon.md#drac) (the previous controller architecture).

Like DRAC, the iDRAC platform consists of a paired relationship between hardware controller and firmware. The two are bonded together, meaning the release version of iDRAC (e.g. iDRAC 8) needs to correlate with its corresponding hardware controller. These are in turn correlated with the capabilities of the hardware installed on any given server. This includes hardware devices built-in to the server motherboard (e.g. RAM memory speed support) and add-on devices such as those interfacing with PCI-e and NVMe data buses.

iDRAC major release version iterations align with major shifts in hardware technology available on Dell PowerEdge servers at the time of each release.

Dell's original strategy (beginning with iDRAC 6) was to evolve iDRAC in lock-step with the PowerEdge server generations. However, the company pivoted its strategy beginning with server gen 15. This explains why earlier releases of iDRAC (e.g. iDRAC 6) have a 1:1 iDRAC-to-server gen relationship, while later releases (e.g. iDRAC 9) have been spread out in 1-to-many generations relationship. The pace of significant hardware changes was more pronounced from gen 11-14 servers, but became much less pronounced with the release of gen 15. Debuting in 2020, iDRAC 9 currently spans server generations 14, 15, 16, and 17. The current major versions are iDRAC 9 and iDRAC 10; the latter being released in late 2024 on only a few server models.

| Type     | Year | Server             | Comments                                                                                      |
| -------- | ---- | ------------------ | --------------------------------------------------------------------------------------------- |
| iDRAC 10 | 2024 | Gen 17             | Latest iDRAC version. Targeted toward data center server models only. First release Dec 2024. |
| iDRAC 9  | 2017 | Gen 14, 15, 16, 17 | New User Interface. Support for modern hardware.                                              |
| iDRAC 8  | 2014 | Gen 13             | UEFI secure boot, HTML5 virtual console.                                                      |
| iDRAC 7  | 2012 | Gen 12             | Hardware based, NTP support, Redfish management.                                              |
| iDRAC 6  | 2008 | Gen 11             | Basic remote management. Cannot upgrade to later iDRAC major versions.                        |
| DRAC 5   | 2006 | Gen 10             | Last gen of DRAC                                                                              |

## iDRAC 9: A Fan Control Odyssey
iDRAC 9 is an odyssey in server fan controls.

Since its inception in 2017, iDRAC 9 has taken end users on an episodic journey of fan controls alternating between blocking and permitting IPMI fan control. No other version of iDRAC has been so contentious and alternately ignored, blocked, and supported IPMI fan control across the lifespan of the same iDRAC version, to the chagrin of many sysadmins.

### The Four Chapters of iDRAC 9 IPMI Fan Support (2017 - 2025)
The historical demarcation between 'can' and 'cannot' manually control fans versions of iDRAC 9 breaks down into four (4) distinct phases like this:
1. **2.10.10.10 and earlier**: Not supported
	- No IPMI fan control. These older versions of iDRAC 9 allow fan control ONLY via iDRAC thermal profiles or the BIOS.
2. **2.30.30.30 - 2.86.86.86**: Mostly supported
	 - Supports full IPMI manual fan control, but risks the possibility of race condition scenarios with iDRAC's built-in thermal fan control algorithms, which cannot be defeated.
	 - On the positive side of things, Dell introduced adjustable fan speed offsets for the thermal profiles, though they can only be modified via HTTPS iDRAC interface.
3. **3.00.00.00 - 3.32.32.32**: Fully supported
	 - Fully supports IPMI manual fan control.
	 - iDRAC switch prevents most interference from iDRAC or BIOS.
	 - If you want or need to use iDRAC 9, this version range is preferred.
1. **3.34.34.34 and later**: Not supported
	 - Completely locked out.

### 1. iDRAC 9 Pre-v2.30.30.30
iDRAC 9 versions *prior to* 2.30.30.30 are to be **avoided** as IPMI fan control is blocked.

Dell chose the initial launch of iDRAC 9 as an opportunity to re-visit out-of-band flexibility in the server environment, including fan control. Communications from out-of-band tools such as IPMI were more strictly limited than they had been in iDRAC 8, and this included blocking IPMI raw commands addressed to the BMC's fan controller. The end result is IPMI commands attempting to control fans are dropped and not passed through to the BMC.

### 2. iDRAC 9 v2.30.30.30 - v2.86.86.86
Dell received substantial pushback from frustrated sysadmins after the launch of iDRAC 9, and subsequently decided to scale back iDRAC 9's aggressive filtering of out-of-band commands (such as IPMI). This included rolling back the blocker on raw IPMI fan control commands present in pre-2.30.30.30 versions of iDRAC 9.

Unfortunately, unblocking IPMI fan speed controls highlighted a problem that - while it also existed in previous iDRAC releases (6, 7, and 8) - was not as pronounced. Compared with iDRAC 8, iDRAC 9's built-in fan management [thermal profiles](dell-idrac-fan-control.md#thermal-profiles) are more aggressive, resulting in a higher probability of experiencing [unmetered race conditions](dell-idrac-fan-control.md#what-is-a-race-condition) between the BIOS, iDRAC controller, and IPMI fan control instructions.

The automated iDRAC fan management features present in the iDRAC firmware cannot be disabled, and the BIOS and iDRAC controller have no comprehension of IPMI's competing demands or incumbent requests to the BMC. When conflicts occur, they appear to end users as erratic fan behavior and make the system appear to be unreliable. However frustrating this may be, in reality each system is performing as expected.

### 3. Goldilocks: iDRAC 9 v3.00.00.00 - v3.32.32.32
iDRAC 9 is the only major version of iDRAC that has ever expressly permitted (though not officially supported) manual fan control outside of the iDRAC HTTPS interface, and only for a limited range of iDRAC 9 versions: 3.00.00.00 through 3.32.32.32. This range of iDRAC 9 versions is ideal for IPMI fan control. It is the sweet spot.

Released between June 2017 (v3.00.00.00) and May 2019 (v3.32.32.32), these iDRAC 9 versions are the "goldilocks" phase of iDRAC software most coveted by home lab users. Servers with iDRAC 9 versions within this range will be the most trouble-free and reliable of the entire range of iDRAC builds that allow manual fan control via IPMI.

Though Dell has never expressed official support for IPMI manual fan control in any iDRAC release, it is clear that was the intent with this range of iDRAC 9 versions, due to its purposeful design tailored specifically to IPMI fan control commands. In this range of iDRAC 9 versions, Dell brought back the option for manual fan control via IPMI, but gated it behind an unadvertised, explicit override command. Attempting to apply IPMI fan control commands users were accustomed to in iDRAC 8 will fail unless the override command is sent first.

This range of iDRAC 9 versions is denoted from all others for the following key reasons:
1. Clear support for manual fan control via IPMI raw commands
2. IPMI fan controls must be "unlocked"
3. Resolves most [race condition](dell-idrac-fan-control.md#what-is-a-race-condition) conflicts with iDRAC

At first glance, it may seem as if Dell was trying to conceal the renewed IPMI fan control capabilities they added back into iDRAC 9 3.30.30.30, however that's not the full story. It's more of a compromise on several levels.
1. Though Dell never officially supported it, they reinstated IPMI fan control, placating the many complaints they received after previously removing this feature. 
2. Gating IPMI manual fan control capabilities behind a software switch indirectly enabled other improvements.
	1. Supported Dell's desire to wean users off IPMI fan control by adding another step in the process. For example, this broke scripts that sysadmins had used for years.
	2. Made it possible for iDRAC to have awareness of an end user's intent to control fans manually via IPMI.
	3. Solved a related problem with fan control race conditions when communicating with the BMC about the fan controller.

In particular, when the iDRAC controller is explicitly informed the end user wishes to take over fan controls, the iDRAC firmware disables most of its fan control/thermal sensor algorithms, eliminating most [race conditions](dell-idrac-fan-control.md#what-is-a-race-condition) where iDRAC is the causal factor.

### 4. iDRAC 9 v3.34.34.34+
Avoid these versions of iDRAC, as they make manual fan control impossible.

After reinvigorating IPMI fan controls - and with no advance warning - Dell abruptly sabotaged this feature in the iDRAC 9 3.34.34.34 update (June 2019). The iDRAC 9 3.34.34.34 release removed the software gate first added to iDRAC 9 3.30.30.30, along with any remnants of manual fan controls from the web iDRAC interface. Due to the changes in IPMI fan controller management introduced in iDRAC 9 3.30.30.30, the effect **permanently blocked** users' ability to manually control case fans.

The change was not advertised ahead of time and caught many system administrators off-guard, breaking their previously existing software-based fan controllers. Adding insult to injury, six months later in December 2019 Dell released iDRAC 9 version v4.00.00.00 which **permanently blocked users from downgrading iDRAC 9** to a pre-3.34.34.34 release version. This time, at least there was a brief footnote in the release notes, though relatively speaking it hardly mattered.

These decisions were borne out of Dell's desire to further tighten iDRAC's control over the system environment - primarily for security reasons - that Dell had desired to initiate back in 2017 when iDRAC 9 was first released. As you can see in the history notes above, Dell ultimately stayed the execution of manual fan controls due to the strong pushback it initially received, however this was temporary. After making it more difficult for sysadmins to implement manual fan control for a couple of years, they finally pulled the rug.

It was revealed some time later that the downgrade blocker introduced in iDRAC 9 4.00.00.00 was done on purpose explicitly to block users from unlocking manual fan control capabilities via IPMI. This is also why on more recent server generations (gen 16+) and in iDRAC 10, manual fan control via IPMI is impossible. Unfortunately, if you have a gen 16 or later server, you are out-of-luck and must live with automated cooling fan controls, though you may have some sway over how the fans perform via iDRAC's [fan thermal profiles](dell-idrac-fan-control.md#thermal-profiles).

## Why Fan Control Solutions are iDRAC Dependent
Dell server fan control options are directly dependent on two iDRAC related factors:
	1. Which *generation* is your server?
	2. Which version of iDRAC firmware is currently installed?

Aside from the major iDRAC release number, iDRAC also has minor version numbers. It's the combination of major and minor versioning that determines which fan control options are available.

> [!TIP]
> Looking for specific suggestions on choosing a Dell server for Home Lab use? Check-out [choosing the best Dell PowerEdge server](dell-choosing-best-poweredge-server.md) and the [Dell Server Buyer's Guide](dell-server-buyers-guide.md)
> 

## Determining iDRAC Version
There are two methods of determining a server's iDRAC version:
1. Login to its web-based (HTTPS) interface and have a look.
2. Using a command-line based protocol such as IPMI to query the server's hardware information.

The default iDRAC IP address is 192.168.0.120. Upon logging into its HTTPS interface with a web browser, the version is displayed at the upper left of the iDRAC along with the iDRAC license level.

> [!WARNING]
> Caveat: You **must** enable IPMI access via the iDRAC web interface BEFORE you will be able to query the server via IPMI. See the section below for details on how to do this.

Once it's allowed access, utilizing IPMI, the controller can be queried directly like this:

```
ipmitool -I lanplus -H <iDRAC_IP> -U <username> -P <password> mc info
```


> [!NOTE]
> Fan duty level for each profile are normally fixed. On some models with later versions of iDRAC 7, and virtually all iDRAC 8 implementations, options may exist that allow users to influence the fan duty starting levels of certain fan profiles. When available, these settings must be discovered in the BIOS and/or iDRAC web (HTTPS) interface, as they cannot be manipulated via IPMI. Monitored temperature sensors and profile trigger levels are beyond user control.

## Feasibility of IPMI Fan Control by iDRAC Version
Dell PowerEdge server generations are easily identified in server model numbers by their 2nd digit. For example, an R710 server belongs to the 11th generation, while the R720 belongs to gen 12.

Your best chance of getting a Dell server supporting manual fan controls via IPMI is to focus on PowerEdge generations 12, 13, and 14. Let's dive into what iDRAC is, how and why it governs which servers are realistic options, and how to implement manual fan control on the servers that will allow it.

| **Server Generation**           | **iDRAC Version**   | **IPMI Fan Control Feasibility** |   Recommended?    | **Details**                                                                                                                                                                |
| ------------------------------- | ------------------- | :------------------------------: | :---------------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 10th Gen, 11th Gen (e.g., R710) | iDRAC 6             |     **Limited / Unreliable**     | Maybe<sup>1</sup> | Fan control through IPMI typically blocked by iDRAC automation. Disabling iDRAC may allow direct control via the BMC, but this disables other features.                    |
| 12                              | iDRAC 7             |        **Yes**<br>(Most)         | Most<sup>1</sup>  | Allows setting fan speeds independently. Reliable on most 12th Gen servers.                                                                                                |
| 13                              | iDRAC 8             |        **Yes**<br>(Most)         |  Yes<sup>1</sup>  | Similar to iDRAC 7, raw IPMI fan commands often work. Behavior may vary depending on firmware. Generally reliable for manual control.                                      |
| 14                              | iDRAC 9             |             **Yes**              |  Yes<sup>2</sup>  | Supported by older firmware only.                                                                                                                                          |
| 15, 16                          | iDRAC 9             |      **Maybe** (Restricted)      |  No<sup>2</sup>   | Supported by older firmware only. IPMI raw fan commands blocked by default on most firmware versions. Limited reliability (depends on ability to downgrade iDRAC version). |
| 17                              | iDRAC 9 or iDRAC 10 |              **No**              |        No         | IPMI raw fan commands blocked by default                                                                                                                                   |

<sup>1</sup> Most gen 10 servers will not work. Some gen 11 servers will work, but most will not. Which work or do not is completely dependent on iDRAC 6 version.</br>
<sup>2</sup> Most gen-14 servers will work. Very few gen 15/16 servers may work, but most will not. A thorough understanding of the process to get these server gens to work should be understood before attempting to do so.

To get the complete picture on compatibility, refer to [Choosing the Best PowerEdge Server](dell-choosing-best-poweredge-server.md) and the [Dell Server Buyers Guide for Home Labs](dell-server-buyers-guide.md).

### Thermal Profiles
By default, iDRAC automatically controls the CPU and case fans in PowerEdge servers to prioritize system stability and hardware longevity. To accomplish this, it relies on automatic, thermal based algorithms. The goal is to prevent the server's hardware components from overheating. These algorithms leverage a simplistic model of fan control by triggering different modes, and often result in unnecessarily, constant high fan speeds.

Dell's approach is somewhat similar to Supermicro's, though there are some key differences:
- Detection of any 3rd-party hardware negates current mode and forces Max Cooling
- "Default" mode (Dell)
	- "Optimal" mode is the closest Supermicro approximation
	- Both scale up and down based on ambient chassis temperature sensors
		- Supermicro will not drop fan speeds below a minimum level (typically 30%)
		- Dell drop fan speed lower than Supermicro (depending on thermal sensor readings)

#### Comparison of Dell vs. Supermicro Fan Profiles

| **Purpose**               | **Dell iDRAC Profiles**              | **Supermicro Fan Profiles** |
| ------------------------- | ------------------------------------ | --------------------------- |
| **Default Mode**          | Default                              | Optimal                     |
| **Power-Saving Mode**     | Power Efficiency / Energy Efficiency | Optimal                     |
| **Performance**           | Performance                          | Standard                    |
| **High-Performance Mode** | Performance / High Performance       | Heavy I/O                   |
| **Maximum Cooling**       | Maximum Performance                  | Full Speed                  |

### IPMI Fan Control and Monitoring
An equally critical component of controlling server fans via IPMI pertains to the ability to monitor the fans. After all, you can't truly control something which cannot be monitored, as a proper cooling feedback loop cannot be created. 

As shown in the table below, not all solutions that allow manual fan control also allow all types of monitoring or fan failsafe configuration, and some that don't allow manual fan control do allow monitoring or configuring fan failsafe settings. The "IPMI Fan Thresholds" column indicates whether or not the server gen and iDRAC combination allow setting upper and lower fan speed thresholds through IPMI. These thresholds are pre-determined and will cause the BMC to override the current fan duty level. When the BMC perceives one or more reported fan speeds are outside the lower or upper threshold of what is expected for normal fan operation, those fans. This is failsafe behavior and cannot be undermined, other than moving the goalposts by setting these thresholds to abnormally high or low levels. Thus, this column in the table below indicates whether or not iDRAC allows modifying these values via IPMI for the given combination of server gen and iDRAC version.

| PE Server Gen | iDRAC Version |  IPMI Fan Control   | IPMI Sensor | IPMI SEL | IPMI Fan Thresholds |
| ------------- | ------------- | :-----------------: | :---------: | :------: | :-----------------: |
| 17            | iDRAC 10      |       **No**        |      ?      |    ?     |          ?          |
| 15, 16, 17    | iDRAC 9       | **No**<sup>1</sup>  |     Yes     |   Yes    |         Yes         |
| 14            | iDRAC 9       | **Yes**<sup>2</sup> |     Yes     |   Yes    |         Yes         |
| 12, 13        | iDRAC 9       | **Yes**<sup>2</sup> |     Yes     |   Yes    |         Yes         |
| 12, 13        | iDRAC 8       | **Yes**<sup>3</sup> |     Yes     |   Yes    |         Yes         |
| 12            | iDRAC 7       |      **Maybe**      |     Yes     |   Yes    |         No          |
| 10, 11        | iDRAC 6       |      **Maybe**      |     Yes     |   Yes    |         No          |

<sup>1</sup> Theoretically possible if user manually downgrade to iDRAC 9 3.32.32.32 or earlier, though stability could be a concern.<br>
<sup>2</sup> See [Dell iDRAC Limits](dell-idrac-limits.md)<br>
<sup>3</sup> Fully supported, subject to the possibility of [race conditions](dell-idrac-fan-control.md#what-is-a-race-condition), and a known and potentially significant [iDRAC 8 defect](dell-idrac-fan-control.md#idrac-8-ipmi-credentials-bug).<br>

## Server Generations Supportive of Manual Fan Control
Certain generations of Dell PowerEdge servers offer the best opportunity for successful manual control of fan speeds via IPMI:
1. **12th Gen (iDRAC 7/8/9)**: Hassle-free solution for most models.
2. **13th Gen (iDRAC 8/9)**: Most models work well with IPMI commands, though Dell began introducing stricter firmware behavior, such as [add-on graphics cards forcing Max Cooling](dell-idrac-graphics-card-max-fan.md) mode.
3. **14th Gen (iDRAC 9)**: Completely dependent on minor/sub version. Dell began phasing out allowing manual fan control via IPMI by purposefully blocking the technique. Yet, for a select sub-set of iDRAC 9 versions, manual fan control is enhanced through their mitigation of known [race conditions](dell-idrac-fan-control.md#what-is-a-race-condition).

Having clarified which Dell PowerEdge server generations can or may support manual fan control via IPMI, it's worth discussing caveats before continuing with details on how to implement it.

## Risks
Once you've confirmed that you *can* control your server's fans manually via IPMI, before making a final determination that you will do so, I recommend reviewing your server's built-in [thermal fan management behavior](dell-idrac-fan-control.md#thermal-profiles). If you find it insufficient to meet your needs and/or you'd just prefer controlling them manually via IPMI for any reason, the next step is to review any potential ramifications of manual fan control. This section outlines known risks by iDRAC version. These risks are not particularly problematic for most users, but being aware of them will assist you with any troubleshooting, should you find that necessary in the future.
### 1. IPMI Fan Control is Not Persistent
IPMI commands to control fan speed - when they work - are temporary. The BIOS and iDRAC controller have no comprehension of IPMI's competing demands or incumbent requests to the BMC, and IPMI's requests are forgotten when the server is restarted. Naturally, this means IPMI commands need to be executed after each server restart event in order for IPMI to maintain fan control. However, there is another more insidious potential conflict that can occur, and that is a race condition issue. When this occurs, it manifests itself through perceived fan control instability.

### 2. Race Conditions and Fan Control Reliability
Before diving into the nuances of each iDRAC major version and how to handle manual fan controls via IPMI, it's worth mentioning that doing so creates a **race condition risk**.

All versions of iDRAC 6, 7, 8, and 9 - *with the exception of iDRAC 9 versions 3.00.00.00 through 3.32.32.32* - are vulnerable to unmetered race conditions between the BIOS, iDRAC controller, and IPMI. iDRAC 10 is not impacted because it aggressively screens out any attempt to control the fans via IPMI raw commands in the first place. If your server has iDRAC 10 you are SoL (though you could consider [downgrading your iDRAC version](dell-idrac-swaps.md#idrac-version-downgrades)).

#### What is a "Race Condition?"
First off, let's define what a "race condition" is exactly, as the term may be unfamiliar to some. A *race condition* is when two or more things are attempting to influence an outcome, at the same time. In the context of computers and information, this term often refers to information being provided to a receiving process, which will take some action when it receives the information. The term sometimes refers to a race in a sense, where whichever piece of information arrives at the receiver first "wins." However, it's more often used to refer to a situation where the competing processes are continuously sending information to the same receiving process, and the receiver adjusts its behavior or reaction every time it receives a new piece of information from the senders. The latter scenario is what is being described here with the fan controller.

The BMC can receive fan instructions from a variety of sources (BIOS, iDRAC, IPMI, and perhaps others). When it receives a fan instruction, it processes it immediately. The BMC acts in real-time and has no concept of "remembering" prior requests. It does not understand fan states, previous command requests, etc. It's just an operational piece that performs its job in the moment, and it's done. The BIOS and iDRAC on the other hand, may send continuous or periodic fan control messages to the BMC, which will dutifully perform them when asked.

#### Common Conflicts
The most common conflict is related to hardware thermal sensors. These can cause the iDRAC's algorithms to issue pre-defined commands to the fan controller (via the BMC). There is no way to disable the thermal-based iDRAC fan management portion of its firmware, which is what makes this the most common root cause of the race condition issue. Even with specified iDRAC 9 versions (see below), there will always be scenarios where your IPMI issued fan speed commands can and will be overridden. This is by design, to protect you from bricking your server due to preventable overheating circumstances.

Meanwhile, the BIOS and iDRAC controller have no comprehension of IPMI's competing demands or incumbent requests to the BMC. This is true even with regards to [the Goldilocks version range of iDRAC 9](dell-idrac-fan-control.md#3-goldilocks-idrac-9-v3000000---v3323232), as even though this subset of iDRAC 9 includes an on/off switch for IPMI fan control, iDRAC still has no awareness of what IPMI is doing with the fans.

iDRAC firmware will still commands to the BMC's fan controller when its hardware temperature sensors detect behavior matching one of its built-in thermal profiles, even when IPMI is ostensibly running the show. There is no way to disable the iDRAC fan management code in the iDRAC firmware, for any iDRAC version.

### 3. Finicky iDRAC Firmware
iDRAC firmware generally cannot - or at least should not - be modified on a server in terms of which generation or release train of iDRAC is incumbent on a given server model. Therefore, it's wise to have at least a basic understanding of the nuances of each iDRAC generation. This is particularly true of limitations around manual fan control and thermal fan profiles that are built into the iDRAC and/or BIOS of every one of these servers.

#### iDRAC 6 (Gen 10, 11 Servers)
iDRAC 6 has less sophisticated thermal algorithms compared to iDRAC 7, 8, and 9. The BIOS and iDRAC have fewer interactions with the BMC, and the fan control algorithms are not as aggressive. This tends to make race conditions that do occur more volatile and unpredictable in their behavior, when compared with how iDRAC 7, 8, and 9 servers may react under such circumstances. However, the resulting behavior of the server will be similar.

#### iDRAC 7, 8 (Gen 12, 13, 14)
iDRAC 7 and 8 have more sophisticated thermal algorithms than iDRAC 6. While this fact does not allow complete mitigation of the risk of race conditions with regards to fan control, it does soften the risk profile a bit. Particularly with later iDRAC 8 versions, it is easier to exercise control over the levers in the iDRAC thermal algorithms which tend to lead to the race condition problem in the first place. It's worth spending some time on these machines browsing the controls available in the HTTPS iDRAC interface, and making whatever adjustments you can in the web user interface to try and prevent iDRAC from interfering with your manual fan control plans. This means focusing on intelligent design of your manual fan control strategy, and tweaking iDRAC settings to try and keep each from interfering with the other's range. For example, if you incorporate thermal sensor monitoring into your manual fan control executions, make sure you've previously adjusted the iDRAC controller's temperature monitoring ranges so they are outside your IPMI manual fan controller's thresholds.

#### iDRAC 9 (Some Gen 13, 14, 15, 16)
This race condition problem is the reason why the iDRAC 9 versions that are [most supportive of IPMI manual fan control](dell-idrac-fan-control.md#3-goldilocks-idrac-9-v3000000---v3323232) introduced - and in fact require - the use of specific IPMI commands to first activate or de-activate the allowance of IPMI fan control before the BMC accepts IPMI raw fan commands.

This process makes supportive iDRAC versions acutely aware of when IPMI is requesting fan control ownership. This in turn results in more reliable and consistent fan behavior when IPMI fan control is in use, because the iDRAC controller is not fighting for control of the fans except under extreme server duress, in which case you'd want the related automated processes in iDRAC to take over anyway.

#### iDRAC 10 (Gen 17+)
Released in late 2023 and a reasonable step-up in capabilities from iDRAC 9, Dell's 17th PowerEdge server generation come from the factory with iDRAC 10. Requiring the ability to monitor and manage much more powerful hardware, iDRAC 10 is not backward-compatible with iDRAC 9. This means it is not possible to "downgrade" a server that comes with iDRAC 10 to iDRAC 9 firmware. The latter simply can't handle the significant jump in hardware capabilities from gen 16, which truly stretched iDRAC 9 as far as it could.

### 4. Third-Party Hardware
This attribute is further influenced by the presence of third-party components (e.g., NVMe drives, GPUs, or PCIe cards), and especially unrecognized hardware. When iDRAC detects a non-Dell or unknown manufacturer hardware component in the server chassis, by default maximizes fan speeds by forcing the "Maximum Cooling" thermal profile.

Defeating this behavior is slightly complex. First, it requires that IPMI fan control is possible. And second, there is an additional step on some servers - beyond manual fan control processes via IPMI - when a 3rd party graphics card is involved. The work-around for this edge case scenario is explained [here](dell-idrac-graphics-card-max-fan.md).

## Enabling IPMI Access
All iDRAC controller firmware versions support IPMI 2.0. However, it must be enabled explicitly via the iDRAC web (HTTPS) interface. This is a security feature set from the factory on all PowerEdge servers. Enabling IPMI communication is a simple process, but it varies slightly by iDRAC release.

### iDRAC 6 and iDRAC 7
On iDRAC 6 or iDRAC 7, access the iDRAC web interface via a web browser and navigate to IPMI settings. Enable **IPMI over LAN**.

```
Settings > Network/Security > IPMI Settings
```

Logout of the web interface and execute the IPMI command detailed above, to confirm IPMI access works as expected. If not, restart the server and try again and it should work. If it still doesn't work, login with the HTTPS interface again and examine whether or not the change you made to the settings was saved or not.

### iDRAC 6 Summary Table of IPMI Fan Control Versions

| iDRAC 6 Version | Release Date |  Fan Speed Profiles  | Manual Fan Control Possible? | Notes                                                |
| --------------- | :----------: | :------------------: | :--------------------------: | :--------------------------------------------------- |
| iDRAC 6 v1.00   |   Mar 2009   |                      |             Yes              | Coordinated with launch of PowerEdge gen 11 servers. |
| iDRAC 6 v1.10   |   Jun 2009   |                      |              ?               |                                                      |
| iDRAC 6 v1.30   |   Jun 2010   |                      |             Yes              |                                                      |
| iDRAC 6 v1.35   |   Aug 2010   |                      |              ?               |                                                      |
| iDRAC 6 v1.40   |   Oct 2010   | Low\|Med\|High\|Auto |             Yes              | manual fan control introduced                        |
| iDRAC 6 v1.41   |   Nov 2010   |                      |             Yes              |                                                      |
| iDRAC 6 v1.44   |   Feb 2011   |                      |              ?               |                                                      |
| iDRAC 6 v1.50   |   Mar 2011   | Low\|Med\|High\|Auto |           Limited            | profile selection possible via IPMI                  |
| iDRAC 6 v1.52   |   May 2011   |                      |              ?               |                                                      |
| iDRAC 6 v1.54   |   Jul 2011   |                      |              ?               |                                                      |
| iDRAC 6 v1.55   |   Sep 2011   |                      |              ?               |                                                      |
| iDRAC 6 v1.57   |   Nov 2011   |                      |              ?               |                                                      |
| iDRAC 6 v1.60   |   Jun 2013   | Low\|Med\|High\|Auto |           Limited            | profile selection possible via IPMI                  |
| iDRAC 6 v1.85   |   Feb 2012   |                      |             Yes              |                                                      |
| iDRAC 6 v1.90   |   Jun 2012   |                      |      Maybe<sup>1</sup>       |                                                      |
| iDRAC 6 v1.92   |   Sep 2012   |                      |              ?               |                                                      |
| iDRAC 6 v1.95   |   Mar 2013   |                      |              ?               |                                                      |
| iDRAC 6 v1.97   |   Mar 2014   |                      |              ?               |                                                      |
| iDRAC 6 v1.98   |   Jan 2015   |                      |              ?               |                                                      |
| iDRAC 6 v1.99   |   May 2015   |                      |              ?               |                                                      |

<sup>1</sup> May possibly work. May be impacted by server model.

### Modular iDRAC 6 Versions
iDRAC 6 is bifurcated. There is the standard server or normal iDRAC 6 firmware, which Dell refers to as the "Monolithic" version. And there is a separate release train called the "Modular" variant, also known as Modular iDRAC 6. Their difference is the Monolithic version is intended for typical rack and tower-mounted servers, while the Modular version is designed for modular (a.k.a. "blade") servers.

From the perspective of fan control, the distinction is important. Modular servers share power, cooling, and networking within a chassis. This makes manual fan control a tricky business, as there is first a question of "who" owns this responsibility (i.e. a blade server, or something else)? And, if there are potentially multiple systems with control over fans, how does one reconcile which server is controlling which fan, in addition to some level of coordination over fan cooling activity.

Generally speaking, fan control should not be attempted on servers running Modular iDRAC 6.

You can tell the difference simply by the iDRAC 6 version. The Monolithic (normal) versioning begins with version 1.00 and ends with version 1.99. While the Modular variant versioning scheme began at 2.00 and the last version is 2.92.

| Modular iDRAC 6 Versions | Release Date | Manual Fan Control Possible? | Notes                                            |
| ------------------------ | :----------: | :--------------------------: | :----------------------------------------------- |
| iDRAC 6 v2.00            |   Mar 2010   |              No              | Initial release                                  |
| iDRAC 6 v2.10            |   Jun 2010   |              No              |                                                  |
| iDRAC 6 v2.20            |   Sep 2010   |              No              |                                                  |
| iDRAC 6 v2.30            |   Dec 2010   |              No              |                                                  |
| iDRAC 6 v2.40            |   Mar 2011   |              No              |                                                  |
| iDRAC 6 v2.50            |   Jun 2011   |              No              |                                                  |
| iDRAC 6 v2.60            |   Sep 2011   |              No              |                                                  |
| iDRAC 6 v2.70            |   Dec 2011   |              No              |                                                  |
| iDRAC 6 v2.80            |   Mar 2012   |              No              |                                                  |
| iDRAC 6 v2.85            |   Feb 2016   |              No              |                                                  |
| iDRAC 6 v2.90            |   Jul 2012   |              No              |                                                  |
| iDRAC 6 v2.91            |   Sep 2012   |              No              | Urgent fix                                       |
| iDRAC 6 v2.92            |   Jan 2019   |              No              | Security fixes. Final release of modular iDRAC 6 |

### iDRAC 7 Summary Table of IPMI Fan Control Versions

| iDRAC Version    | Release Date |  Fan Speed Profiles  | Manual Fan Control Possible? | Notes                                                                 |
| ---------------- | :----------: | :------------------: | :--------------------------: | --------------------------------------------------------------------- |
| iDRAC 7 v1.0.0   |   Mar 2012   |                      |             Yes              | Initial release. Aligned with 12th-gen PowerEdge server introduction. |
| iDRAC 7 v1.10.10 |   Jun 2012   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.20.20 |   Sep 2012   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.23.23 |   Sep 2012   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.30.30 |   Dec 2012   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.31.30 |   Feb 2013   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.40.40 |   Mar 2013   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.50.50 |   Jun 2013   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.51.51 |   Aug 2013   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.55.55 |   Oct 2013   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.56.55 |   Dec 2013   |                      |             Yes              |                                                                       |
| iDRAC 7 v1.57.57 |   Feb 2014   |                      |             Yes              | Confirmed on late model R710 (gen 11)                                 |
| iDRAC 7 v1.60.60 |   Apr 2014   | Low\|Med\|High\|Auto |              No              | Disabled by Dell                                                      |
| iDRAC 7 v1.65.65 |   Jun 2014   | Low\|Med\|High\|Auto |              No              | Full fan speed control via http interface only                        |
| iDRAC 7 v1.66.65 |   Aug 2014   |                      |              No              |                                                                       |
| iDRAC 7 v1.70.70 |   Oct 2014   |                      |              No              |                                                                       |
| iDRAC 7 v1.80.80 |   Dec 2014   |                      |              No              |                                                                       |
| iDRAC 7 v1.85.85 |   Feb 2015   |                      |              No              |                                                                       |
| iDRAC 7 v1.90.90 |   Apr 2015   |                      |              No              |                                                                       |
| iDRAC 7 v1.95.95 |   Jun 2015   |                      |              No              |                                                                       |
| iDRAC 7 v2.00.00 |   Aug 2015   | Low\|Med\|High\|Auto |              No              | Full fan speed control via http interface only                        |
| iDRAC 7 v2.10.10 |   Oct 2015   |                      |              No              |                                                                       |
| iDRAC 7 v2.15.15 |   Dec 2015   |                      |              No              |                                                                       |
| iDRAC 7 v2.20.20 |   Feb 2016   |                      |              No              |                                                                       |
| iDRAC 7 v2.21.21 |   Apr 2016   |                      |              No              |                                                                       |
| iDRAC 7 v2.30.30 |   Jun 2016   | Low\|Med\|High\|Auto |              No              | Full fan speed control via http interface only                        |
| iDRAC 7 v2.40.40 |   Aug 2016   |                      |              No              |                                                                       |
| iDRAC 7 v2.41.40 |   Oct 2016   |                      |              No              |                                                                       |
| iDRAC 7 v2.50.50 |   Dec 2016   |                      |              No              |                                                                       |
| iDRAC 7 v2.52.52 |   Feb 2017   |                      |              No              |                                                                       |
| iDRAC 7 v2.60.60 |   Apr 2017   |                      |              No              |                                                                       |
| iDRAC 7 v2.61.60 |   Jun 2017   |                      |              No              |                                                                       |
| iDRAC 7 v2.62.60 |   Aug 2017   |                      |              No              |                                                                       |
| iDRAC 7 v2.63.60 |   Oct 2017   |                      |              No              |                                                                       |
| iDRAC 7 v2.65.65 |   Dec 2017   |                      |              No              | Final iDRAC 7 release                                                 |

### iDRAC 8
On iDRAC 8 servers, the process is the same as iDRAC 6 and 7, but there is a slight twist. Specifically, on some versions of the iDRAC 8 firmware, there is a bug that may hamper access, though there is a work-around.

If you not have previously changed your iDRAC root account password, enable IPMI access if you have not done so already. In the web (HTTPS) iDRAC interface, navigate to IPMI settings and enable **IPMI over LAN**.

```
Settings > Network/Security > IPMI Settings
```

If you have previously changed your iDRAC root account password prior to enabling IPMI-over-LAN, and your server has one of the affected minor versions, you will receive the following error:
```
Error: Unable to establish IPMI v2 / RMCP+ session
```

This error occurs when the iDRAC root account password was changed prior to setting the **IPMI over LAN** setting to *Enabled*. To prevent this from happening, activate IPMI via the web-based firmware interface first, before changing the default iDRAC root account login and password.

The defect is related to how the iDRAC controller stores its root account user passwords. The iDRAC HTTPS login and IPMI login passwords are stored independently. When the HTTPS root user login credentials are changed, if IPMI access is not currently enabled at that time, the controller does not mirror the root account name / root password updates to the IPMI login copy. This results in a disconnect when IPMI access is later enabled. The current root account login credentials do not match the stored IPMI login credentials, and vice-versa.

If you happen to have the old credentials, it may be possible to continue using them for the IPMI login process only. However, I have not tested this theory, and either way this practice is strongly discouraged as it would mean remembering two (2) independent sets of credentials, increasing the risk of unauthorized access to the server.

#### iDRAC 8 IPMI Credentials Bug
When this scenario is encountered, the fix requires resetting the (HTTPS) root account password back to its factory setting, and proceeding with enabling IPMI access, and then changing the root password back to what it was before, or a new password.

1. Login to the iDRAC controller via HTTTPS interface (i.e. via web browser)
2. There is no need to perform a complete factory reset on the iDRAC controller. Simply reset only the root account password to the factory default ("calvin")
3. Exit the iDRAC interface
4. Restart the server
5. Login to the iDRAC interface via web browser (HTTPS)
6. Access the iDRAC web interface and navigate to IPMI settings. Enable **IPMI over LAN**.
```
Settings > Network/Security > IPMI Settings
```
7. Change the root account name and password per your discretion
8. Log out of iDRAC (this is a precaution to make sure the root account changes stick fully)
9. Login to iDRAC again via web browser, verifying the root credentials have changed
10. Logout
11. Test the connection to the iDRAC controller via IPMI with your root account credentials

### iDRAC 8 Summary Table of IPMI Fan Control Versions

| iDRAC Version          | Release Date | Manual Fan Control Possible? | Notes                                                                 |
| ---------------------- | :----------: | :--------------------------: | --------------------------------------------------------------------- |
| iDRAC 8 v2.00.00       |   Mar 2014   |             Yes              | Initial release. Aligned with 13th-gen PowerEdge server introduction. |
| iDRAC 8 v2.01.01.01    |   Jul 2024   |             Yes              |                                                                       |
| iDRAC 8 v2.02.02.02    |   Dec 2015   |             Yes              |                                                                       |
| iDRAC 8 v2.10.10.10    |   Mar 2015   |             Yes              |                                                                       |
| iDRAC 8 v2.20.20       |   Aug 2015   |             Yes              |                                                                       |
| iDRAC 8 v2.30.30.30    |   Jun 2016   |             Yes              |                                                                       |
| iDRAC 8 v2.40.40.40    |   Dec 2016   |              No              |                                                                       |
| iDRAC 8 v2.50.50.50    |   Jun 2017   |              No              |                                                                       |
| iDRAC 8 v2.52.52.52    |   Oct 2017   |              No              |                                                                       |
| iDRAC 8 v2.60.60.60    |   Jun 2018   |      Maybe<sup>1</sup>       |                                                                       |
| iDRAC 8 v2.61.60.60    |   Dec 2018   |      Maybe<sup>1</sup>       |                                                                       |
| iDRAC 8 v2.62.60.60    |   Mar 2019   |      Maybe<sup>1</sup>       |                                                                       |
| iDRAC 8 v2.63.60.61    |   Jun 2019   |      Maybe<sup>1</sup>       |                                                                       |
| iDRAC 8 v2.70.70.70    |   Oct 2019   |      Maybe<sup>1</sup>       |                                                                       |
| iDRAC 8 v2.75.75.75    |   May 2020   |              No              |                                                                       |
| iDRAC 8 v2.80.80.80    |   May 2021   |              No              |                                                                       |
| iDRAC 8 v2.81.81.81    |   Oct 2021   |              No              |                                                                       |
| iDRAC 8 v2.82.82.82    |   Jan 2022   |              No              |                                                                       |
| iDRAC 8<br>v2.83.83.83 |   Apr 2022   |              No              |                                                                       |
| iDRAC 8<br>v2.84.84.84 |   Mar 2023   |              No              |                                                                       |
| iDRAC 8<br>v2.85.85.85 |   Oct 2023   |              No              |                                                                       |
| iDRAC 8 v2.86.86.86    |   Apr 2024   |              No              | Final iDRAC 8 release; security vulnerability patch                   |

<sup>1</sup> May possibly work. May be impacted by server model.

### iDRAC 9
Manual fan control with iDRAC 9 is a more complex topic than other iDRAC versions. On the one hand, iDRAC 9 versions [within a specified range](dell-idrac-fan-control.md#3-goldilocks-idrac-9-v3000000---v3323232) have the most well-supported capability for manual fan control of any iDRAC major/minor version combination. During this time period, although Dell did not officially sanction manual fan control via IPMI, these iDRAC 9 versions were situationally aware of IPMI's control over the fans, thanks to Dell's implementation of the iDRAC automatic fan control on/off switch discussed [above](dell-idrac-fan-control.md#idrac-7-8-gen-12-13-14).

### iDRAC 9 Version History
Tracking iDRAC versions within each release can be a bit confusing to follow for a couple of reasons:
- Although release versions are numbered sequentially, their release schedule does not always follow a chronologically linear pattern.
- Versions are branched based on the first integer in the full release version. For example, iDRAC 9 3.30.30.30 belongs to the iDRAC 9 3.x branch.
- iDRAC 9's versioning scheme consists of different development branches based on hardware compatibility considerations. These different branches often have different development cycles, potentially relying on different technical teams within Dell.

This approach sometimes results in higher-numbered versions being released before lower-numbered ones, even within the same top-level sub-version range (e.g. iDRAC 9 3.xx.xx.xx). For example, iDRAC 9 3.32.32.32 preceded iDRAC 9 3.31.31.31 by two months.

| **Version** | **Release Date** | IPMI Manual Fan Control? |                               **Notable Features**                                |
| :---------: | :--------------: | :----------------------: | :-------------------------------------------------------------------------------: |
| 7.10.90.00  |     Dec 2024     |            No            |                                                                                   |
| 7.10.75.00  |     Oct 2024     |            No            | Enhancements for 15th & 16th gen servers, security updates, expanded Redfish APIs |
| 7.10.70.00  |     Sep 2024     |            No            |                        GPU, thermal stability improvements                        |
| 7.10.30.00  |     Mar 2024     |            No            |                     Improved stability for gen 15, 16 servers                     |
| 7.00.55.00  |     Dec 2023     |            No            |       Performance improvements, updated support for NVMe drives, bug fixes        |
| 7.10.50.00  |     Jun 2024     |            No            |                    Stabilize iDRAC on gen 15, 16; Redfish API                     |
| 7.00.00.173 |     Aug 2024     |            No            |                                                                                   |
| 7.00.00.172 |     Jun 2024     |            No            |                                                                                   |
| 7.00.00.00  |     Jun 2023     |            No            |                                                                                   |
| 6.10.91.00  |     Aug 2023     |            No            |                          Last iteration of iDRAC 9 v6.x                           |
| 6.10.30.20  |     Apr 2023     |            No            |                                                                                   |
| 6.11.11.11  |     Aug 2023     |            No            |                      Support new hardware, system stability                       |
| 6.10.10.10  |     Jun 2023     |            No            |                                                                                   |
| 6.10.00.00  |     Dec 2022     |            No            |                                                                                   |
| 6.00.30.00  |     Nov 2022     |            No            |                                                                                   |
| 6.00.00.00  |     Nov 2022     |            No            |                        Gen 16 support, enhanced telemetry                         |
| 6.00.02.00  |     Aug 2022     |            No            |                         Support newer hardware; bug fixes                         |
| 5.10.50.00  |     Aug 2022     |            No            |                                                                                   |
| 5.10.30.00  |     Jun 2022     |            No            |                           More Redfish API enhancements                           |
| 5.10.00.00  |     Dec 2021     |            No            |                         Better remote management support                          |
| 5.00.00.00  |     Jun 2021     |            No            |                        Minimum version for gen 16 servers                         |
| 4.40.55.00  |     Oct 2021     |            No            |                                                                                   |
| 4.40.45.00  |     Jul 2021     |            No            |                                                                                   |
| 4.40.40.40  |     Jul 2021     |            No            |                        Major release. Downgrade prevention                        |
| 4.40.35.00  |     Jul 2021     |            No            |                                                                                   |
| 4.40.29.00  |     Jul 2021     |            No            |                                                                                   |
| 4.40.20.00  |     May 2021     |            No            |                                                                                   |
| 4.40.10.00  |     Apr 2021     |            No            |                                                                                   |
| 4.40.00.00  |     Dec 2020     |            No            |                                   Major release                                   |
| 4.32.10.00  |     Dec 2020     |            No            |                                                                                   |
| 4.30.30.30  |     Sep 2020     |            No            |                                                                                   |
| 4.22.00.00  |     Aug 2020     |            No            |                                                                                   |
| 4.20.20.20  |     Jun 2020     |            No            |                                Redfish API updates                                |
| 4.11.11.11  |     Mar 2020     |            No            |                                                                                   |
| 4.10.10.10  |     Feb 2020     |            No            |                                                                                   |
| 4.00.129.00 |     Jun 2020     |            No            |                                                                                   |
| 4.00.00.00  |     Dec 2019     |            No            |                                   Major release                                   |
| 3.42.42.42  |     Oct 2019     |            No            |                                                                                   |
| 3.40.40.40  |     Sep 2019     |            No            |                                                                                   |
| 3.36.36.36  |     Sep 2019     |            No            |                                                                                   |
| 3.34.34.34  |    June 2019     |            No            |                            Disabled manual fan control                            |
| 3.32.32.32  |     Apr 2019     |           Yes            |                                                                                   |
| 3.31.31.31  |     Jun 2019     |           Yes            |                                                                                   |
| 3.30.30.30  |     Mar 2019     |           Yes            |                                   Major release                                   |
| 3.24.24.24  |     Jan 2019     |           Yes            |                                                                                   |
| 3.23.23.23  |     Nov 2018     |           Yes            |                                                                                   |
| 3.21.26.22  |     Dec 2018     |           Yes            |                                                                                   |
| 3.21.24.22  |     Dec 2018     |           Yes            |                                                                                   |
| 3.21.23.22  |     Sep 2018     |           Yes            |                                                                                   |
| 3.21.21.22  |     Jul 2018     |           Yes            |                                                                                   |
| 3.21.21.21  |     Jun 2018     |           Yes            |                                                                                   |
| 3.20.21.20  |     Dec 2018     |           Yes            |                                                                                   |
| 3.20.20.20  |     Sep 2018     |           Yes            |                                                                                   |
| 3.18.18.18  |     May 2018     |           Yes            |                                                                                   |
| 3.17.20.17  |     Apr 2018     |           Yes            |                             Targeted release (minor)                              |
| 3.17.18.17  |     Feb 2018     |           Yes            |                             Targeted release (minor)                              |
| 3.17.17.17  |     Dec 2017     |           Yes            |                                                                                   |
| 3.16.16.16  |     Dec 2017     |           Yes            |                             Targeted release (minor)                              |
| 3.15.19.15  |     Feb 2018     |           Yes            |                             Targeted release (minor)                              |
| 3.15.17.15  |     Jan 2018     |           Yes            |                             Targeted release (minor)                              |
| 3.15.15.15  |     Dec 2017     |           Yes            |                             Targeted release (minor)                              |
| 3.11.11.11  |     Sep 2017     |           Yes            |                             CPU and security updates                              |
| 3.00.00.00  |     Jun 2017     |           Yes            |           Coordinated w/gen 14 server release. Not backward compatible.           |
| 2.30.30.30  |     Oct 2018     |           Yes            |                                                                                   |
| 2.20.20.20  |     Jun 2018     |           Yes            |                                                                                   |
| 2.10.10.10  |     Mar 2018     |           Yes            |                                                                                   |
| 2.02.00.00  |     Dec 2017     |            No            |                                                                                   |
| 2.01.01.01  |     Sep 2017     |            No            |                                                                                   |
| 2.00.00.00  |    July 2017     |            No            |                                  Initial release                                  |

source: https://www.dell.com/support/kbdoc/en-us/000178115/idrac9-versions-and-release-notes

#### Circumventing the "Fan Ban"
Dell disabled manual fan control capabilities as of iDRAC 3.34.34.34 and further strengthened the ban as of iDRAC 9 4.00.00.00, disabling attempts to downgrade below the release that blocked this feature. Under some circumstances, manually downgrading to a version that *does* support manual fan control via IPMI is feasible, but doing so requires a  [deliberate, multi-step process](dell-idrac-swaps.md) to downgrade iDRAC 9 to a pre-fan controller banned version. The last version of iDRAC that allowed unfettered manual fan speed changes was iDRAC 9 3.32.32.32, released in April 2019.

### iDRAC 9 Summary Table of IPMI Fan Control Versions

| iDRAC 9<br>Version  | **Manual<br>Fan Speed<br>Supported?** |
| :-----------------: | :-----------------------------------: |
|  earlier versions   |          Partial<sup>1</sup>          |
| iDRAC 9 v2.10.10.10 |                  Yes                  |
| iDRAC 9 v2.30.30.30 |                  Yes                  |
| iDRAC 9 v2.60.60.60 |                  Yes                  |
| iDRAC 9 v3.00.00.00 |                  Yes                  |
| iDRAC 9 v3.11.11.11 |                  Yes                  |
| iDRAC 9 v3.15.15.15 |                  Yes                  |
| iDRAC 9 v3.16.16.16 |                  Yes                  |
| iDRAC 9 v3.17.20.17 |                  Yes                  |
| iDRAC 9 v3.17.18.17 |                  Yes                  |
| iDRAC 9 v3.17.17.17 |                  Yes                  |
| iDRAC 9 v3.18.18.18 |                  Yes                  |
| iDRAC 9 v3.20.20.20 |                  Yes                  |
| iDRAC 9 v3.20.21.20 |                  Yes                  |
| iDRAC 9 v3.21.21.21 |                  Yes                  |
| iDRAC 9 v3.21.23.22 |                  Yes                  |
| iDRAC 9 v3.21.24.22 |                  Yes                  |
| iDRAC 9 v3.21.26.22 |                  Yes                  |
| iDRAC 9 v3.23.23.23 |                  Yes                  |
| iDRAC 9 v3.30.30.30 |                  Yes                  |
| iDRAC 9 v3.32.32.32 |                  Yes                  |
| iDRAC 9 v3.34.34.34 |                  No                   |
|   later versions    |                  No                   |

<sup>1</sup> Risk of race conditions with iDRAC and BIOS (particularly iDRAC), may result in instability when attempting IPMI fan control operations.
