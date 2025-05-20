# How to Create a New Fan Duty Category
This guide explains how to define new fan categories and configure fan groups for use by the Universal Fan Controller (UFC).

There are numerous 'hooks' in the core programs and subroutines that rely on consistent fan duty category usage.

The following steps are required to support a new fan category, the nuances of which are described in this guide:
1. Related variables must be [modified via the Builder configuration file](/documentation/universal-fan-controller/configuration/builder-config-file.md).
2. Various subroutines (include files) must be modified.
3. Configuration files must be modified. Depending on use case for the new fan category, this could mean modifying any of the following:
  - Motherboard manufacturer config files
  - Motherboard model config files
  - Builder config file

---

## Categories, Groups, Schemas, and Labels
The process involves creating a new fan category type, and optionally assigning fan headers to it. When desired, the assignment of fan headers to a category must be performed by selecting a group of fans to assign to the new fan category, creating a new fan group schema (or altering an existing one), and associating that fan group with the new fan category.

### Fan Duty Category (Fan Category)
A functional tag that determines which logic or control strategy should be applied to a fan group. Each fan group is assigned a category, which governs how it is managed.

<<>> pre-defined understood fan categories
<<>> we need logic in the programs and binaries in the declarations files, etc. to accomodate these

### Fan Group (Fan Group Schema)
A schema-defined list of fan header names that are grouped together. All headers in a group are controlled concurrently as a single unit.

<<>> this is arbitrary, but you set this up via one or more of the config files that get loaded
<<>> tells UFC which fan header names belong together in a group

### Fan Group Label
A human-readable name assigned to each fan group for easier reference. Labels are defined as key-value pairs, mapping fan group identifiers to their descriptive names.

<<>> arbitrary, but needs to be defined in a config file
<<>> associates a human readable label with each fan group
<<>> you can use any label you like, just no spaces or special characters

### Fan Group Category
Fan group categories are key-value pairs that associate fan groups (by label) to their associated fan duty category (fan duty category type).

<<>> (pre-defined) map of known fan header name prefixes to assigned fan duty categories
<<>> supports automation
<<>> index names need to align with real world fan header name prefixes
<<>> values need to align with known fan duty category names

> [!NOTE]
> These structures are array-based:
> - **Fan duty categories** and **Fan group labels** are associative arrays (key-value pairs)
> - **Fan group categories** and **fan group schemas** are indexed arrays (ordered lists)



| Array variable name | Array type | Index maps to | Value is |
| ------------------- | ---------- | ------------- | ------------- |
| `fan_duty_category`  | indexed | n/a | fan duty category name |
| `fan_group_schema`   | indexed | `fan_group_label` index | list of fan header names |
| `fan_group_label`    | indexed | `fan_group_schema` index | fan group label |
| `fan_group_category` | associative | `fan_group_label` value | fan duty category name |

Example:
Goal: Organize fan headers FAN1, FAN2, and FAN3 into a single fan header group, and tag them as responsible for cooling CPU 1.

- `fan_group_schema[0]="FAN1,FAN2,FAN3"` groups fan header names FAN1, FAN2, and FAN3 into _fan group schema 0_
- `fan_group_label[0]="cpu1"` _creates fan group label_ `cpu1` and _relates it to fan header schema ID_ `0`
- `fan_group_category[cpu1]="cpu"` _associates fan group label_ `cpu1` _with fan duty category_ `cpu`

<<>>

--> why doesn't fan_group_category[] be indexed and use same index id as the fan group label and fan group schema indexes?
	--> because this way we associate the fan group label to fan duty category
 	--> does this approach have an advantage or special purpose? if so, what is it?


1. fan_group_category sets up pre-established mappings between fan group labels and their fan category (purpose)
2. we don't know ahead of time what each fan group label is going to be, as it will vary between motherboards
3. the fan_group_category indexes are based on known, industry-standard fan header name prefixes
4. we don't know ahead of time which any given board will use
5. so we have a system here where the possible fan header name prefixes can be mapped out ahead of time, but we have flexibility in assigning the actual fan header names to any duty type we want to

--> but we do seem to be locking in fan header prefixes to designated fan duty categories; why? doesn't this conflict with above?
--> well, maybe. but if we do auto-name prefix fan grouping, then we need this fan_group_category map pre-defined in order to guess what fan duty category each fan header should be assigned to


--> arrays defined in config files for particular mobo
	--> fan_group_label[x] = arbitrary label name of fan group x
	--> fan_group_schema[x] = list of fan header names belonging to group x

--> fixed pre-defined arrays
	--> fan_group_category[label name] = fan duty category name ; associates label name (index) to a fan duty category (cooling function of associated fan group); [label name]=fan duty category
	--> fan_duty_category[x] = array of fan duty categories in no particular order; values are used to create binaries; [x]=name

<<>>
1. why not have fan_group_category[label name] = index id of fan_duty_category instead of fan_duty_category value name? would be easier to logic map in the code instead of having to search for matching value
2. on the other hand tho, when verifying a fan duty category exists, we need to know what the fan duty category name is and verify related things exist
3. we only run thru all this in builder when compiling the fan binary maps

<<>> potential alternative methods

1. fan_duty_category[index] = fan duty category name (no change)
2. fan_group_category[index] = fan_duty_category index where this array index = same index id as schema and label, and its value = index of the fan duty category array
3. fan_group_schema[index] = list of fan headers in group ID index (no change)
4. fan_group_label[index] = human readable label of group ID index (no change)

| `fan_duty_category`  | indexed | n/a | fan category name |
| `fan_group_schema`   | indexed | `fan_group_label` index | list of fan header names |
| `fan_group_label`    | indexed | `fan_group_schema` index | fan group label |
| `fan_group_category` | associative | `fan_group_label` value | fan duty category name |

<<>>

---> what is the current advantage of requiring the fan_group_category array to be associative and have the group labels as its indexes?
	--> we can also leverage this in automation if we need/want to auto-detect what type of category a given fan header should belong to based on its prefix name (e.g. SYS_FAN)

--> so, when is this a benefit? is it only when the fan groups are not defined? do we allow that state to begin with? is assigning the fan groups and labels optional?

---

## Fan Duty Categories
The first step in supporting a new fan duty category involves adding the capability of UFC to accept it. For example, if you wanted to establish a more granular distinction between fans associated with cooling disks versus fans associated with exhausting hot air out the rear of the server chassis. In this imaginary use case, you might be interesetd in creating a new fan category called `rear' that would identify which fans were assigned to the rear exhaust cooling function.

_Fan duty categories_ associate groups of fans with a type of cooling. For example, the default category names such are `cpu` and `device` are named for categories of fans responsible for CPU cooling and device or disk cooling, respectively. It may be easier to think of these categories as "CPU related" versus "not CPU related" as these category names support two distinct goals in UFC's architecture:
1. Prioritizing CPU cooling above all other goals; and
2. Implementing PID-based fan control logic for non-CPU cooling fans only.

The fan category identifies the focus or responsibility of a given type of cooling within the server. By default, acceptable values are limited to `cpu` and `device`, representing the cooling management of all CPUs and all disk devices, respectively. UFC refers to these as 'categories' or 'types' of fans, and refers to their function. In UFC's default configuration, one may think of the 'device' fan category as responsible for peripheral cooling and/or anything in the server not directly tied to cooling the CPU(s).

### Default Fan Categories
Default category types are:
- `cpu` : CPU cooling
- `device` : disk cooling using PID controller
- `psu` : Power Supply Unit fans, which are automatically excluded and ignored

The `psu` fan category acts as a repository for fans that should always be ignored. Even if they fans are not actually PSU fans, a user may assign a given fan header to this category in order to ensure it is excluded from monitoring and manual fan control, regardless of the reason.

Several critical UFC logic filters and automation routines rely on fan duty category designations. For example, if no fan group is assigned to the category of CPU cooling, naturally this will be a problem as keeping the CPU(s) cool is UFC's top priority. If this situation occurs, UFC will attempt to re-assign fans to CPU cooling duty.

### Adding New Fan Categories to UFC
Adding a new fan duty category to UFC involves making the following changes:
1. Determine the purpose of the new fan category, including why no pre-existing fan category supports its use case(s).
2. Updating variables that constrain the universe of fan categories.
3. Deciding on the logic method of managing fan duty changes of fans belonging to the new fan category (e.g., use PID controller, or not).
4. Identifying subroutines that need to be modified to support a new fan category.
5. Modifying the Runtime program to support the new fan category type.
6. Testing and debugging the new integration.

#### Required Variable Array: `fan_duty_category`
The reference indexed array `fan_duty_category[]` lists all supported fan duty category names recognized by UFC. New fan categories must be added to this array or they will be ignored.

Here is an example showing the default fan duty categories:

```
fan_duty_category[1]=cpu
fan_duty_category[2]=device
fan_duty_category[3]=exclude
```

Keep in mind, **the index values don't matter**. It is **the values** the `fan_duty_category[]` array contains which matter. These values define the universe of recognized fan duty categories. For instance, they impact the creation of [binary strings](binary-strings.md) because **these values represent the only recognized prefixes of binary string variable names**.

> [!NOTE]
> The fan group schema and fan group label arrays are inter-connected.
> 
> The fan duty category array is not. It is a stand-alone array unto itself.
> Although it does impact other aspects of UFC, it does not have a bearing on the others.

---

## Fan Groups (Fan Group Schemas)
_Fan groups_ or _fan group schemas_ are lists of fan header names that share a common purpose. These lists are referred to as _schemas_ because they define which fan headers are associated with the given fan group ID.

Fan headers belonging to the same fan group are governed together. Manual fan control commands and actions are targetted toward a fan group, and the fan group schema identifies which individual fan headers are the target of the activity.

Fan groups must also be assigned a _[Fan Group Label](#fan-group-labels)_.

<<>>

```
fan_group_schema[0]="CPU_FAN"
fan_group_schema[1]="SYS_FAN1,SYS_FAN2,SYS_FAN3"
fan_group_schema[2]="psu_fan_1_1,psu_fan_1_2"
```

Fan Group Labels would need to be updated (below) and new [binary strings](/documentation/universal-fan-controller/binary-strings.md) would need to be created. Motherboard manufacturer and/or model configuration files might also need updating (if you wish to add use of a new fan group to a pre-existing motherboard manufacturer/model config file).

Example Usage
```
fan_group_category[cpu1]="cpu"
fan_group_category[cpu2]="cpu"
```

2. fan_group_schema[0]="FAN1,FAN2,FAN3"
3. fan_group_label[0]="cpu"
	- can be anything but value must match an index in fan_group_category or UFC wont know how to handle it
4. fan_duty_category
- indexed array of valid fan duty categories (e.g. cpu, device)
5. need to declare new binaries (they will be automatically created, but should be added to declarations file as well to be thorough and ensure documented everywhere)

<<>>

`fan_group_category[group label name] = fan category (type)`

maps index names to fan cooling types

<<>>

<<>>

Every fan header in the same group will have the same cooling duty function. For example, if three fans are grouped into fan group 0, and fan group 0 is assigned to CPU fan cooling duty, then each of the three fan headers mentioned in fan group 0 will be designated for dedicated CPU cooling responsibilities.

Fan groups are named and organized in configuration files, using indexed arrays to associate fan headers with their cooling roles.

Fan groups are defined using the following configuration variables:

- `fan_group_schema[group_id]`
  - Indexed array
  - 'group_id' = group number
  - Each array element's value consists of a **comma delimited list of fan header names** that belong to the fan Group ID.
- `fan_group_label[group_id]`
  - Indexed array
  - "group_id" = group number
  - Each array element's value consists of a **fan group label** associated with the fan Group ID.

## Fan Group Labels

are reference the group to make it easier for humans to understand their purpose, and a fan category (to inform UFC how the group of fans should be managed)

<<>>

Fan group _labels_ define the _functional_ role of the fan headers of the group.

[group index id] = fan group name

## Mapping with `fan_group_category` Array
--> maps every fan label to an existing fan category
<<>>

## Examples
1. Typical default fan groups of 'CPU' and 'disk device' cooling responsibilities.
```
fan_group_label[0]="cpu"
fan_group_label[1]="device"
```

2. This configuration splits CPU fans between two fan groups for dual-CPU systems.
```
fan_group_label[0]="cpu1"
fan_group_label[1]="cpu2"
```

3. Example where PSU fans appear in BMC's fan tracking sensors. The user has chosen to explicitly declare and isolate the fan headers in order to ensure they are ignored.

Note the custom name for `fan_group_label[2]`, which is translated appropriately as a PSU (excluded) fan group type via the variable assignment `fan_group_category[power_supply]="psu"`. This avoids any confusion on the part of UFC, although in this case it would be a straightforward process for UFC's automation to catch the fact this is a PSU fan and should be ignored.

```
fan_group_label[0]="cpu"
fan_group_label[1]="device"
fan_group_label[2]="power_supply"

fan_group_schema[0]="CPU_FAN"
fan_group_schema[1]="SYS_FAN1,SYS_FAN2,SYS_FAN3"
fan_group_schema[2]="psu_fan_1_1,psu_fan_1_2"

fan_group_category[cpu]="cpu"
fan_group_category[device]="device"
fan_group_category[power_supply]="psu"
```

### Reserved Group Types
Any fan group label containing one of the following words will have its associated fan headers (per its associated fan group schema) automatically [excluded](/documentation/universal-fan-controller/details/excluded-fans.md).
- exclude
- ignore
- psu

> This logic is controlled by the `inventory_fan_schemas` subroutine.

### Use in Automation
<<>>

### List of Recommended Fan Group Categories
<<>>

- maps fan label to a fan duty category
- fan category value must exist in fan_group_category[] array
- fan_group_category[] is required table or builder bails
- value must = a valid fan_duty_category array value

fan_group_category[cpu]="cpu"
fan_group_category[device]="device"
fan_group_category[disc]="device"
fan_group_category[disk]="device"
fan_group_category[drive]="device"
fan_group_category[exhaust]="device"
fan_group_category[fan]="device"
fan_group_category[fr]="device"
fan_group_category[front]="device"
fan_group_category[graphics]="exclude"
fan_group_category[hdd]="device"
fan_group_category[ignore]="exclude"
fan_group_category[intake]="device"
fan_group_category[psu]="exclude"
fan_group_category[rear]="device"
fan_group_category[side]="device"
fan_group_category[ssd]="device"
fan_group_category[sys]="device"
fan_group_category[vent]="device"

<<>>

sub `inventory_fan_schemas`
- $fan_category

<<>>


- Fan group schemas()
- Create new binary strings
- Create or update motherboard manufacturer and / or model configuration files as needed

see

related info: /documentation/universal - fan - controller / configuration / builder - config - file.md# fan - type - definitions - and - mapping


- update Fan Group Labels
- related info: /documentation/universal - fan - controller / configuration / builder - config - file.md
- fan - group - labels


How fan schemas work

`inventory_fan_schemas` function

# How it works: 
1. Fan headers are organized logically into groups called fan schemas.
2. These fan schemas indicate the role or purpose of the fan headers contained in each schema(group).
3. Fan schemas are tagged for their cooling responsibility type, which may be CPU cooling or device cooling;
i.e.anything other than the CPU(s).Fan schema labels are used to identify CPU or non - CPU related fan scheams.
4. Each fan header ID within a schema is grouped together for the purpose of the type of cooling duty or responsibility it is associated with.
5. The fan header IDs in each schema may be managed individually or as a group.How they are managed depends on the $fan_control_method variable setting.
- direct: fan speeds are independent, and fans are controlled individually
- group: fan speeds are independent, but fan speed changes must target all fans at once
- zone: fans are organized into logical groups called zones
- universal: fans can only be controlled en masse, as a group of all fans
6. When the zone $fan_control_method = zone is selected, fan schemas are associated with the given fan zone, meaning the fan schemas then take on a physical correlation to the fan headers, where the fan zone mirrors the logical fan schema IDs.
7. Fan schemas contain fan header names.These names must correlate to the fan header names reported by IPMI and map to the physical fan header IDs on the motherboard.
8. Any fan header name declared in a fan schema, but which does not exist or is not found, is ignored and will not be included in the corresponding logical fan group (nor the fan zone when `$fan_control_method` type is zoned).

Pre - requisites: 
1. Fan header names `fan_header_id[fan_name]` array
2. Fan header IDs `fan_header_name["$fan_id"]` array


Note that fan "groups" are tracked in the same manner, regardless of which fan control method is applied.
- The fan_group_schema[group_id] array contains non - validated fan headers by group ID.
- The fan_group_fan_id_binary[group_id] array is used to store fan header IDs which have been validated. Its element / key maps to the fan_group_schema array element IDs. Its value consists of a binary tracker representing the complete list of possible fan header IDs.
- The fan_group_label[group_id] array contains fan schema group labels and is applicable to both of the above arrays.
- When fans are controlled via fan zones, the fan_group_fan_id_binary[group_id] array serves an additional purpose of keeping track of which fan headers belong to each fan zone. It is also used by the Service program for monitoring fan groups and watching for certain types of fan failures.


do not need to worry about:
- fan_group_fan_id_binary: stores validated fan headers after sorting known fan header ids into the groups


In order to properly assign cooling duty to a fan header, its header name must appear in a fan schema. This is the whole point of fan schemas; to ensure each fan header is properly assigned to its desired fan duty / purpose. When fans are controlled via zones, orphaned fan headers are always disqualified from use.

Non - zoned fan control methods will attempt to utilize orphaned fan headers, though they may be assigned to an unexpected fan duty category. To prevent this from happening, or to resolve undesirable automatic orphan fan header assignments, purposefully declare all fan header names in .config or.zone files under fan group schemas.

<<>>

## modify subs

in include file, need to update this section to add support for new fan category:


<<>>

--> must update Runtime program as well

fan duty categories **must be pre-defined in the [Builder configuration file](/documentation/universal-fan-controller/configuration/builder-config-file.md#fan-type-definitions-and-mapping)**.

<<>>

`get_fan_info.sh` subroutine needs to be modified to add new fan categories

```
		##
		# When target is not a specific fan header name, it must reference one of the following:
		#
		# 1. group of fans based on fan duty category (type); or
		# 2. all fan headers; or
		# 3. a specific fan header ID
		#
		# Note: When target = all fans, the current fan ID is simply correlated to the master list of
		# valid fan header IDs, and if the current fan ID is valid, it's data will be processed.
		##

		case "$target" in # 1/
			cpu|device)
				# skip when fan duty category does not match target duty type
				! query_ordinal_in_binary "$fan_id" "${target}_fan_header_binary" && continue
			;;

			*)
				# target = all fans or specific fan header name
				# skip when fan header name not recognized or not valid
				! query_ordinal_in_binary "$fan_id" "fan_header_binary" && continue
			;;
		esac # 1/
```

update `parse_fan_label.sh` sub

```
	# filter result based on known fan duty categories since at this time only specific fan duty categories are supported
	case "$result" in # 1/
		cpu|device|exclude)
			printf "%s" "$result"
		;;

		*)
			printf "unknown"
		;;
	esac # 1/
```


update `inventory_fan_schemas.sh` sub

```
		##
		# Stage 4: Parse remaining fan group/zone schemas
		#
		# Sort remaining fan schema headers into cpu, device, or excluded fan group types.
		#
		# Assigns fan duty category to every fan header name in fan group schema, based on
		# decision of what cooling duty type should be, which is decided based on the
		# label of the fan group imported from .config and/or .zone files.
		##

		# parse remaining fan group schemas based on their labels
		for group_id in "${!fan_group_label[@]}"; do # 1/ loop through remaining fan group schema labels
			debug_print 4 "Examine fan group schema label ID $group_id"


			fan_category="$(parse_fan_label "${fan_group_label[$group_id]}")" # get mapping of fan group label to fan duty category
			debug_print 4 "Fan group category: $fan_category"

			if [ "$fan_control_method" = "zone" ]; then # 2/ fan zone filtering
				set_ordinal_in_binary "on" "$group_id" "fan_zone_binary" # keep a record of identified fan zones even if they will not be utilized

				case "$fan_category" in # 1/
					cpu|device)
						set_ordinal_in_binary "on" "$group_id" "${fan_category}_fan_zone_binary"
						debug_print 3 "Fan zone ID $group_id (${fan_group_label[$group_id]}) assigned to ${fan_category^^} cooling duty"
					;;

					*)
						debug_print 3 caution "Ignore fan zone ID $group_id (${fan_group_label[$group_id]}): non-supported fan duty category \"$fan_category\""
						unset fan_category # force fan headers to be excluded in next section
					;;
				esac # 1/
			else # 2/
				debug_print 4 "Fan $schema_type $group_id cooling duty type: ${fan_category^^}"
			fi # 2/

			# process disqualified fan types
			case "$fan_category" in # 1/
				ignore|exclude*)
					debug_print 4 caution "Explicitly ignoring fan headers in fan group $group_id"
					unset fan_category # force fan exclusion
				;;

				psu)
					# excluded fan type
					debug_print 2 warn "Fan $schema_type $group_id appears to contain fan headers of an unsupported special type: '${fan_category}'"
					debug_print 4 warn "${fan_category^^} cooling fans are not supported and will be ignored permanently as a precaution"
					unset fan_category # force fan exclusion
				;;
			esac # 1/
```

and


```
# Stage 5: Orphan fan header detection

##
# Attempt to determine orphan fan header type by parsing the fan name.
# The fan name is mapped to the list of known fan header types, which
# is then translated to a functional fan category (CPU, Device, or PSU type).
##

fan_category = "$(parse_fan_label "
$fan_name " "
header name ")"
debug_print 3 "Fan name $fan_name categorized as type \"${fan_category^^}\""

case "$fan_category" in
psu)
# fan category not allowed, exclude fan header from being managed
debug_print 3 warn "Fan $fan_name appears to be unsupported type \"${fan_category^^}\""
debug_print 4 warn "${fan_category^^} cooling fans are not supported and will be ignored permanently as a precaution"

set_ordinal_in_binary "on"
"$fan_id"
"exclude_fan_header_binary"
debug_print 4 "Fan header $fan_name (ID $fan_id) excluded from further utilization (special fan category: ${fan_category^^})";;

cpu | device)
debug_print 3 "Orphan fan header \"$fan_name\" appears to be ${fan_category^^} cooling related"
set_ordinal_in_binary "on"
"$fan_id"
"${fan_category}_fan_header_binary";;

##
# Orphan fan headers are otherwise presumed to be device fan headers.
# Default to device cooling duty when type / category unknown.
# Ignore fan header when already accounted for.
##

*)
debug_print 4 caution "Fan header $fan_name type is unknown type"
debug_print 3 "Fan header $fan_name (ID $fan_id) assigned to Disk Device cooling duty"
set_ordinal_in_binary "on"
"$fan_id"
"device_fan_header_binary";;
esac
done# 1 /
```

`validate_fan_group.sh` sub may need to be modified

`declarations_builder.sh`
