# ASRock "Smart" (Automatic) Fan Control
ASPEED versions prior to AST2500 have hard-coded automatic fan temperature-based algorithms and tables. The user cannot modify them. However, beginning with the AST2500, this is possible for most ASRock Rack server boards. ASRock re-envisioned their automatic fan speed control, calling it "Smart Fan" control. Regardless of the name, this is an indicator you might be able to control the auto fan speed triggers on any given board.

## Smart Fan Mode Temperature Curve Tables
On the AST2500 BMC chip boards, it's possible to manipulate the temperature curve tables the BMC uses when fans are controlled by it automatically. The BMC contains a pair of correlated tables that together control how the BMC smart fan algorithm assigns fan duty to the fans under its (automatic) control. There is a temperature threshold level table and a fan duty table. As each temperature in the temp table is exceeded, the fan duty in the corresponding position of the fan duty table is applied to each fan under automatic control. So, when the ambient temperature rises, the BMC looks up each successive fan duty as the temperature crosses each temp threshold. And likewise when the ambient temperature is falling, it walks down the table and gradually drops the fan speeds down as each increment in the temp table is passed.

This capability _may_ be possible on AST2600 boards as well.

## Get Smart Fan Temperature Threshold Tables
To investigate this further, one may query the BMC for the current contents of the temperature table, like so:

```ipmitool raw 0x3a 0x06 0x02 0x00```

Let's breakdown the command to see what these bytes mean.
- 0x3a = fan controller
- 0x06 = read table
- 0x02 = smart fan temperature threshold table
- 0x00 = reserved header byte

> [!NOTE]
> The 4th byte is a reserved header byte. It must be included. Set it to 0x00 (zero).

The BMC response by returning 12 hexadecimal values representing temperature thresholds in Celsius. The temperatures from the Smart Fan Temperature Threshold table are in chronological order, and correlate to the fan duty thresholds in the paired Smart Fan Duty table.

For example, imagine this set of results is returned for the current temperature table:
```2d 32 37 3c 41 46 4a 4e 52 56 5a 5f```

Converting to 10-base integers:
| Row | Hex | 10-Base |
|:---:|:---:|:-------:|
| 1 | 2d | 45 °C |
| 2 | 32 | 50 °C |
| 3 | 37 | 55 °C |
| 4 | 3c | 60 °C |
| 5 | 41 | 65 °C |
| 6 | 46 | 70 °C |
| 7 | 4a | 74 °C |
| 8 | 4e | 78 °C |
| 9 | 52 | 82 °C |
| 10 | 56 | 86 °C |
| 11 | 5a | 90 °C |
| 12 | 5f | 95 °C |

### Get Smart Fan Duty Table
Retrieve the current contents of the corresponding Smart Fan Duty table:

```ipmitool raw 0x3a 0x06 0x01 0x00```

Let's breakdown the command to see what these bytes mean.
- 0x3a = fan controller
- 0x06 = read table
- 0x01 = smart fan duty table
- 0x00 = reserved header byte

The BMC responds by returning 12 hexadecimal values representing fan duty speeds expressed as PWM percentage. The fan duty levels from the table are in chronological order and correlate to the temperature thresholds in the paired Smart Fan temperature thresholds table.

For example, imagine this set of results is returned for the current fan duty table:

```14 1e 28 32 3c 46 50 5a 64 64 64 64```

Converting to 10-base integers:
| Row | Hex | 10-Base |
|:---:|:---:|:-------:|
| 1 | 14 | 20 |
| 2 | 1e | 30 |
| 3 | 28 | 40 |
| 4 | 32 | 50 |
| 5 | 3c | 60 |
| 6 | 46 | 70 |
| 7 | 50 | 80 |
| 8 | 5a | 90 |
| 9 | 64 | 100 |
| 10 | 64 | 100 |
| 11 | 64 | 100 |
| 12 | 64 | 100 |

### Putting It All Together
Combining the two tables side by side:
| Row | Temp | Fan Duty |
|:---:|:----:|:--------:|
| 1 | x2d (45 °C) | x14 (20) |
| 2 | x32 (50 °C) | x1e (30) |
| 3 | x37 (55 °C) | x28 (40) |
| 4 | x3c (60 °C) | x32 (50) |
| 5 | x41 (65 °C) | x3c (60) |
| 6 | x46 (70 °C) | x46 (70) |
| 7 | x4a (74 °C) | x50 (80) |
| 8 | x4e (78 °C) | x5a (90) |
| 9 | x52 (82 °C) | x64 (100) |
| 10 | x56 (86 °C) | x64 (100) |
| 11 | x5a (90 °C) | x64 (100) |
| 12 | x5f (95 °C) | x64 (100) |

### Set Smart Fan Temp Curve Table
These tables must be modified separately. To modify the Smart Fan temperature thresholds, use this write subcommand:

```ipmitool raw 0x3a 0x05 0x02 0x00 {temp table values...}```

Let's breakdown the command to see what these bytes mean.
- 0x3a = fan controller
- 0x05 = write table
- 0x02 = smart fan temp threshold table
- 0x00 = reserved header byte

Notice that again the 4th byte is a reserved header, which must be included and must = 0x00.

The Temp Table write command sets the temperature thresholds for each level. So, for example to set the temperature thresholds in the table to the same values shown in the "Get" example above, you would enter this command:

```
ipmitool raw 0x3a 0x05 0x02 0x00 45 50 55 60 65 70 74 78 82 86 90
```

### Set Smart Fan Duty Table
These tables must be modified separately. To modify the Smart Fan fan duty table, use its corresponding write subcommand:

```ipmitool raw 0x3a 0x05 0x01 0x00 {fan duty table values...}```

Let's breakdown the command to see what these bytes mean.
- 0x3a = fan controller
- 0x05 = write table
- 0x01 = smart fan duty table
- 0x00 = reserved header byte

To set the fan duties in the table to the same values shown in the "Get" example above, you would enter this command:

```
ipmitool raw 0x3a 0x05 0x02 0x00 14 1e 28 32 3c 46 50 5a 64 64 64 64
```
