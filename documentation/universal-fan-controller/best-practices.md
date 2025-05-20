# UFC Best Practices: Usage and Customization
A collection of recommendations for maximizing performance with the Universal Fan Controller (UFC).

## 1. Read the Docs
All three core programs are heavily documented, which should assist troubleshooting when necessary. There is also extensive stand-alone documentation, as you can see here.

---------------------

## 2. Modular Coding Design
UFC is built on a highly modular design for several reasons:
1. Keeping the runtime footprint as small as possible in memory, while not requiring disk reads to operate the program.
  - Requiring reading content from disk to keep the RAM footprint super small would add substantial risk. If the source disk were to fail or become inaccessible for another reason, the program's operation would be compromised. Since this program will be controlling your server's fans, it is crucial that it operate unhindered.
2. Numerous calculations are repeated across one or more of the core programs (the Builder, Service Launcher, and Service Runtime). By compartmentalizing common tasks into dedicated functions, it means that tweaks or adjustments will apply in all areas they are used, preventing inconsistencies.
3. Ease of customization. Expanding the universe of motherboard manufacturers and models is relatively simple, as the process is template-based.

---------------------

## 3. Review Motherboard Config Files
Determine whether or not adjustments should be made to the motherboard manufacturer or model configuration files pertaining to your server's motherboard.

1. Identify your motherboard's manufacturer and model.
2. Determine whether the manufacturer is supported or not.
  - Look for a manufacturer sub-directory name in `/config/manufacturers/` matching your motherboard's manufacturer name.
  - If one is not found, cross-reference the [Supported Hardware Manufacturers](supported-hardware-manufacturers.md) list.
  - If your motherboard manufacturer is not supported, **stop here** and go to the next topic in this document, as unfortunately, UFC is not compatible with your board.
3. Locate sub-directory corresponding to your motherboard manufacturer under the `/config/manufacturers/` directory.
4. Look for a filename resembling your motherboard's model.
  - Remove spaces and special characters from your board's name to find a match.
  - If you do not find an exact match, then only the manufacturer's configuration file will apply.

Once you have determined whether or not a manufacturer and/or motherboard model configuration file are pre-existing:
- If your motherboard model has a pre-existing config file, you can **stop here** as you do not need to do anything else on this topic.
- If not, you should consider creating one by studying the motherboard config file templates and other existing motherboard model config files. However, it may be easier and more prudent to simply take a look at the Builder configuration file and adjust it as necessary. Some trial-and-error may be required when initially running the Builder to determine if any errors occur due to the Builder's inability to determine any key characteristics about your board.

---------------------

## 4. Customize Builder Config File
Review the Builder config file carefully, as it contains useful contextual information and may not currently be setup in a manner you would prefer. This is especially true with regards to default fan speed settings.

Review the guide on the [Builder configuration file](/documentation/configuration/builder-config-file.md) and/or review the embedded notes in the file itself.

You should review and customize the Builder config file based on your needs and your server motherboard's characteristics. The Builder config file stacks on top of related motherboard manufacturer and model configuration adjustments. Config files are loaded and processed in this order:
1. Manufacturer-specific (if exists)
2. Model-specific (if exists)
3. Builder config file (required)

> [!TIP]
> Carefully review the 'optional' parameters in the Builder configuration file.
> 
> While it may be tempting to allow the Builder to fill in various variable values automatically, this also means giving up control over customization. It is suggested to review each optional field and make an independent decision on customization for each, rather than ignoring all of them.

---------------------

## 5. Presume All Disks are HDDs Even When They're Not
The Universal Fan Controller (UFC) presumes all disk devices are hard disk drives (HDDs). By default, it excludes any disk device it discovers that it does not recognize as a HDD.

### Why HDDs are Presumed by Default
UFC makes a number of presumptions with regards to data storage devices:
1. Only disk based storage devices are relevant.
2. All disk based storage devices are internal to the server chassis.
3. Only HDDs should be monitored.
4. SSDs should be ignored.
5. Target temperature is an average target, inclusive of all storage devices.
6. The current ambient temperature of every storage device should be as close as possible to the target temperature.
7. Managing ambient temperature is simpler when all monitored devices are the same type.
8. Although small temperature variations may exist within a drive array, when all drives are the same type, their variations rarely impact server performance.
9. HDDs typically have lower operating temperatures than other storage devices, and being mechanical, are more prone to developing faults due to temperature extremes.
10. UFC focuses on monitoring the average ambient temperature of storage devices.
11. As far as hardware protection is concerned, UFC is biased toward protecting devices from excessive heat. This strategy aligns with HDD temperature requirements.
12. Including a mixture of devices to skew the average temperature, causing UFC to adjust fan speeds too frequently. For example, Solid State Drives (SSDs) are known for their resilience in higher temperatures. In fact, they tend to operate with higher average temperatures than HDDs, perhaps due to their solid state composition versus the electro-mechanical nature of hard drives.

### Mixed Storage Device Environments
The most common mixed-use storage environment consists of a combination of HDDs and SSDs. There are two schools of thought on how UFC should handle such situations.
1. As explained above, the default method ignores the SSDs.
2. The other option is to force all disk devices to be taken into consideration for monitoring and average temperature calculations.

### Why Are non-HDDs Excluded by Default?
When HDDs and SSDs are mixed together in the same server, prioritizing the ambient temperature needs of the HDDs should not adversely effect the SSDs, as long as:
1. The disk device **Disk Target Temperature** is set based on the needs of the storage device *with the lowest maximum operating temperature*; and
2. No data storage device in the server would be negatively impacted by *lower* average operating temperatures.

> _In a mixed storage environment, the device with the lowest maximum operating temperature should generally determine the target temperature._

Most SSDs have significantly higher temperature tolerances than HDDs. Unlike HDDs, most SSDs could care less until ambient temperature is well above the comfort-level of most HDDs. In fact, most SSDs are capable of operating without issue in ambient temperatures that would have a high risk of damaging a HDD.

Some SSDs may *prefer* cooler operating temperatures, but generally speaking there is no preference for most SSDs other than remaining in their "zone" of acceptable temperature range. 

Putting all this together, the overall point is UFC's default behavior ignores non-HDDs because HDDs are presumed to be the most temperature sensitive group of any storage devices in the server. When every other device type is able to tolerate ambient temperatures above teh comfort-level of hard drives, and are not impacted by cooler temperatures, then there is no reason to alter UFC's default behavior (from the standpoint of temperature protection of storage devices).

UFC is designed primarily to address cooling hard disk drives (HDDs) and servers that use them, such as those running RAID or ZFS clusters. As a result, UFC defaults to monitoring HDDs only, presuming any unrecognized storage device is an SSD. Since HDDs are mechanical and typically have lower operating temperature thresholds than SSDs, cooling HDDs is a higher priority. In practice, SSDs generally benefit indirectly when fans are adjusted to keep HDD temperatures in check. While there is a rare risk of an SSD overheating without being monitored, this is unlikely given most server setups and typical operating conditions.

A potential concern is that SSD temperatures could rise faster than HDDs or even exceed their maximum or ideal operating temperatures, while monitored HDDs appear to be operating normally. In UFC’s default mode, this condition would go unnoticed and consequently would not be addressed, posing a legitimate - though unlikely - risk. While this feature can be overridden, it’s recommended to leave it as-is in order to maintain consistent cooling for the most temperature-sensitive devices (likely HDDs).

### Activating SSD Support
If you want to include SSDs in UFC’s monitoring (including NVMe<sup>1</sup> disks) - you will need to adjust the Builder configuration file. 

Locate the following section in your UFC Builder program config file:

```
#################################
## DISK DEVICE MONITORING OPTIONS
#################################
```
Edit this line:
```
include_ssd=false
```
Change it to:
```
include_ssd=true
```
This forces UFC to monitor all disk devices, regardless of type.

### When Not to Change the Default Behavior
Mixing data storage device types (e.g., HDDs and SSDs) *from a hardware monitoring perspective* can be counter-productive to UFC's [primary goals](program_goals.md).

One key consideration is how UFC calculates the current temperature as an average of all monitored disk devices. Since SSDs often operate at higher temperatures than HDDs, including them can elevate the average and cause UFC to increase fan speeds more frequently and for longer periods. This can result in unnecessary fan noise.

Whether this is an issue for your setup depends on your specific environment and tolerance for increased fan activity. If you don't need to monitor SSDs, it’s generally best to stick with UFC’s default behavior to maintain efficient and consistent cooling.

<sup>1</sup> Non-Volatile Memory Express<br>

> [!NOTE]
> UFC’s temperature averaging and trend monitoring algorithms may produce inconsistent results when storage device operating temperature ranges differ significantly.
> 
> Optimized cooling behavior for mixed-use storage configurations is planned (see [Future Roadmap](future_roadmap.md))

---------------------

## 6. Use the Failure Notification Handler Daemon
The [Failure Notification Handler](fnh.md) (FNH) is a stand-alone **systemd** service daemon that is triggered upon an unexpected failure of either of the Service programs (Launcher or Runtime). It is a highly useful feature when troubleshooting unexpected UFC behavior, and users are recommended to favor its use.

The FNH is responsible for notifying the end user via email when and why a core program failed. Disable the Failure Notification Handler daemon if your operating system does not support email or you do not wish to receive email alerts.

---------------------

## 7. Disable Irrelevant Optional Features
Think about your needs. How will the server be utilized? How many groups of fans do you need or should you have? What purpose do you need them to serve?

Disable features you don't care about. For example, if your server has just a few fans, it may be prudent to configure just one fan zone and setup your configuration for a CPU-only focused cooling strategy.

---------------------

## 8. Traps
Debug traps are built-in to both Service programs. The code portions pertaining to the traps may need to be modified or removed on some systems, based on the absence of or difference in trap signals. The built-in traps are designed to shutdown errant services and provide high-level troubleshooting info via email alerts (using the Failure Notification Handler).

---------------------

## 9. Configuration Files
As explained under [Program Design: Configuration Files](program-design.md#configuration-files), UFC utilizes multiple configuration file types. Which file is best to influence a given parameter depends on what the paramater is and its purpose. Each is handled independently and has a different purpose. They are, however rolled-up sequentially, meaning as each subsequent include file is loaded, any identical parameters loaded from previous files will be overwritten.

These are the possible configuration file types and the order in which they are loaded:
1. Motherboard manufacturer config files (optional)
2. Motherboard model config files (optional)
3. Builder configuration file (required)

This makes the user-defined Builder configuration file the ultimate location for end users to influence UFC behavior, including overriding settings in the motherboard manufacturer/model config files.

Certain features should be defined in other config files first, and can ultimately be overruled via the Builder config file if deemed appropriate by the end user. However, establishing defaults in other config files that are processed prior to the Builder config file is prudent. These other config files are static and set baselines for certain critical variable definitions, without which UFC's Builder cannot run.

### Default Fan Control Method
Set a default [fan control method](/documentation/configuration/manufacturer-config-files.md#fan-control-methods) first at the manufacturer level configuration file. If more than one choice is available for a give motherboard, consider setting a different choice for this variable in any given motherboard model configuration file. However, generally speaking if you wish to override the default (defined in the manufacturer-level config file), it's usually best to do so via the user-defined Builder config file, as it is your opportunity to customize how the Builder program runs and how the UFC operates overall.

---------------------

## 10. Hot Swapping Fans
Don't do it.

Hot-swapping fans is the practice of removing or replacing fans while the server is operating. It is **strongly discouraged**. The practice is not supported by UFC and is likely to lead to unpredictable behavior for several reasons:
- The service Runtime program performs a fan validation periodically. This scan occurs at different time intervals, and during these validation phases the program attempts to detect failed or failing fans. UFC will tag fans it perceives to be [suspicious](suspicious-fans.md), and if a fan is expected, but cannot be detected on multiple passes, it will be disqualified.
- A disqualified fan header will be ignored even if a fan is plugged back into it.
- Hot-swapping hardware (including fans) while a server is running is also inherently risky from a hardware perspective, irregardless of its effects on UFC.

---------------------

## 11. Replacing Fans
If a fan is replaced for any reason, re-run the Builder (setup program). Failing to do so will result in unpredictable consequences.

---------------------

## 12. Intentional Disk Inventory Changes
One of UFC's responsibilities is monitoring the health of the server's disk storage device array. To that end, UFC maintains a record of known disk storage devices present in the server. Whenever a discrepancy is detected between the [baseline and current lists of disk storage devices](/documentation/details/disk-inventory-management.md), a notification event is triggered.

When the disk inventory is changed intentionally and the change is expected to be permanent, the Builder should be re-run. This updates the disk inventory benchmark and resets the discrepancy detection mechanism.

If a user fails to do this, each time the server restarts, the Launcher will trigger a false alert indicating that a change has occurred in the disk inventory. This includes sending emails if that option is enabled in the Builder configuration.

Although re-running the Builder may seem inconvenient, it prevents misleading alerts. Consider this scenario: a disk fails, but the user hasn’t re-run the Builder to update the expected inventory. If the system only notifies the user once - when the Launcher first detects the failure - the warning could easily be forgotten. By rechecking the inventory on every boot, UFC ensures persistent issues remain visible.

The purpose of this process is to inform. If the condition that triggered the notification has not changed (i.e., on the next system boot), then the warning is still valid and should continue. The proper way to stop these warnings is to re-run the Builder, which re-generates the initialization (`.init`) file it provides as input to the Launcher. Among other things, this file contains the baseline disk device inventory. By resetting that inventory when the user is aware of the change and considers it permanent, false alerts are avoided while preserving the integrity of the monitoring system.
