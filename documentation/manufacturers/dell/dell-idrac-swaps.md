# Changing Dell iDRAC Versions
From an official support perspective, iDRAC major versions are locked in. This means the iDRAC major version assigned to a server generation does not change and users should not attempt to install replace their server's iDRAC firmware with a different major release. In other words, if your Dell server came from the factory with iDRAC 8 for example, do not attempt install iDRAC 7 or iDRAC 9 on it. The reason for this is that iDRAC major release versions (6/7/8/9/10) are closely tied to the hardware of the server and/or similar hardware available at the time the server generation was produced.

On the other hand, upgrading and downgrading iDRAC versions within a major release are feasible and encouraged. Upgrading and even downgrading iDRAC firmware versions are a common practice, though some general guidelines should be followed:
1. Servers should not be downgraded below the first iDRAC version installed from the factory for the given server model.
2. Server models have a maximum supported iDRAC version, and one should avoid attempting to update firmware beyond this level. It can be challenging to determine what the maximum is, but here are a few best practices to avoid surpassing a model's maximum version:
	- Don't upgrade the firmware unless there is a good reason to do so.
	- Avoid upgrading outside the iDRAC version tree currently installed on the server. This is the first number of the iDRAC version that is not the iDRAC release number. For example, iDRAC 9 4.00.00.00 is part of the iDRAC 9 4.x version tree.

Restrictions on downgrading iDRAC firmware are more important to adhere to than upgrade restrictions. This is because newer firmware versions *should* be supportive of older hardware platforms, though it is possible that newer firmware installed on older hardware will result in gaps or errors in the iDRAC web (HTTPS) interface choices available to an end user, it should support the core management functions of the older hardware. Again, staying within the same version tree is ideal as it prevents this problem from occurring. This means that for instance, if your server came with iDRAC 8, don't install iDRAC 9.

Downgrading firmware - and especially forced downgrading - is less common and not officially sanctioned, and comes with a higher risk of undesirable effects. 

## Safe iDRAC Versions by Server Gen

| **Dell Server Generation** | **iDRAC Versions**                                                  | **Notes**                                                                             |
| -------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Gen 10, 11**             | iDRAC 6 (Firmware 1.x-2.x)                                          | Basic remote management. Cannot use later iDRAC generations.                          |
| **Gen 12**                 | iDRAC 7 (Firmware 1.x-1.65.x)                                       | NTP support, Redfish management.                                                      |
| **Gen 13**                 | iDRAC 8 (Firmware 2.x)                                              | HTML5-based UI and virtual console features. UEFI secure boot, HTML5 virtual console. |
| **Gen 14**                 | iDRAC 9 (Firmware 3.00.00.00-4.40.40.40)                            | First iDRAC 9 adoption. New User Interface. Support for modern hardware.              |
| **Gen 15**                 | iDRAC 9 (Firmware 4.40.40.40-7.10.75.00)                            | Expanded firmware capabilities and support for modern hardware.                       |
| **Gen 16**                 | iDRAC 9 (Firmware 7.x)                                              | Added advanced features including telemetry.                                          |
| **Gen 17**                 | iDRAC 9 (Firmware 7.00.00.173-7.x)<br><br>iDRAC 10 (Firmware 1.x-?) | Gen17 can use iDRAC 9 or iDRAC 10 only, depending on the specific model.              |

## iDRAC Version Downgrades
While minor version downgrades are possible to an extent, users should not attempt to downgrade their server's iDRAC release to a lower instance (e.g. from iDRAC 8 down to iDRAC 7). System firmware, BIOS, and iDRAC versions are designed to work together within the Dell server hardware ecosystem. Dell does not support downgrading a server's iDRAC firmware to a major release version lower than the factory-installed version (e.g. downgrading from iDRAC 8 to iDRAC 7). Doing so is likely to result in unstable behavior and/or render the iDRAC controller inoperable. For example, iDRAC 9 supports gen 14 servers, but iDRAC 8 lacks the necessary support for features and hardware introduced in gen 14 servers. Thus, downgrading the firmware on a gen 14 server from iDRAC 9 to iDRAC 8 is ill advised.

### Summary of iDRAC Version Downgrade Options
- Downgrading within the same version tree (e.g., v4.x to v4.x or v3.x to v3.x) is generally safe.
- Do not attempt to downgrade below the [minimum safe iDRAC version](dell-idrac-limits.md).
- Downgrading to a previous branch (e.g., from iDRAC 9 v4.x to v3.x or v2.x) is not recommended, as it can lead to:
    - Hardware compatibility issues: Newer hardware may not work properly with older branches, even of the same iDRAC release number.
    - Feature loss: You could lose access to important server features that were added in newer iDRAC versions.
    - Potential stability and security risks: Older versions may have unpatched bugs and security vulnerabilities, and may no longer be actively supported.
- Downgrade in steps to maintain optimal stability.
	- This means downgrading from the current firmware version to the prior version number appropriate for the server model, and within the same version tree.
	- The preferred method to do so involves the use of Dell's built-in tools, such as the Lifecycle Controller and the iDRAC web (HTTPS) interface.
		- Dell's Lifecycle Controller is not available universally. It was introduced in 2018 in iDRAC 9 3.21.21.21. Ignore mentions of it if your server pre-dates this release or if you purposefully downgrade below that version.
- When there is a need to downgrade to an older branch, (e.g. from IDRAC 9 4.x to iDRAC 9 3.x), downgrade in steps, but using the lowest possible downgrade version in each step. Ensure downgrading to the first version in the branch (e.g. iDRAC 9 5.00.00.00), then downgrade to the top of the next lower branch (e.g. from iDRAC 9 5.00.00.00 down to iDRAC 9 4.40.55.00) before downgrading within the next lower branch (e.g. anything in the iDRAC 9 4.x branch).
- Some iDRAC versions only apply to very specific server models. These typically were issued in order to address specific problems - such as bug fixes - that apply only to particular models. Attempting to install such releases on a server model they are not intended for risks disrupting the downgrade process, and in the worst case scenario could brick the server.
- Manual update methods may be used to downgrade when the iDRAC firmware will not allow going past a particular point, but bear in mind this increases risk.

**Staying within the same branch** (and making only stepped downgrades) is the safest path. If you need to downgrade to an older branch (such as from v4.x to v3.x), make sure to follow the necessary downgrade steps to avoid incompatibilities and instability.

> [!NOTE]
> There are special situations allowing some overlap between iDRAC release version and server generation, but it is difficult to determine exactly which server models can reliably utilize this approach, and the end result is unpredictable.
> 
> For example, iDRAC 8 can theoretically be applied to server gens 13-16, although doing so doesn't make sense under most circumstances for gen 14+. Conversely, both gen 11 and 12 require iDRAC 6, and gen 17 requires iDRAC 9.
> 
> Overall, it's wise to stick with the iDRAC major version that was first bundled with the server and not to try and shoehorn a previous iDRAC version into it, even if it could theoretically work.

### Semi-Automatic Downgrades
Most iDRAC releases have a built-in downgrade path which can be selected and run in the iDRAC web (HTTPS) interface. Intended to simplify back-tracking if an iDRAC upgrade goes poorly, this process can also be utilized to voluntarily downgrade for other reasons. This is the default downgrade method mentioned above with regards to stepping down in versions. Chaining this process into multiple step-downs is the preferred method of downgrading as the entire process gets handled automatically by the iDRAC firmware. Here this concept is referred to as "semi-automatic" because the user must initiate each downgrade step. The process is repeated as long as necessary or until reaching a point where a release cannot be downgraded.

When a user cannot get down to their target iDRAC version using this method, manual downgrades are the next option.

> [!warning]
> Dell recommends not downgrading iDRAC firmware below the original version shipped with the server, as this can lead to instability or unsupported configurations.
> 
> See [iDRAC History](dell-idrac-history.md) to find a server model's lowest safe iDRAC release and version number.

### Manual Downgrade Process
If user-friendly, partially automated downgrades are not possible or insufficient to attain your goals, it is possible to circumvent the process and its accompanying restrictions by performing iDRAC downgrades manually.

A good example is iDRAC 9 version 4.00.00.00, which will not allow a user to downgrade iDRAC 9 below 3.34.34.34. And likewise, iDRAC 9 3.34.34.34 will not allow a user to downgrade *at all*. These particular restrictions are tied to preventing users from installing iDRAC firmware that will allow manual fan controls via IPMI, which is discussed at length [here](dell-idrac-fan-control.md). So, if for example, you are a home network lab user interested in configuring a Dell PowerEdge server to not sound like a jet engine taking off in your home lab, you might find yourself in this position.

The solution involves learning the process to manually force the iDRAC controller to wipe its current firmware and flashing the new (lower) firmware version to it.

> [!WARNING]
> Before proceeding with a manual iDRAC downgrade, cross-check your server model against the [Safe iDRAC Versions by Server Model](dell-idrac-limits.md) list.

Here's what you will need to do:
1. Plot your step-down firmware versions from that which is currently installed on your server to the firmware version you wish it to use. Double-check that each leg down is feasible based on compatibility. You should be able to find this information in the release notes for the various iDRAC versions. If not, search Dell's support website and online forums .
2. Once your path is confirmed, determine which firmware versions you will need, and acquire them. All of Dell's iDRAC firmware releases may be downloaded independently from [Dell's support website.](https://www.dell.com/support/kbdoc/en-us/000130533/dell-poweredge-how-to-update-the-firmware-via-https-connection-to-idrac)
3. Execute the manual firmware updates in order. After each has been installed, restart the server at least once, preferably via a cold boot process to ensure all parameters of each iDRAC version get initialized properly before continuing to the next firmware removal/installation process.

For detailed instructions, refer to [Dell's support website](https://www.dell.com/support/kbdoc/en-us/000130533/dell-poweredge-how-to-update-the-firmware-via-https-connection-to-idrac).

Exact instructions and potential pitfalls vary based on a variety of factors, including the starting iDRAC release version and the hardware on the server. Generally speaking, it's best to only perform a manual or forced downgrade to the point where you can accomplish your goals by continuing with further downgrades (if necessary) via the tools built-in to iDRAC for this purpose, which include (in no particular order):
- iDRAC 7/8/9 HTTPS interface upgrade tool (well documented [here](https://dharper.co.uk/?p=196))
- Dell's Lifecycle Controller (iDRAC 9 3.21.21.21 and later ONLY)
- Dell Repository Manager
- iDRAC Recovery Mode

### Downgrading to Attain Manual Fan Control
Focusing on manual fan control capabilities, if you've digested the information about [iDRAC Fan Control](dell-idrac-fan-control.md) and [Dell iDRAC History](dell-idrac-history.md), you're already familiar with the limitations built-in to iDRAC 9 with regards to manual fan control via IPMI. This information is poignant to certain use cases, such as those common with home network lab users, and are readily illustrated by the potential challenges of downgrading more recent server generations in order to gain manual fan control. For example, to manually downgrade iDRAC 9 5.00.00.00 to a release allowing manual fan control via IPMI, you cannot simply downgrade from your current iDRAC 9 5.00.00.00 firmware directly to iDRAC 9 3.32.32.32, as even the Lifecycle Controller will not permit it. This is because iDRAC 9 4.00.00.00 and later versions block downgrades below a certain point. In this case, you would need to first downgrade to version 4.00.00.00, then to 3.34.34.34, and then below that to your target version of 3.32.32.32 or lower.

## Upgrading to a New iDRAC Release
Upgrading within the same iDRAC release (e.g. iDRAC 9), and especially within the same iDRAC release version tree (e.g. iDRAC 9 4.x), is highly encouraged by Dell. Upgrading to the next highest iDRAC release version (e.g. from iDRAC 8 to iDRAC 9) while it may be technically possible, is strongly discouraged by Dell and should be avoided in order to maintain stability, performance, and security of the server.

iDRAC release numbers are incremented when there is a significant enough change in hardware technology between server generations. Therefore, under most circumstances it is sensible to stick with the iDRAC release the server had pre-installed from the factory.

> [!CAUTION]
> Do not attempt to upgrade a native iDRAC 6 controller to later iDRAC later releases. iDRAC 6 hardware controllers and firmware are hard-wired onto the motherboard.

### Upgrading iDRAC Major Release
Upgrading to a higher iDRAC major release - such as from iDRAC 8 to iDRAC 9 - is **strongly discouraged**.

While theoretically possible for many servers, it is generally ill-advised. There may be a few rare exceptions related to models produced very late in a given generation, where the following server gen moved up to a higher iDRAC release number. In these rare cases, you could be successful in upgrading to a higher iDRAC release. However, as a general rule, it's better not to attempt doing so.

iDRAC release (major version) numbers are tied to specific server generations and are heavily tied to hardware present on the generation they were designed for. In the case of iDRAC 6, it's even more stringent. These servers cannot have their iDRAC upgraded because it is hard-coded into the iDRAC controller itself.

When a server model's default major version is iDRAC 7 or higher, in theory it is possible to upgrade to a higher release. For example, iDRAC 9 can theoretically be installed on a gen 12 server. However, this practice is discouraged because its possible the newer iDRAC firmware will suffer performance degradation running on the older hardware and/or some critical features (e.g. boot) will become inoperable.

iDRAC 7 was purpose-built to support hardware that came with the 12th generation of PowerEdge servers. iDRAC 8 is designed to support the 13th gen, and so on. Installing iDRAC 9 on such a system - built on hardware that has been supplanted twice - will at a minimum slow down the performance of iDRAC on that system as the older hardware will be running newer software.

## Example iDRAC 9 Upgrade / Downgrade Decision Tree
iDRAC 9 version 4.00.00.00 will not allow downgrading (in one step) below v3.34.34.34 (which defeats manual fan control). However, it can be downgraded in steps. To enable manual fan control, you would need to downgrade from any version above 3.34.34.34 and up to 4.00.00.00, to version 3.34.34.34. Then downgrade again to version 3.30.30.30. You should now be able to control the case fans manually.

If your starting position is higher than iDRAC 9 version 4.00.00.00, but is version 4.x, then the path is: downgrade to 4.00.00.00, then downgrade to 3.34.34.34, then downgrade again to 3.30.30.30.

If your starting position is iDRAC 9 version 5.00.00.00 or higher, you must step down by each major version number (e.g. from iDRAC 9 version 6.x to version 5.00.00.00) until you reach version 4.00.00.00. Then follow the instructions above for downgrading that version.

| Server Gen | Starting Version Range                    | Action                  |
| ---------- | ----------------------------------------- | ----------------------- |
| 13         | iDRAC 9 version < 2.10.10.10              | Upgrade to 2.10.10.10   |
| 13 or 14   | iDRAC 9 version < 3.00.00.00              | Upgrade to 3.00.00.00   |
| 13 or 14   | iDRAC 9 version 3.00.00.00 --> 3.32.32.32 | Do Nothing              |
| 14         | iDRAC 9 version 3.34.34.34                | Downgrade to 3.32.32.32 |
| 14         | iDRAC 9 version 3.36.36.36 --> 3.42.42.42 | Downgrade to 3.34.34.34 |
| 14 or 15   | iDRAC 9 version 4.00.00.00                | Downgrade to 3.34.34.34 |
| 14 or 15   | iDRAC 9 version > 4.00.00.00              | Downgrade to 4.00.00.00 |
