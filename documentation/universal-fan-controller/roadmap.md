# Future Release Roadmap
Non-prioritized order. This is frankly more of a wishlist than a roadmap at the moment.

## Priorities
1. Maintenance updates
2. Feature improvements
3. Tech debt

## Maintenance
Monitor bug reports and project tracking for known maintenance issues pending resolution.

## Future Feature Improvements
Features identified as worthy of spending time on improving UFC should also be tracked under the UFC GitHub project.

Support for SSDs and mixed-form factor disk arrays is planned, but not yet designed or developed.

Managing mixed HDD and SSD configurations is complex. It requires advanced algorithms, which UFC does not yet support. As SSDs are generally designed to run hotter than HDDs, deriving a simple target temperature goal is virtually impossible if a disk array contains a mixture of disk types.

Comprehensive SSD and PCIe/NVMe based storage device support is [planned for future development](roadmap.md).


1. Support mixed storage device types in the same data storage ecosystem (see [Functional Limitations](program-requirements.md#functional-limitations))
2. Add the ability to isolate speed change commands to individual fans for 'group' method boards (such as most ASRock Rack motherboards).
    - Add an option for 'group' fan control method
    - When only a single fan needs adjustment, come up with a simple method of knowing all pre-existing fan header levels without needing to read them or run calculations to determine them.
    - For example, keep a record in an array of all current fan header settings so that it's easier and faster to call fan speed updates by a single fan at a time.
    - Watch out for repetitive and redundant fan speed change calls. If more than one fan needs changing at the same time, the program should consolidate them into a single IPMI command.
    - Also make sure not to try and set any speed other than actual current speed for any excluded fan.
3. Support for [OpenBMC](https://github.com/openbmc/docs/blob/master/README.md) as an alternative to **ipmitool** 

## Technical Debt
Stuff that should be done. Not necessarily defects, but improvements that will promote the longevity of the UFC concept.

### Make POSIX Great Again
- Make all include files POSIX compliant
