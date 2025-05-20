# Bibliography of Influential Individuals
People who have pioneered related projects, from whom I may have taken inspiration from their ideas, designs, or concepts. I have spent many, many hours perusing forums and blog sites for information and wanted to be certain that I recognized people who stood out with regards to sharing relevant information publicly.

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

## Peter Sulyok
- smfc
	- https://github.com/petersulyok/smfc

## "PigLover" (Serve The Home)
Research performed and shared by user named, "PigLover" via the [Serve The Home](https://forums.servethehome.com/index.php) forum.

- 2016-05-30
	- Initial release

## "Stux" (TrueNAS)
Work created by the [TrueNAS Community forum](https://www.truenas.com/community/) user named "Stux."

- 2024-03-15
	- Ported controller to SCALE and created a [GitHub repository](https://github.com/mrstux/hybrid_fan_control)
- 2016-09-15
	- Initial versioned release
- 2016-08-16
	- Shared modified version of Kevin Horton's original Perl script on TrueNAS forum
