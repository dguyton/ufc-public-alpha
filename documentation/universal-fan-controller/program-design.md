# Program Architecture and Design
This article describes the Universal Fan Controller's (UFC) system architecture and design philosophy.

The Universal Fan Controller (UFC) is a cooling fan management utility designed for server-based motherboards operating in a server chassis. As most such computing systems are rack-mounted, this means that frequently there is a dual mandate to prioritize both proper system cooling and maintaining a reasonable acoustic level. The latter is of particular concern to Home Lab enthusiasts or similar environments where the server(s) may be in close proximity to normal human activities. The UFC exists to satisfy these priorities, which tend to conflict with one another, thus necessitating an effort toward active fan management.

## Modular Design
UFC incorporates a modular design philosophy. Its system design consisting of the following components:
1. Core programs
2. Multi-layered configuration files
3. Supportive functions (code subroutines)
4. Global variable declarations
5. Dynamic variable creation

## Three-Part Process: Configure, Launch, Run
The Universal Fan Controller (UFC) is actually three programs. 
1. Builder: Validation, system inventory, configuration, and prep.
2. Service Launcher: Launch executable triggered on server start-up. Validates the environment and launches the Runtime program.
3. Service Runtime: Runtime executable that is the workhorse and contains the PID fan controller utility.

Originally developed as a single runtime executable, as of version 2 UFC was renamed and split into three distinct portions in order to reduce the memory footprint and initialization time of the runtime portion, which has been carved out to operate as an independent executable. It was also determined during testing that certain functions only need to be run once to establish static benchmarks regarding the system hardware, and therefore retaining this portion of the code indefinitely was inefficient.

Inventory and configuration is performed first. It only needs to be run once, and whenever you wish to change the parameters included in the initialization (.init) file imported by the Launcher program. The Launcher performs minimal validation to ensure the environment has not changed substantially since the last time the first program (known as the "Builder") was run. If a significant change is detected, the Launcher will not launch the Runtime program, and will instead exit gracefully, including notifying the end user they need to re-run the Builder and/or examine the current system state.

The Launcher and Runtime programs are run in the background as _systemd_ daemon services.

## Building Blocks
One may think of the relationship between the three core modules as a building-block concept. The Runtime program cannot run without the Launcher, which cannot run without the Builder. The Builder kicks off the whole process. The Launcher and Runtime are the "UFC service" executables triggered when the server boots.

### Program Modules
There are four program modules that work together to operate UFC:
1. Builder (program)
2. Launcher (service daemon)
3. Runtime (service daemon)
4. Failure Notification Handler (service daemon)

### Modular Block Design Concepts
UFC approaches certain operational processes from a modular perspective as well. Many program functions are handled in a modular fashion, allowing end users to customize the program flow to some extent, including:
- [BMC fan schemas](/documentation/universal-fan-controller/details/bmc-fan-schemas.md)
  - Declared in config files
  - Allow customized sets of IPMI raw commands particular to a given motherboard or manufacturer
- Flexible and user-defined fan groupings by fan cooling type

## Core Programs Overview
Core functionality is driven by three distinct, purpose-built modules:
1. Builder
   - Setup and configuration management
   - Sets up and configures the Launcher
   - Validates and copies program files and libraries
   - Run manually from command line
2. Launcher
   - Validate operating environment, launch runtime program
   - Triggered on system start-up
   - Configures Runtime program parameters
   - Launches the Runtime program
3. Runtime
   - Operational workhorse
   - Requires .init file created by the Launcher
   - Runs continuously in the background until system shutdown

---

## The Builder
The "Builder" or "Builder program" is a stand-alone program module that sets up and initializes the programs which are the actual workhorse. UFC eschews the traditional approach of a single fan controlling program in favor of a modular approach for several reasons.
1. UFC supports multiple motherboard manufacturers.
2. Manufacturers have multiple models, with differing operational characteristics.
3. Promotes a small runtime footprint, in conjunction with broad product support.

### Single-Shot Setup
The Builder is a single-shot setup and configuration program module. This means it runs just once, during which it configures the Service Launcher and Runtime programs. The Launcher and Runtime are executables that run everytime the server starts up. Meanwhile, the Builder is only ever run in order to configure or reconfigure the Launcher's configuration file.

### The Builder's Role
The Builder orchestrates the entire program setup. It is responsible for the following:
1. Hardware analysis
2. UFC compatibility screening
3. Creating the Launcher initialization (.init) file (essentially a configuration file for the Launcher)
4. Copying files required for the Launcher and Runtime programs
5. Copying include file libraries
6. Validating the Launcher and Runtime programs, daemons, and include file libraries
7. Configuring the Launcher daemon

## The Service Launcher
The *Launcher* is a daemonized BaSH script. Run in the background as a **systemd** service, the Launcher validates and configures the Runtime program. The Launcher is started automatically when the server starts (boots up). It performs various validations, and if everything looks good it launches the Runtime program.

### Role
The Launcher has two primary responsibilities:

1. Analyze the current server environment
2. Prep and launch the Runtime program

The Launcher runs during the post-boot server start-up sequence. It views the current system fans from a point of low dependency (inventory) to highest dependency (active zones). It must evaluate the current state of all fans in the server, cope with unexpected environmental changes, and make a final go/no-go decision of whether or not to launch the Runtime program.

Using the configuration provided by the Builder, it must ascertain whether or not the server's current state of fans aligns with what it expects based on the Builder-provided schema. The Launcher must determine if adjustments are necessary when the current state of fan headers is not consistent with the expected state (gleaned from in its .init file created previously by the Builder), and make those adjustments. Alternately, the Launcher may determine the current server state is too far off the rails from what is expected, and abort the entire process.

### Tasks
The Launcher is responsible for the following tasks:

1. Validate (Launcher) .init file created by Builder
2. Enable Failure Notification Handler (FNH) service daemon
3. Validate Runtime program file, include files
4. Process Launcher program log when requested
4. Test and configure Runtime program log when requested
5. Test and configure JSON metadata log when requested
6. Validate hardware monitoring programs (e.g. hddtemp, smartctl, etc.)
7. Inventory data storage device list
8. Validate fan speed threshold settings
9. Initialize fan headers
10. Validate fan group/zone configurations
11. Enable manual fan controls
12. Poll fan headers and establish benchmarks
13. Create Runtime unique .init file (new file created on each system boot)
14. Close Launcher program log file (if requested)
15. Send email notification to end user when Runtime is started successfully

## The Service Runtime Script
The *Runtime* program is a daemonized BaSH script that runs continuously as a systemd service daemon. It is the real workhorse behind UFC. The other program modules (Builder and Launcher) exist to quantify the parameters of the Runtime program. This allows the Runtime program to take up as small of a footprint as possible in system memory. Since it is run constantly in the background, it is important that it be as compact as possible while still running in memory. Although it would be possible to make it even smaller by running many of its functions from disk, a design decision was made to not do this for several reasons. Notably, running it in memory prevents potential issues such as a disk drive failing. Given the importance of the Runtime program's responsibilities of cooling the CPU(s) and disk storage devices, it is prudent to make its operation as foolproof and redundant as possible.

The Runtime program manages the following tasks:
1. Monitoring CPU temperatures
2. Monitoring disk device temperatures
3. Monitoring fan health
4. Writing program and/or metadata logs as requested
5. Real-time [P.I.D.](pid-explained.md) algorithm

---

## Configuration Files
The use of configuration files is an important characteristic of how UFC operates. It depends on these config files to establish critical operating parameters, as these factors vary from motherboard to motherboard, and in some cases by manufacturer. The use of configuration files improves the flexibility of UFC and its ability to accomodate server motherboards from many different manufacturers.

UFC utilizes four types of configuration files:
1. Nested, static motherboard-specific configuration files used by the Builder
2. Dynamic runtime program configuration (rebuilt on every system start-up)
3. User-defined Builder (setup program) configuration file
4. Launcher configuration file produced dynamically by Builder

### Builder Config Stacking Rules
The Builder related configuration files are loaded in a specific sequence, following this hierarchy:
1. Motherboard manufacturer config (when exists)
2. Motherboard model config (when exists)
3. User-defined, version-specific Builder program config file

Subsequent config file loads may override previously loaded parameters. Highest priority is given to the last config file loaded. This allows the end user to override default settings if desired. Thus, if more than one configuration file contains the same parameter, the most recently loaded value wins.

### Nested Motherboard Config Files
Base configuration files are organized by motherboard manufacturer and motherboard model.

The file system directory layout is:
- Manufacturer-specific level configuration: `/config/manufacturer/manufacturer.conf`
- Motherboard model-specific configuration: `/config/manufacturer/model.conf`
- User-defined Builder config file: `/config/{program name & version specific filename}.conf`

Motherboard-level configuration files define various important incumbent settings. One of the most important is the _BMC fan schema_, which indicates to UFC the default IPMI command structure understood by the motherboard. More details on this topic may be found [here](/documentation/universal-fan-controller/details/bmc-fan-schemas.md).

---

## Importing Support Files
The modular design of the project architecture extends to the use of a substantial number of supporting files. In order to make maintenance of the core programs a bit more manageable, most subroutines (functions) are imported by each core program (Builder, Service Launcher, Service Runtime program) on an as-needed basis. These subroutines are segmented based on one of these use cases:
1. Global variable declarations
2. Configuration files
   - User defined environmental parameters and overrides
   - Manufacturer specific
   - Motherboard model specific
3. Initialization files (Service programs only)
4. Dedicated subroutines (functions)
5. Shared subroutines

### Include File Libraries
Most subroutines (functions) are imported by each core program on an as-needed basis. This process exists for several reasons:
1. Limit code length of each core program (Builder, Service Launcher, Service Runtime program)
2. Reduce maintenance overhead
3. Improve efficiency through sharing common code between modules

Most include files contain a single subroutine and are organized based on which module requires them:
1. Builder-only functions
2. Service-only functions (required by Launcher and/or Runtime)
3. Common or shared functions (needed by the Builder and one or more of the Service programs)

---

## Global Variable Declarations
Global variables are declared through three different methods, depending on when and how the variable is utilized by each core program.

1. Global variables necessary for program operation or otherwise utilized prior to when the core program imports its include files.
2. Global variables not required by a core program until _after_ its include files have loaded.
3. Variables that can be created dynamically.

Most variables of each program are created via their respective _global declarations file_. This process is part of UFC's modular design. The easiest way to add a new global variable is via this file, respective of which program needs the new variable. This makes managing most of the long list of variables in each program more straightforward.

The universe of global variables declared in each core program is kept to a minimum. Only the variables required - those that cannot be imported before they are needed - are hard-coded in each core program file.

---

### Dynamic Variable Creation
A small number of variables are created dynamically. The primary reason to do this is because a group of related variables are needed, but their exact names cannot be known ahead of time.

An example of this is the set of variables related to the fan header and fan zone binary tracking strings. These are critical global variables. The reason they are created dynamically is because another variable - the array `$fan_header_category[]` defines the universe of fan duty category names. This array define the fan header and fan zone category names. This information is used to generate prefixes for the fan header and fan zone binary trackers.

Thus, in this example the dynamic input - the `fan_header_category` array - is specified by the user in the Builder config file. The array is then parsed by the Builder, and a series of related global variables are created dynamically based on the input from the config file. The user's input acts as a group of keys which form prefixes, resulting in complete new and dynamically created global variables. These global variables are later passed on to the Service programs via their respective .init files.

---

## Failsafes and Redundancy
Obviously, when a program is responsible for critical management of a server, it's wise to consider how the design of said program impacts its resistance to failure. What happens if the program fails? How robust is it (i.e. likely or unlikely to fail)?

UFC incorporates numerous safeguards to prevent the possibility that a server ecosystem could be exposed to an unmanaged fan control environment. It incorporates the following measures to prevent this from ever happening:
1. Validation checks in every module. On start-up, if a module finds a core component missing it will abort the process and exit.
2. Traps setup to trigger exit code blocks in the event of an unexpected catastrophic program failure.
3. Multiple exit code blocks with differing strategies that trigger based on system state on exit.

### Distinctive Exit Handling
There are five (5) possible sudden program exit scenarios that apply to all of the program modules (except for FNH):
1. Trap on signal
2. Trap on program exit
3. Controlled exit with no action
4. Controlled exit with fans full
5. Controlled exit with optimal fan mode

#### 1. Trap on Signal
This exit is relatively rare. It occurs when an unplanned program exit triggers a hardware interrupt signal. The expecation is this exit type would be triggered by something outside the program's control.

Actions:
1. Send email to user (if option enabled)
2. Exit with no further action

#### 2. Trap on Program Exit
Occurs when a condition is identified that prevents the program from continuing. This is usually caused by a missing file or missing supportive program. The exit action triggers a specific interrupt signal, which in turn triggers the exit code. The expecation is this exit type will be triggered when a required dependency is missing, and it is beyond the program's control to correct the error condition. For example, if the `ipmitool` command is not found or a required file is missing.

Actions:
1. Send email to user (if option enabled)
2. Exit with no further action

#### 3. Controlled Exit - No Action Taken
Occurs when a condition is identified that prevents the program from continuing. This is usually caused when the program determines that it cannot continue due to some sort of incongruency. For example, a valid .init file is analyzed and is found to contain metadata outside the range of what the program expects. This is a graceful exit that occurs before fan control has been initiated. The intent is to return the system to its natural state of automated BIOS or BMC fan control. Since UFC has not yet taken over the fans, this should be the default fan control state on exit.

Actions:
1. Send email to user (if option enabled)
2. Close log
3. Exit with no further action

#### 4. Controlled Exit with Fans Full
This controlled exit mode is implemented when the program exits due to a failure condition after the program has already taken control of the fans. It is normally invoked either when the proper current fan state is unknown and/or the program suspects the possibility of a hardware failure, fan failure, or another urgent condition. As a safety precaution, the fans are set to full speed as the exit code is run.

Actions:
1. Send email to user (if option enabled)
2. Close log
3. Set all fans to full speed
4. Exit

#### 5. Controlled Exit with Optimal Fan Mode
This controlled exit mode is implemented when the program exits due to a failure condition after the program has already taken control of the fans and the program believes the server ecosystem is currently in a stable or non-stressed condition. Fans are set to "optimal" mode on exit when possible. When no optimal mode or equivalent exists, a controlled exit with no action is triggered.

Actions:
1. Send email to user (if option enabled)
2. Close log
3. Set all fans to 'optimal' speed mode (if available)
4. Exit

---

## Code Optimization
UFC uses a number of code optimization techniques, some of which may appear unorthodox to others. The purpose of this section is to briefly highlight these decisions and explain UFC's design philosophy.

### Variable Normalization
Users should not need to be concerned with exact syntax when entering user-declared values, such as in configuration files. Therefore, UFC attempts to normalize these inputs in an effort to eliminate the potential of a user to enter information that could potentially lead to unexpected or undesirable program behavior. Minor differences in syntax usage should not cause a program to fail or otherwise perform unexpectedly.

Two areas primarily come to mind in this regard:
1. User-declared variable/parameter value syntax (e.g. handling `=TRUE` vs. `=true` vs. `=True` as the same input value).
2. Numeric variables where an integer is expected, yet a user could enter an unexpected value such as null, floating point number, or alphanumeric characters.

UFC must be robust enough to handle such discrepancies, while also intelligent enough to correctly determine when it is safe to surmise the user's intent when their input is vague, versus when it should be ignored or flagged as a critical error. Substantial pre-filtering steps are thus employed in UFC's core programs and functions (include files) to guard against such potential points of failure.

A related goal is to reduce the amount of comparison and filtering logic required to correctly handle A/B decisions dependent on user-declared variables.

The greatest concern in terms of normalizing values pertains to user-declared values in the Builder configuration file. While UFC has no direct user inputs (e.g. via keyboard), the syntax of all variable declarations in the Builder configuration file, as well as the manufacturer and motherboard model config files, is at the mercy of the end user. This means consistency with regards to input values cannot be guaranteed, and thus must be accounted for when processing what are essentially input values for the UFC programs.

Focus areas for data input normalization:
1. True/False inputs are normalized to lowercase `true` or `false` values (always lowercase).
2. Fan header names are normalized to UPPERCASE values because this is how most BMC's present fan header names.
3. Most alphanumeric variables are normalized to lowercase only, in order to reduce the complexity required in comparison operations.
4. Under a few circumstances, alphanumeric variables may require UPPERCASE values for comparison operations. These are particular, known circumstances, and are not the norm.
5. In many cases, null values are a detriment to filtering. Under such circumstances, a `{null}` value is converted to a default value aligned with expectations for the filter scenario.
6. Missing values for variables required to be numeric are usually converted to 0 to prevent issues with integer processing.

### No 'elseif' Statements
There are no `elif` or `elseif` statements in UFC's code. Although supported in BaSH, this practice is not supported by all SHell compilers. Therefore, its use is not practiced in UFC's code. Why? UFC endeavours to be [mostly POSIX compliant](/documentation/details/posix-support.md).

As an alternative, UFC uses a more verbose `IF/THEN/ELSE/IF` style. While refusing to use the `elseif` branching technique leads to less efficient coding, it makes the compartmentalization of logic easier to follow for the most part, while saving labor for users who wish to port the code to SHell compiler variants that do not support it.

### Non-POSIX Cheat Codes
While a long-term goal of UFC is to make it fully POSIX compliant (see UFC's [future roadmap](roadmap.md)), the path there is not a straight one. A choice was made to use certain features of BaSH that were beneficial to get all of the program logic nailed down in version 2.

#### Variable Indirection
[Variable indirection]() in BaSH allows dynamic variable name handling.

```
foo="hello"
ref="foo"
echo "${!ref}"  # outputs "hello"
```

#### nameref
[_nameref_](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-declare) - introduced in BaSH version 4.3 - makes a variable a _name reference_ to another variable.

Also known as, "indirect assignment," is a technique unique to BaSH that allows the dynamic reading and writing of variable values by referencing the name of one variable through another. The concept can become confusing. Therefore, it is best utilized in a limited fashion for the most part. However, it can be very useful under certain circumstances, such as when the name of a variable expected to contain some value of importance is not known ahead of time, but the name of that variable can be determined dynamically. By passing the name of the dynamic target variable name to a chunk of code expecting this variable state, it is possible to write code that acts on the real variable value without knowing the real variable name ahead of time.

Usage: `declare -n pointer`

Example:
```
var1="hello"
declare -n var2="var1"   # treat $var2 as if it were $var1
echo "$var2"   # outputs "hello" (value of $var1)
var2="world"   # sets the value to "world" of the variable name referenced by $var2 (i.e. assigns value to $var1)
echo "$var1"   # now outputs "world"
```

Breakdown:
1. declare -n var2="var1": Creates `var2` as a nameref to var1. Anything you do to var2 affects var1 directly.
2. var2="world" does not assign "world" to a variable named var2 - it assigns it to var1.
3. In other words, the pointer variable's (var2) value is always equal to the value of the variable pointed to by the variable name assigned as its value (var1). Thus, if var2 is read, it is always equal to the value of var1 since var2 is redirected (or indirectly points) to var1's value.

All references, assignments, and attribute modifications to `var2`, except for those using or changing the -n attribute itself, are performed on the variable referenced by name’s value (`var1`). 

> [!TIP]
> The _nameref_ attribute cannot be applied to array variables.

Note the distinction between [variable indirection](#variable-indirection) and _nameref_. The former is similar to the latter from a read perspective. If your use case calls for a one-time need for redirection, then variable indirection is typically ideal. However, if read/write capabilities are required, then _nameref_ would be used. Likewise, if there is a permanent need for variable indirection, _nameref_ may be a superior choice.

#### Parameter Expansion
BaSH also has some very useful [parameter expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html) techniques, some of which are used extensively in the code.

### Coding Defensively
It is wise to code defensively in BaSH. The following practices adhere to this philosophy, even though they may technically be unnecessary at times.
- Always quoting variable declarations except when it can assign an incorrect value (rare circumstances)
- Always quoting string variable values
- No use of the `eval` command

---

## Fan Header Metadata as Canonical Source
<<>>

---

## Program Documentation
Some design choices in UFC's code may seem redundant to some people, but these are purposeful and conscious choices.

### Verbose Comments
Each core program is replete with verbose comments describing program behaviors. Include files (functions/subroutines) have varying levels of comment verbosity, but most contain fairly verbose comments.

### Nested Level Notation
You will find every IF/THEN statement pairs are commented with their depth level.

Like this for IF/THEN statements:

```
		if [ "$var_1" -gt "$var_2" ]; then # 2/
         ...
         ...
		fi # 2/
```

And this for CASE statements:

```
		case "$var_1" in # 1/
         value_1)
            ...
         ;;
      esac # 1/
```

> [!NOTE]
> Even non-nested (single layer) statements are commented in this fashion for consistency.

This coding practice applies to  `if/then/else`, `case/esac`, and `do/done` statements.

#### Design Decision Reasoning
1. There are numerous deep nests of IF/THEN/ELSE and CASE statements throughout UFC's code. This indexing system makes it easier to follow the code.
2. Aides troubleshooting, such as when a compiler error indicates an open statement (for example, due to a missing `then` or `esac` statement).
3. When inserting new code, it is easier to see which neighboring sections will be impacted.

Naturally, these could have been removed after the primary dev phase in order to de-clutter the code, but as you can see if you read through the code, it is very verbose by design. Either way, in the author's opinion the pros outweight the cons in favor of leaving them in.

---

## Future Proofing
Some program design elements are intended as a sort of "future proofing" of various aspects of the programs. For example, `$fan_id` is quoted even though as it is an integer, this should be unncessary. The reason it is still quoted (as `"$fan_id"`) is to make it easier to modify the programs to use an alphanumeric based fan ID system versus a strictly numeric based model. While this would not obviate any code changes, it would reduce the technical debt for anyone seeking to make such a modification in the future.
