# Binary Strings
One of the most important design factors in the Universal Fan Controller (UFC) is its _"binary"_ strings. This is a made-up term used which refers to a global text string variable that is used to track the status of a group of objects where UFC needs to track a distinctive True/False flag state for each object in the group. For example, imagine there is a binary string used to track the status of which fan headers on a motherboard have an active fan and which do not. By assigning a position to each fan header, a state can be recorded for each of `1` (true or yes there is a fan there) or `0` (false or no fan is there) for each fan header position. Then, as long as there is a consistent way of mapping which fan header position is aligned with which byte position in the string, we can use this "binary" string to keep track of all the fan states.

Naturally, this task could also be accomplished with an array. However, the use of a fixed length string allows a smaller memory footprint, and can also potentially be a bit easier under some circumstances to keep track of the state of whatever object type is being tracked. Either way, it's simply a method of keeping track of things, and it is a method employed in several different ways by the UFC.

This method is used to keep track of much of the most important details that UFC needs to track in realtime.

## Why They're Called "Binary" Strings
The binary strings contain only 1's and 0's - thus representing binary notation - where `0` = false (not present) and `1` = true (is present, or does exist). This explains why they are called "binary" strings.

The string bytes are evaluated in order, such that the first byte in the string (byte 0) represents Fan ID 0 or Fan Zone ID 0, depending on which binary string is examined. A value of 0 in any given byte position always indicates that for that particular ID position, an associated object does not exist or is disabled/turned off. For example, if a motherboard has fan zones 0, 1, and 3 established as valid logical fan zones, then the 0, 1, and 3 byte values for the fan zone binary tracker would be set by the Builder program such that byte positions 0, 1, and 3 will all = 1, while all other byte positions would be set = 0. Continuing with this thought process, imagine the fan zone binary string can track a maximum of 8 fan zone IDs. The string as described would look like this:

```
fan_zone_binary="11010000"
```

## Low-bit (Position) Starts on the Left
Note the position of the `1` (on/active) flags for fan zones 0, 1, and 3, and that those bytes are on the far LEFT side of the string.

It's important to clarify this point because users may expect binary values to start on either the left or right side of a string, depending on their familiarity with binary value representation, which can vary by operating system.

## Ordinal Position Significance
You will see references throughout the core programs' code and within the UFC documentation discussing binaries and ordinals. Now that the concept of _binaries_ has been described, what are these _ordinals_?

Ordinals are a type of number that indicates the position or rank of an object in a sequence, such as first, second, or third. It is used to describe the order of items rather than their quantity. They are - in a sense - the indeces of the binary strings. An _ordinal_ simply refers to the position of an object within a binary string to which it belongs. For example, within a fan header-related binary, Fan ID 0 will be the first ordinal, which may also be referred to as "ordinal 0" or "position 0" in the code or documentation. 

> Many of these terms are used interchangeably within the code comments and this documentation.
>
> Hopefully, it does not come across as confusing, as the concepts are actually rather straight-forward.
>
> "Bits", "Ordinals", and "Positions" all essentially refer to the same thing: the position of a particular object identifier within its associated binary string that is tracking the object type.

Most binaries track fan headers in some capacity. These may be existing fan headers, active fans, excluded fans, etc., but they're usually referring to fan headers and fan header positions.

### Determining Ordinal Position within Binary Strings
Now that we've established what binaries and ordinals are, how they work together, and what various terms mean, an explanation is in order with regards to how binary/byte positions or ordinals are determined.

As previously mentioned, the binary strings have a finite length, determined by physical or logical limitations related to either the physical motherboard's characteristics or limitations of the Baseboard Management Controller (BMC) itself (i.e., logical limiters). Binary string length is correlated with the maximum possible number of each object type. There may be less than this number of each object type available, but there cannot be more. The Builder config file caps binary string lengths with distinct limits for fan header versus fan zone trackers, with default values of 16 and 8 respectively.

Ordinals are ordered based on _read order_. In other words, the order in which information is read by a tool or application used to populate a binary with information (e.g. the **lm-sensors** program) determines the relationship between binary string ordinals and its related objects. For example, if fan status is read, the first row of fan header information might be considered to be "Fan position 0" and therefore "ordinal 0 (zero)." Then, sequentially read objects are assigned consecutive ordinal positions based on their position in the data feed. The first series of read data determines the characteristics of the ordinal position 0 within a binary string. The second determines ordinal 1, and so on.

Additional context may be found in [Sensor Monitoring](/documentation/universal-fan-controller//documentation/details/sensor-monitoring.md).

## Examples
Several variables represent every physical fan header and fan zone (respectively) via binary true/false switches for each. Each character in the string represents a single physical fan header or fan zone, and acts as a placeholder and presence indicator. The values represent physical (fan header) or logical (fan zone) states.

These variables may be found in the global variable declarations files. The use for each variable is documented there.


