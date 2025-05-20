# BIOS Fan Controls Preempt All Others
The BIOS always wins.

Server fan control may seem like a mystery if you don't understand how they are controlled, and the physical and logical hierarchies present on most modern server motherboards that ultimately control fan behavior.

## Physical Controls
At the physical layer, fan headers provide input and output to the fans themselves. Nearly all fan headers have 3 pins (non-PWM), 4 pins (PWM) or 6 pins (dual-PWM). The 6-pin fan headers are an amalgamation of the 4-pin (PWM) design, with shared power and ground connections.

### 6-pin Fan Header Versatility
The 6-pin design originally evolved as a more sophisticated method of controlling dual-axle fans (paired fans with opposing force to create more rapid and concentrated airflow). However, this design is increasingly applied to standard 4-pin headers. The shared power and ground pins allow system designers to be slightly more efficient with board layouts and the physical real estate of the board itself. Custom plug-in adapters may provide 8 pins worth of outputs to power and monitor two independent 4-pin fans, or two independent 3-pin fans if PWM monitoring is not a priority.

The point being, when a 6-pin fan header is observed on a motherboard, this means it controls two fans, not one. A caveat to this rule being that some motherboards treat dual-axle fans as a single fan (though this is not the norm, as doing so means an end user cannot determine when only one fan in the pair fails).

### The Fan Controller
Every motherboard with fans has a fan controller. This is hardware on the board that controls the transmission of power and communications from a physical standpoint. The fan controller is not directly accessible in any way to the end user. Typically, it is directly connected to the Baseboard Management Controller (BMC) chip. In some cases, it is also directly wired to the BIOS chip, though this is uncommon.

### BMC's Role at the Physical Layer
The BMC's presence from a physical standpoint on the board is what makes it the ultimate fan controller from a logical perspective. Since on most server motherboards, the BMC is the only device physically interacting with the fan controller, it means the BMC is effectively the ultimate arbitrator of which process is in control of fan speeds at any give time.

## Logical Controls
Here lies the heart of fan control, and whether or not manual control of a server's fans is possible or not. Where the proverbial rubber meets the road, we have the fan controller itself, at the physical layer. However, the logical controls are what actually determines the prioritization and rank of any devices or software interested in controlling the fan headers.

### BMC as Logical Controller
Most modern server motherboards have the fan controller directly connected only to the BMC, and therefore all logical controllers must talk to the BMC in order to effect a change to any fan's behavior.

### BIOS Gets First Dibs
The BIOS always has top priority for fan control. Always. There are several good reasons for this approach.
1. The BIOS chip has a direct physical connection to the BMC chip
2. On server start-up, the BIOS is the first operating system to take control. Without instruction, the fans will either spin at top speed, or do nothing (depending on the default behavior of the Fan Controller.
