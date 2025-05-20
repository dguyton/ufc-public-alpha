# Supermicro Built-in Fan Control Modes
Supermicro server motherboards have either three (3) or four (4) built-in fan modes. Supermicro boards that allow manual fan speed control require the board to first be set to a specific _fan mode_, which varies by model. There are 3 or 4 levels of speed control - again depending on the motherboard model - though they are largely consistent across the same motherboard generation (e.g., X9, X10, etc.).

## Generation X8 Boards
|     Fan Mode     | Description                                 |
|------------------|-------------------------------------------- |
| Full Speed/FS    | All fans run at 100% constantly |
| Performance/PF   | Moderates target speed higher than Balanced between ~50-70% based on PCH temp sensors |
| Balanced/BL      | Equivalent to "Standard" setting on later gen boards (target fan speed ~50%) with some moderation based on PCH temp sensors |
| Energy Saving/ES | Equivalent to "Optimal" setting on later gen boards (target fan speed ~30%)  |

## X9 and Later Gen Boards

|  Fan Mode  | Description                                       |
|------------|-------------------------------------------------- |
| FULL       | Pretty obvious. Does exactly what it sounds like: 100% PWM all the time. |
| STANDARD   | BMC control of both fan zones, with CPU zone based on CPU temp (target speed 50%) and Peripheral zone based on PCH temp (target speed 50%). |
| OPTIMAL | 30% base PWM. Max 100%. Temperature controlled. |
| PUE OPTIMAL | Only certain boards support this mode. Think of it as the Economy version of Optimal. This mode prioritizes power consumption over performance, and will cause the motherboard to try and lower power consumption for the CPU (if capable), RAM, etc. Target fan speed is ~30% for all fans. |
| HEAVY I/O  | Standard mode (50% base PWM) for Zone 0 (FAN1) fans and 75% base PWM for Zone 1 (FANA) peripheral cooling fans. |

The fan mode can usually be set in the BIOS or via [IPMI](/documentation/lexicon.md#ipmi) , though again options to change it can vary by board model.

## Default Fan Modes
The BMC is programmed to initiate the last fan mode it was set to on boot. Factory new, the default fan mode will be either Standard or Full, and is usually set to Full mode.

When the server is booted, under some circumstances the BIOS will intervene and force the fan mode to a particular level. This could be a default level that is always the same, or there couldd be a user-configurable setting in the BIOS. The exact behavior varies by motherboard model.

## Included Motherboards
Most Supermicro motherboards from gen 8 forward are covered in this guide, though some may have missing information. Included servers must meet all of the following criteria to be included in this guide:
- Motherboard
- Server-class
- Has a BMC chip

## Excluded Motherboards
The information in this guide is focused on server-class motherboards intended for general computing purposes. Models designed to function in speciaized roles such as blade servers and GPU servers are not included. Manufacturers may refer to such boards as, "integrated solutions." Such servers are typically not intended as general computing platforms and tend to have markedly different use cases and system architecture. Although some of them do allow manual fan control capabilities, keeping track of their abilities and sharing information on how to utilize them effectively on these boards is beyond the scope of this guide.

Examples of excluded Supermicro motherboard model numbers:
- These models utilize the Nuvoton WPCM450R BMC chip. They have two (2) or three (3) fan zones and a total of 12 fan headers.
  - X9DRG-HF series
  - X9DRG-HTF series

## Enabling BMC Capabilities
Some - primarily older - Supermicro motherboards require access to the BMC (such as via IPMI) to be enabled explicitly in the BIOS. The default behavior on these motherboards is normally to block BMC access through IPMI or other similar user-facing tools. If you receive error messages or no response when attempting to process IPMI commands on a motherboard known to support them, check the BIOS settings, such as in the screenshot shown below.

![supermicro_bios_utility_bmc_enable](https://github.com/user-attachments/assets/653ba0ed-1dcb-4a23-bb2e-2b0ae92bda91)

## Miscellaneous Features
- Get list of all temperature sensors and their current status:

```ipmitool -U username -P password sdr type temp```

- List all the sensors which can be queried , including their entity ID (4th column of output):

```ipmitool -U username -P password sdr elist full```

> [!NOTE]
> Display format is {entity id}.{number} where 'number' is simply a counter for how many there are of those devices, and to identify them in order.

- Take an entity id and get a list of all sensors of this type and their current status
- For example, presume 29 = fans, to get a list of all current fans status:

```ipmitool -U username -P password sdr entity 29```
