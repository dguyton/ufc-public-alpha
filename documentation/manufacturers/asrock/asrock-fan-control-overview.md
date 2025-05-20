AsRock Rack (server) motherboards are an interesting beast. There are some nuances about them that can make them very appealing from a fan controller perspective. However, tweaking them can be a time-consuming challenge.

## Most Important Points When Addressing Fan Headers
1. Fan headers can only be addressed in sequence (by position in the IPMI command payload). Sending a speed change command to one fan necessitates sending a similar command to ALL fan headers at the same time. This means if you don't want to change the speed for all fans at the same time, you must know the current speed of the fans you don't wish to alter, and explicitly instruct the board to set those fans to the same speed they're already at.
2. The fan headers don't have names as far as the IPMI is concerned. Just a placeholder (X of 16 numbered from position 0-15). You'll see fan header IDs output in IPMI output (e.g. upper/lower fan speed thresholds or current fan speed), however these don't always correlate to each fan's position when the fan is called via IPMI commands.
3. To change the speed of a given fan, you must know the fan's order in the sequence. Each fan header has a placeholder position. When you want to make a change only to fan X, you need to know its position in the list. To add insult to injury, there is no common table of fan header names to fan header positions for any given fan header. This means trial-and-error to figure out the sequence unless you already know this information from a reliable source.

> [!WARNING]
> Be careful when cross-referencing fan header names between IPMI and the motherboard.
>
> Motherboard have fan header names engrained onto the board itself. These may differ from fan header names displayed in IPMI output.

## Additional Details
1. Fan headers can be addressed and controlled individually, however when doing so via IPMI most boards require addressing all fan headers simultaneously.
2. Fan header labels imprinted on the motherboard may not coincide exactly with IPMI reported fan header names/IDs.
3. Fans cannot be addressed in the IPMI by name/ID.
4. Every fan header has a placeholder to the BMC. There are a total of 16 placeholders.
5. There may be fan controls available only via a web browser interface to the BMC that allow additional controls, such as adjusting custom fan curves, graduated temperature ramp-ups/ramp-downs based on time and/or temperature, or how long of a polling or grace period is required of a particular temperature before the fan controller reacts. Such features cannot be automated via a script.
6. Zero (0) as a fan speed assignment via IPMI manual fan control will usually cause the fan to be set to automatic control rather than assigning a speed of 0% PWM.
7. Minimum manual fan speed may be 1%, 4%, or another higher value. Most modern ASRock boards enforce a minimum speed of 4%, but there is quite a bit of variation by model.
8. AsRock Rack boards use either 4 or 6-pin fan headers. Some boards have a combination of both types. The 6-pin headers are simply variants of the 4-pin style with additional sensor and control wires. 6-pin fan headers are backward-compatible, so if you plug a standard 4-pin PWM fan into one, it should work just fine.
9. AsRock boards do not support voltage manipulation, meaning 3-pin fan speeds cannot be adjusted. They will always run at 100% fan speed.
10. AsRock fan header naming methodology across motherboards varies dramatically, but is normally consistent within a class or group of similar motherboard models.
11. Most ASRock boards have 16 fan position placeholders. You need to specify a value for each, even if no fan exists in that position. WHen that is true, set its speed value to zero (0x00).
