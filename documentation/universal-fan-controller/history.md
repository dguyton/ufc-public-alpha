# UFC Project History

My first thoughts related to server fan control were not about controlling fan speeds specifically, but rather along the lines of, "*How can I prevent this rack mount server I bought from being so friggin' loud?*" An avid techno-geek since birth, I've spent literally decades programming and building PCs. However, it wasn't until a few years ago that I began dabbling with enterprise-class server motherboards and related components in my home. This was because it was not until around 2012 or so that an abundance of off-lease equipment began hitting the prosumer market. Suddenly, it became possible to garner high-end processing platforms on the cheap. Well, at least they were high-end at one point in time. And given the fact most of these were coming from data centers, although pre-owned and had been operated for thousands of hours non-stop, they were for the most part, in pristine condition. This was a network IT geek's dream come true! There was just this annoying issue of rack mount fans running at say 9k or 15k RPM that were just plain LOUD! So, the question became, what to do about the noise?

My first solution was to physically isolate my servers from the remainder of my home. Eventually, I discovered the Supermicro servers I was using had several built-in fan speed modes. After realizing they defaulted to full speed all the time, yet there was another factory-installed mode called "optimal" fan speed, it became readily apparent this was the way to go. The "optimal" speed mode ran the fans at a constant 30% of total power, which reduced the noise pollution from aircraft engine level to a manageable background whine.

I subsequently dabbled with attempts to replace the stock server fans with alternative, quieter options. However, I found the choices available were limited and tended to miss the mark in terms of noise reduction or their static pressure was too low to provide effective cooling. I reverted back to the stock fans and presumed this was the end of the road.

Several years later, my perspective changed when I began to discover information on various forums, including [TrueNAS](https://www.truenas.com/community/) and [ServeTheHome](https://forums.servethehome.com/) that indicated it might be possible to implement a finer level of control over my servers' fans. I learned how to control the fans directly via IPMI commands, though it required me to tweak them every time the servers were restarted. I subsequently created a small script triggered automatically on start-up to handle this task, and then promptly forgot about it.

As time progressed, I began to realize the static solution I had created had a significant drawback: it was not responsive to changes in system load, which meant I might be over-heating some components (especially hard drives) on occasion without realizing it. After making a point to conduct some research, and start monitoring HDD temps and motherboard temperature sensors, I realized this was indeed a valid concern.

This chain of events led me to go back to the drawing board yet again. This time, I learned there were other people working on solving these same problems, but who had dug deeper and made more progress than I had. After more research and reading through many forum posts, I finally managed to cobble together some idea of how a better solution could be derived. But, before I got very far, I discovered Kevin Horton's small program on the TrueNAS forum.

There are various versions of P.I.D. fan controllers floating around. Many of them are forks of Kevin Horton's Perl script first published in 2016 on the [TrueNAS forum](https://www.truenas.com/community/). Kevin, "Stux" (also of TrueNAS forum fame), and "PigLover" from the [ServeTheHome forum](https://forums.servethehome.com/) are whom I give the biggest credit to putting all the pieces together with regards to unlocking the potential of manual fan control on Supermicro server motherboards. Their combined efforts have led to many others' ability to find salvation in dealing with similar challenges.

> Additional citations of prior art that were inspirations for this program are included in the [References](references.md) page.

These authors deserve full credit for freely sharing their original PID fan controller concepts, research information, and having spent countless hours combing through very technical documents to figure out that manual control of server fans via IPMI was even possible. Their enthusiasm inspired me to conceive this project and bring my own community contribution to fruition over many months.

I started coding my own variation on this them in March 2022. UFC in its current form has taken me over 2-1/2 years to get it to where it is today. Countless hours of work and research, experimentation, design changes, and constantly re-working and improving portions of the program. To understand why and how my interpretation became such a monolithic project, it is necessary to comprehend my [[Project Goals]]. The bottom line is I wanted a comprehensive solution that someone else could treat as off-the-shelf software that was plug-and-play. Download the program, setup a few configuration points, and it just works. I also wanted a solution that was capable of working on server boards other than Supermicro. If I ever purchased another brand of server board in the future, I didn't want to have to repeat this massive deep dive into various rabbit holes all over again, after the details had become distant memories.

# Complete Program History (Release Notes)

This is an archival record.
## Version 2.0 (Universal Fan Controller) - April 2025

1. Completely overhauled architecture, pivoting to modular design
2. Removed manual mode from fan controller
3. Refined the Builder/Runtime architectural model introduced in version 1.1 further by splitting the Runtime concept into two (2) parts: a Launcher script and a smaller Runtime script to reduce the code footprint of the evergreen portion
4. Expanded use of configuration files
5. Enlarged scope to include over a dozen motherboard manufacturers
6. Enhanced anomaly detection
	1. Refined logic for automatic resolution of anomalous conditions
	2. Added additional validation checkpoints before beginning critical tasks
	3. Alert user to resolve non-sequitur issues via program log
	4. Exit gracefully and alert user when encountering non-recoverable error conditions
7. Split Service side core program
	1. Service Launcher: environmental calibration on system boot
	2. Service Runtime: continuous loop fan controller
8. Reduced Service Runtime footprint through design optimizations
9. Core program load only necessary functions
10. Manufacturer-specific parameters moved to separate config files
11. Streamlined configuration handling; loads only relevant parameters
12. Supportive functions migrated to libraries
13. Added traps to handle unexpected program exits
14. Added automated email alerts and program log updates on unexpected exits
15. Improved debug trace details for validation errors
16. Added self-validation (e.g. file manifest and inventory checks)
17. Enhanced Service recycling decision tree through more robust edge case filters
18. Startup self-validation for required components in both Builder and Service programs; fail gracefully when missing
19. New Failure Notification Handler daemon automatically trips when either Service program daemon fails

## Version 1.1 (RaPID Fan Controller) - January 28, 2024

1. Re-branded product name to _RaPID_, an abbreviation for "Robust PID" fan controller
2. Introduced concept of independent Builder vs. Service programs by splitting monolithic program design into bifurcated model as distinct Builder and Service (runtime) scripts
3. Added logic to recycle pre-existing Service implementation when feasible
4. Broadened scope of supported motherboards beyond Supermicro

## Version 1.0 (PID Fan Controller) - January 8, 2023

1. Refactored to support Supermicro X9 motherboards and some X8 motherboards (dicey, but should work on some)
2. Refactored to support Ubuntu 16/18/20/22
3. Refactored variable names to make their purpose clearer
4. Prevent fan-lock condition when the program thinks CPU temperature cannot be read correctly and forces all fans to 100% all of the time
5. Remove program dependencies that do not provide the proper information in Ubuntu, such as **sysctl**
6. Check for program dependencies and fail gracefully when missing
7. Automate disk device identification
8. Intelligently excluded non-HDD devices from temperature data collection
9. Improve support for disk device changes (hot-swap, fail & remove, add new disk device)
10. Add support for multi-CPU motherboards (up to 4 physical sockets)
	- Though rare, some motherboards allow up to 4 CPUs
	- Dual CPU boards are relatively common
11. Prevent program crash when no hard drives exist
12. Remove obsolete or redundant code
13. Automatic fan speed detection: automatically determine cpu and case fan speed min/max limits
14. Automatic fan header detection
15. Automate fan zone identification
16. Move configuration settings to a separate file
17. Stub for future support of non-Supermicro motherboard manufacturers and models
18. Restored variable CPU fan function capability
19. Retained option to not control CPU fans
20. Split into two (2) programs
	- Reduce size of runtime program
	- Expand feature set by moving most branching logic to independent setup/configuration program
	- INIT file customized for each server and preserves settings between reboots
21. Most program functions now handled by functions (sub-routines)
	- This makes it easier to follow order-of-operations, make modifications, and perform troubleshooting
22. Added more verbose logging information, including metadata export as JSON files

## Version 0.1 - October 21, 2022

1. Enhanced version of Kevin Horton's script with significant new functionality
2. Converted Kevin's Perl script to SHell
3. Refactored to support Supermicro X9 motherboards
4. Refactored to support Ubuntu 16/18/20/22
5. Refactored variable names to make their purpose clearer
6. Prevent a fan-lock condition when the program thinks CPU temperature cannot be read correctly and forces all fans to maximum all of the time
7. Remove program dependencies that do not provide the proper information in Ubuntu, such as **sysctl**
8. Check for program dependencies and fail gracefully when missing
9. Automate hard drive device identification
10. Intelligently excludes non-peripheral devices from temperature data collection
11. Improved support for disk device changes (hot-swapped, failed/removed, added disk devices)
12. Added support for multi-CPU motherboards (up to 4 physical sockets)
13. Prevent program crash when no hard drives exist
14. Removed obsolete or redundant code
15. Automatic fan speed detection: automatically determine CPU and HDD fan speed min/max limits
16. Automatic fan header detection
17. Automated fan zone identification
18. Added support for configuration settings defined in separate config file
19. Stubbed for future support of other motherboard manufacturers and models
20. Rapid-start initialization option that stores static information about the server between reboots
21. Most program functions now handled by functions. This makes it easier to follow order-of-operations, make modifications, and perform troubleshooting
# Prior Art

The original concept that eventually led to the creation of the alpha (0.1) version of my PID Fan Controller came from aspirations I garnered through reviewing more primitive concepts developed by other people and posted publicly in the NAS forum.

While the oldest reference I could find on the [TrueNAS Community forum](https://www.truenas.com/community/) was credited to a user with the handle of "Stux," Kevin Horton is generally regarded as the person on the NAS forum who first made a concerted effort to turn Stux's ideas into a more user-friendly application, developing a more robust fan control script written in Perl. 

Kevin and Stux both now have shared their code more readily via public GitHub repositories (see below for links).

Another influencer for me was the user "PigLover" on the [ServeTheHome forum](https://forums.servethehome.com/), a valuable source of information for people interested in operating a [home lab](https://linuxhandbook.com/homelab/).

## Unknown Authors
Changes to Kevin Horton's work by unknown authors, shared via the [TrueNAS Community forum](https://www.truenas.com/community/).

- 2017-01-29
	- Add header to log file every X hours
- 2017-01-21
	- Refactored code to bump up CPU fan to help cool HD
	- Drop variable CPU duty cycle, and just set to High
	- Added log file option without temps for every HD
- 2017-01-18
	- Added log file

## Kevin Horton
- 2019-03-15
	- Kevin's script updated and tested on Supermicro X10 motherboard
	- Presumed compatibility on Supermicro X11 boards
	- Presumed incompatibility on previous generation Supermicro boards
- 2017-09-04
	- Code project [migrated to GitHub](https://github.com/khorton/nas_fan_control)
- 2017-01-14
	- Reworked get_device_list() to exclude SSDs
	- Added function to calculate maximum and average HD temperatures
	- Replaced original HD fan control scheme with a PID controller, controlling the average HD temp
	- Added safety override if any HD reaches a specified max temperature.  If so, the PID loop is overridden, and HD fans are set to maximum speed
	- Retain float value of fan duty cycle between loop cycles, so that small duty cycle corrections accumulate and eventually push duty cycle to the next integer value
- 2016-10-07
	- Replaced get_cpu_temp() function with get_cpu_temp() which queries the kernel, instead of IPMI
	- Faster, more accurate and more compatible, hopefully allowing this to work on X9 systems
	- Original function still present and renamed get_cpu_temp_ipmi()
	- Found  previous cpu_temp_override of 60 too sensitive and caused override frequently; bumped cpu_temp_override to 62
	- If a CPU core reaches 62C, the HD fans will kick in, generally bringing temps down to around 60C (depending on actual load)
	- For best results tune controller with mprime testing at various thread levels
	- Updated CPU threasholds to 35/45/55 due to improved responsiveness of get_cpu_temp function
- 2016-09-26
	- device_list now refreshed before checking HD temps to start/stop monitoring hot inserted/removed devices
	- "Drives are warm, going to 75%" log message was missing an 'unless' clause, causing it to print every time
- 2016-09-19
	- Added cpu_temp_override, to prevent HD fans cycling when CPU fans are sufficient for cooling CPU
- 2016-09-19
	- Initial versioned release
- 2016-02-08
	- Idea floated on TrueNAS forums, alpha code shared

## "Stux"
Work created by the [TrueNAS Community forum](https://www.truenas.com/community/) user named "Stux."

- 2024-03-15
	- Ported controller to SCALE and created a [GitHub repository](https://github.com/mrstux/hybrid_fan_control)
- 2016-09-15
	- Initial versioned release
- 2016-08-16
	- Shared modified version of Kevin Horton's original Perl script on TrueNAS forum

## "PigLover"
Research performed and shared by user named, "PigLover" [Serve The Home](https://forums.servethehome.com/index.php)'s forum. 

- 2016-05-30
	- Initial release

## Peter Sulyok
- smfc
	- https://github.com/petersulyok/smfc
