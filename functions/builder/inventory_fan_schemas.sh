##
# Organize detected fan headers into logical groups.
#
# Validate which fan groups exist, identify the purpose of each fan header, sort fans into logical
# groups. Determine which fan group each fan header belongs to.
#
# This information is critical when fan zones are utilized to control fan headers.
#
# It is also useful even when fans are directly controlled, as the fan schemas are used
# to identify which fan headers are responsible for CPU cooling.
#
# On the other hand, this information is not poignant when fans are controlled universally (in which
# case all fans are treated as if they are dedicated to CPU cooling).
#
# How it works:
#
# --> 1. Fan headers are organized logically into groups called fan schemas.
# --> 2. These fan schemas indicate the role or purpose of the fan headers contained in each schema (group).
# --> 3. Fan schemas are tagged for their cooling responsibility type, which may be CPU cooling or device
#	cooling; i.e. anything other than the CPU(s). Fan schema labels are used to identify CPU or non-CPU
#	related fan scheams.
# --> 4. Each fan header ID within a schema is grouped together for the purpose of the type of cooling duty
#	or responsibility it is associated with.
# --> 5. The fan header IDs in each schema may be managed individually or as a group. How they are managed
#	depends on the $fan_control_method variable setting.
#
#	--> direct    : fan speeds are independent, and fans are controlled individually
#	--> group     : fan speeds are independent, but fan speed changes must target all fans at once
#	--> zone      : fans are organized into logical groups called zones
#	--> universal : fans can only be controlled en masse, as a group of all fans
#
# --> 6. When the zone $fan_control_method = zone is selected, fan schemas are associated with the given
#	fan zone, meaning the fan schemas then take on a physical correlation to the fan headers, where the fan
#	zone mirrors the logical fan schema IDs.
# --> 7. Fan schemas contain fan header names. These names must correlate to the fan header names reported by
#	IPMI and map to the physical fan header IDs on the motherboard.
# --> 8. Any fan header name declared in a fan schema, but which does not exist or is not found, is ignored
#	and will not be included in the corresponding logical fan group (nor the fan zone when $fan_control_method
#	type is zoned).
#
# Pre-requisites:
#	1. Fan header names		fan_header_id[fan_name] array
#	2. Fan header IDs		fan_header_name["$fan_id"] array
##

# Stage 0: Validate human-readable fan cooling duty category table
# Stage 1: Validate fan group schemas that define fan groups and zones
# Stage 2: Validate fan header names mentioned in each fan group schema
# Stage 3: Override CPU fans per Builder config file
# Stage 4: Orphan fan header detection
# Stage 5: Assign fan headers to category-specific fan header binaries

function inventory_fan_schemas ()
{
	local binary_pointer
	local clean_fan_schema
	local fan_category_name			# name of fan duty category type for special fan filtering
	local fan_id
	local fan_name
	local group_id					# fan group schema id
	local index					# for/loop index
	local raw_fan_schema
	local schema_type				# group or zone, depending on fan control method
	local status					# most recent fan status
	local zone_id					# group or zone id

	local -a fan_array				# temporary array of fan header metadata
	local -a -l fan_header_category	# temporary array of fan header duty categories ( fan id = fan duty category name )
	local -a zone_array				# temporary array of fan zone metadata

	# nothing to do here when there are no previously detected fan headers
	binary_is_empty "$fan_header_binary" && return

	debug_print 4 "Inventory fan group schemas"

	##
	# When the fan control method is 'universal' fans are not sorted as there is no point
	# in doing so. They will all be managed together anyway, and all treated as assigned
	# to CPU cooling duty.
	#
	# Therefore, most of the logic here only applies when a fan control method other than
	# universal is applied.
	##

	if [ "$fan_control_method" != "universal" ]; then # 1/

		[ "$fan_control_method" = "zone" ] && schema_type="zone" || schema_type="group"

		##
		# Stage 0: Validate human-readable fan cooling duty category table
		#
		# This conversion table is required to be declared in one or more Builder config files.
		# It acts as a bridge between human-readable fan duty categories required by fan group
		# schemas - fan_group_category[fan group schema index]="functional fan duty category" - and
		# functional fan duty categories - fan_duty_category[index]="category name" - as required
		# by UFC to define the cooling purpose of each fan header and zone.
		#
		# The counter-party to this validation involves validating the functional fan duty
		# categories themselves, which is handled by the main Builder program, and precedes
		# calling this function.
		##

		# confirm all fan group category references are legitimate fan duty categories
		debug_print 3 "Cross-reference fan group schema category mappings to fan cooling duty categories declared in config files"

		# remove empty fan duty category array elements
		for group_id in "${!fan_group_category[@]}"; do # 1/
			fan_category_name="${fan_group_category[$group_id]}"

			if [ -z "$fan_category_name" ]; then # 1/ associative array element exists but has no value (empty)
				unset "fan_group_category[$group_id]" # remove element from array
				debug_print 3 warn "Removed empty 'fan_group_category' array entry at index '$group_id'"
				continue
			fi # 1/

			# confirm whether fan duty category indicated is valid
			if validate_fan_category_name "$fan_category_name"; then # 1/
				continue
			else # 1/fan group category name in fan_group_category[$group_id] is not a legitimate fan duty category
				unset "fan_group_category[$group_id]" # remove array element with invalid mapping
				debug_print 3 warn "Removed invalid 'fan_group_category' array entry at index '$group_id' (value: ${fan_group_category[$group_id]})"
			fi # 1/
		done # 1/

		# confirm at least required fan type label mapping exists
		[ "${#fan_group_category[@]}" -eq 0 ] && bail_noop "Required table of 'fan_group_category' declared in one or more config files is invalid"

		##
		# Stage 1: Discard empty fan group schemas
		#
		# Note that if duplicate schema IDs exist in config files,
		# the most recently imported fan schema record with the same ID will prevail.
		##

		debug_print 2 "Analyze fan header ${schema_type}s and their names declared in config (.conf) files"

		# discard empty fan group schemas
		for group_id in "${!fan_group_schema[@]}"; do # 1/
			if [ -z "${fan_group_schema[$group_id]}" ]; then # 2/
				debug_print 4 warn "Removing schema for fan group $group_id because it is empty"
				unset "fan_group_label[$group_id]"
				unset "fan_group_schema[$group_id]"
			fi # 2/
		done # 1/

		# discard fan group labels with no schema
		for group_id in "${!fan_group_label[@]}"; do # 1/
			if [ -z "${fan_group_schema[$group_id]}" ]; then # 2/
				debug_print 4 warn "Removing label for fan group $group_id because it has no associated schema"
				unset "fan_group_label[$group_id]"
				continue
			fi # 2/

			##
			# Confirm there is a fan duty category associated with the fan group category before continuing.
			#
			# Value of fan_group_label[group_id] must match a fan duty category name.
			# Discard fan group schemas that do not map to a valid fan duty category.
			##

			# look-up translation of human-readable fan group category name to comparable fan duty category id
			fan_category_name="${fan_group_category[${fan_group_label[$group_id]}]}"

			# disqualify fan group schema and its label when label references non-existent fan duty category name
			if [ -z "${fan_header_binary[$fan_category_name]}" ]; then # 2/ no matching fan header binary means the duty category name is invalid
				debug_print 4 warn "Removing fan group schema ID $group_id because its label is mapped to an unknown fan duty category type: $fan_category_name"
				unset "fan_group_label[$group_id]"
				unset "fan_group_schema[$group_id]"
			fi # 2/
		done # 1/

		# discard fan schemas with no label
		for group_id in "${!fan_group_schema[@]}"; do # 1/
			if [ -z "${fan_group_label[$group_id]}" ]; then # 2/
				debug_print 4 warn "Removing schema for fan group $group_id because it has no associated group label"
				unset "fan_group_schema[$group_id]"
			fi # 2/
		done # 1/

		# discard fan group schemas with no fan header names
		for group_id in "${!fan_group_schema[@]}"; do # 1/

 			# normalize delimiters by converting them to space character
			raw_fan_schema="${fan_group_schema[$group_id]}"
			clean_fan_schema="$(normalize_text "$raw_fan_schema")"

			# ignore fan schemas with invalid content
			if [ -z "${clean_fan_schema//[0-9 ]/}" ]; then # 2/ discard schemas that do not contain at least one potentially valid fan header name
				debug_print 3 caution "Fan schema for fan group $group_id is empty or contains invalid fan header names"
				unset "fan_group_schema[$group_id]"
				unset "fan_group_label[$group_id]" # also discard label of decommissioned schema
			else # 2/
				[ "${fan_group_schema[$group_id]}" != "$clean_fan_schema" ] && fan_group_schema["$group_id"]="$clean_fan_schema"
			fi # 2/
		done # 1/

		##
		# Stage 2: Parse and validate fans mentioned in each fan group schema
		#
		# Parse list of fan header names associated with each fan group schema.
		#
		# 1. Validate every fan header name in each fan group schema.
		# 2. Scrub schemas of invalid fan header names.
		# 3. Discard fan group schemas lacking at least one valid fan header name.
		# 4. Quantify which fan group/zone each validated fan header belongs to.
		# 5. Ignore duplicate entries for the same fan header name.
		# 6. When fan header name mentioned in more than one fan group, retain the first group ID.
		##

		if [ "${#fan_group_schema[@]}" -gt 0 ]; then # 2/ trap lack of any fan zone definitions

			# sort each fan group schema contents (fan header names)
			for group_id in "${!fan_group_schema[@]}"; do # 1/ review each fan group schema not disqualified in Stage 1
				debug_print 3 "Examine fan $schema_type schema ID $group_id"

				# parse fan header list from fan group schema into array after normalizing delimiters
				clean_fan_schema="${fan_group_schema[$group_id]}"
				read -ra fan_array <<< "$clean_fan_schema"

				##
				# Sort fans in group schema by fan name.
				# Ignore duplicate fan header names in the same fan group schema.
				# When the same fan header name is found in more than one fan group schema, the first prevails.
				##

				for index in "${!fan_array[@]}"; do # 2/ parse each fan header name within current fan schema group

					##
					# Strip invalid fan header names or fan IDs from working array
					##

					fan_name="${fan_array[$index]}"

					if [ -z "$fan_name" ]; then # 2/ drop empty array elements
						unset "fan_array[$index]"
						continue
					fi # 2/

					fan_id="${fan_header_id[$fan_name]}"

					# skip invalid fan header names
					if [ -z "$fan_id" ]; then # 2/ no fan id = invalid fan name (mentioned in fan group schema but BMC did not report its existence)
						debug_print 3 warn "Fan header name '$fan_name' found in fan $schema_type ID $group_id schema is not recognized and will be ignored"
						unset "fan_array[$index]"
						continue
					fi # 2/

					debug_print 3 "Evaluate fan name: $fan_name (fan ID $fan_id)"

					##
					# Note: fan_header_zone[] array is dual-use
					#
					# The fan group schema declarations in the Builder config file specifies which fan headers belong to
					# which fan group.
					#
					# When the fan control method = zone, fan groups are treated as fan zones. They are effectively the
					# same thing.
					#
					# When fan control method != zone, $fan_header_zone[] is still used to associate each fan header
					# with its group ID. This is used to ensure fan header names are not declared more than once in the
					# config file and indirectly to assign fan cooling duty categories to the fan headers.
					##

					# validate each fan header name mentioned in the fan group schema
					zone_id="${fan_header_zone[$fan_id]}" # will be null unless current fan header is a dup

					##
					# Warn when fan header name already tagged in a fan group (duplicate fan header name).
					# Ignore duplicate if fan name is listed more than once in same fan group schema.
					##

					if [ -n "$zone_id" ]; then # 2/ already exists (duplicate entry)
						if (( zone_id != group_id )); then # 4/ fan name mentioned in previously processed fan group schema
							debug_print 3 caution "Ignoring duplicate fan header name '$fan_name' in different fan group schema ($group_id)"
							debug_print 4 bold "Remove duplicate fan name entries within fan group schemas, in config files"
						else # 3/ duplicate entry in same fan group schema
							debug_print 3 caution "Ignoring duplicate fan header name '$fan_name' in the same fan group schema ($group_id)"
						fi # 3/

						# skip/ignore duplicate fan name
						unset "fan_array[$index]"
						continue
					fi # 2/

					##
					# initial assignment of fan_header_zone[fan_id]
					##

					# create new fan header id to fan group/zone association when fan header name not yet assigned
					fan_header_zone["$fan_id"]="$group_id"

					debug_print 3 "$fan_name assigned fan $schema_type: ${fan_header_zone[$fan_id]}"

					##
					# Activate fan zone since it has at least one existing fan header.
					# Do this even when fan control method != zone in order to track all CPU fan groups.
					##

					set_ordinal_in_binary "on" "$group_id" "fan_zone_binary"

					##
					# Associate each fan header with a fan duty category.
					# This is the cooling duty category of the fan header, which is determined by
					# the fan duty category associated with its fan group label.
					#
					# fan duty category = fan category associated with fan group label
					# of fan group the fan header belongs to.
					##

					fan_header_category["$fan_id"]="${fan_group_label[$group_id]}" # fan duty category associated by fan group schema label

					debug_print 3 "$fan_name assigned fan duty category: ${fan_header_category[$fan_id]}"
				done # 2/

				if [ "${#fan_array[@]}" -eq 0 ]; then # 2/
					debug_print 3 caution "Dropping fan $schema_type schema ID $group_id (no valid fan header names remain)"
					unset "fan_group_schema[$group_id]"
					unset "fan_group_label[$group_id]"
				else # 2/

					##
					# Not currently used elsewhere in this subroutine. However, in case it may be
					# needed by other subroutines, save the cleaned and validated list of fan
					# header names back into the fan group schema when there is at least one valid
					# fan header name belonging to it.
					##

					if [ "${fan_group_schema[$group_id]}" != "${fan_array[*]}" ]; then # 3/
						fan_group_schema["$group_id"]="${fan_array[*]}"
					fi # 3/
				fi # 2/
			done # 1/
		else # 2/
			debug_print 1 warn "No fan group/zone schemas defined in Builder config files"

			if [ "$fan_control_method" = "zone" ]; then # 3/
				debug_print 4 critical "Impossible to setup fan zones without specified fan group schemas declared in one or more Builder config files"
				bail_noop "Cannot continue because no fan zones were declared in Builder config files"
			else # 3/
				debug_print 2 warn "All fan headers will be treated as orphans"
			fi # 3/
		fi # 2/

		##
		# Stage 3: Process forced assignment of CPU fans per Builder config file
		#
		# Assign fan headers and groups/zones mentioned in $cpu_fan_group. This may result in reassignment
		# of fans tagged in Stage 2, as this Builder config parameter overrides any previously assigned fan
		# category settings (which fan group schema each fan belongs to) when there is a conflict.
		#
		# $cpu_fan_group is optional. If not set in a config file, then fan group/zone assignments will be
		# dictated by solely by fan group schemas.
		#
		# Note: $cpu_fan_group may not contain both fan header names and group IDs. If it does, group IDs
		# will be ignored and fan header names will prevail.
		##

		# fan zone id numbers, fan group schema ids, or fan header names may be specified
		cpu_fan_group="$(normalize_text "$cpu_fan_group")" # convert common delimiters to space character

		if [ -n "$cpu_fan_group" ]; then # 2/ CPU fan header override list found (fan names, fan groups, or fan zones)
			debug_print 2 "Processing fan $([ "$fan_control_method" = "zone" ] && printf "headers, groups, and zones" || printf "headers and groups") designated for CPU cooling duty"

			##
			# cpu_fan_group contains fan header names
			##

			if [ -n "${cpu_fan_group//[0-9 ]/}" ]; then # 3/ non-numeric characters indicate presence of fan header names
				debug_print 2 "Declared CPU cooling fan header names: $cpu_fan_group"

				read -ra fan_array <<< "$cpu_fan_group" # parse and validate fan header name list

				for fan_name in "${fan_array[@]}"; do # 1/ parse each fan header name from list created in Phase 2
					fan_id="${fan_header_id[$fan_name]}"

					if [ -z "$fan_id" ]; then # 4/ fan header name mentioned in $cpu_fan_group does not exist
						debug_print 3 warn "Fan $schema_type ID '$group_id' specified in 'cpu_fan_group=' declaration in config file is not a valid fan group"
						continue # skip to next group id in the list
					fi # 4/

					[ "${fan_header_category[$fan_id]}" = "cpu" ] && continue # already tracking this fan header as CPU cooler (duplicate fan name)

					# assign fan header to cpu fan header tracker
					fan_header_category["$fan_id"]="cpu"
					debug_print 4 "Fan header $fan_name assigned to CPU cooling duty"

					# convert all fans with the same zone/group id to CPU fan duty
					group_id="${fan_header_zone[$fan_id]}" # fan group assignment of current fan header, discovered during Phase 2

					# find all fan headers belonging to the same fan group/zone and also assign them to cpu fan cooling duty
					for fan_id in "${fan_header_id[@]}"; do # 2/ scan all fan headers
						if [ "${fan_header_zone[$fan_id]}" = "$group_id" ]; then # 4/ match group/zone id of known CPU fan
							fan_header_category["$fan_id"]="cpu"
							debug_print 4 "Fan header $fan_name assigned to CPU cooling duty because it belongs to fan $schema_type $group_id"
						fi # 4/
					done # 2/
				done # 1/

			else # 3/ $cpu_fan_group contains fan schema group IDs

				##
				# $cpu_fan_group contains fan group/zone ids
				#
				# Process each indicated fan group ID.
				# Check each fan header known fan group (fan_header_zone[fan_id]).
				# If they match, then set fan_header_category[fan_id]=cpu
				##

				debug_print 2 "Declared CPU cooling fan $schema_type ID(s): $cpu_fan_group"

				# parse list of fan group/zone IDs
				read -ra zone_array <<< "$cpu_fan_group"

				for group_id in "${zone_array[@]}"; do # 1/ loop thru each fan group id

					##
					# Verify group_id is a legit fan schema group number.
					# Recall that zone binaries are used for tracking purposes even when fan
					# control method != zone.
					##

					if [ -z "${fan_group_schema[$group_id]}" ]; then # 4/ fan zone/group id does not exist
						debug_print 3 warn "Fan $schema_type ID '$group_id' specified in 'cpu_fan_group=' declaration in config file is not a known fan group"
						continue # skip to next group id in the list
					fi # 4/

					debug_print 3 "Designate fan $schema_type schema $group_id fans for CPU cooling fan duty"

					##
					# Tag cpu fan zones when using zoned fan control method.
					#
					# Even when fan control method != zone, this binary is used for validation
					# purposes regarding fan groups.
					##

					# find all fan headers belonging to the same fan group/zone and reassign them to cpu fan cooling duty
					for fan_id in "${fan_header_id[@]}"; do # 2/ scan all fan headers
						if [ "${fan_header_zone[$fan_id]}" = "$group_id" ]; then # 4/ match group/zone id of known CPU fan
							fan_header_category["$fan_id"]="cpu"
							debug_print 4 "Fan header $fan_name assigned to CPU cooling duty because it belongs to fan $schema_type ID $group_id"
						fi # 4/
					done # 2/
				done # 1/
			fi # 3/
		else # 2/ $cpu_fan_group is empty / not specified in a config file

			##
			# CPU fan list override not specified in configuration.
			#
			# CPU fan assignments will be based solely on fan group schemas.
			##

			debug_print 2 caution "CPU fan header list not specified in .config file"
			debug_print 3 bold "CPU fans will be denoted based solely on their fan category $schema_type assignment"
			debug_print 3 bold "Are any CPU fan groups defined in .config or .zone files?"
		fi # 2/

		##
		# Stage 4: Orphan fan header detection
		#
		# Orphans are fan headers discovered by IPMI, but not mentioned in a fan group schema.
		#
		# In order to properly assign cooling duty to a fan header, its header name must appear
		# in a fan schema. This is the whole point of fan schemas; to ensure each fan header is
		# properly assigned to its desired fan duty/purpose.
		#
		# Orphans are identified because they have the following traits:
		#	- Has a valid fan ID
		#	- Not found in any fan group schema
		#	- Not previously tagged in fan_header_binary tracker
		#	- Does not have a fan_header_zone[] array assignment
		#
		# UFC will attempt to assign orphan fan headers to a fan duty category based on the name
		# of each fan (e.g., FANA, SYS_FAN1) when feasible.
		##

		debug_print 2 "Check for orphan fan headers"
		debug_print 4 "Orphan fan headers are those reported by IPMI, but not found in a fan $schema_type"

		##
		# Zoned vs. non-zoned fan control method
		#
		# Orphan fan header filtering applies only when the fan control method is not zoned.
		#
		# When fans are controlled via zones, orphaned fan headers are always almost always
		# excluded from use as their proper fan zone ID cannot be known.
		#
		# There is one edge case which is an exceptions to this rule: when 'only_cpu_fans'
		# is set to 'true' AND there is only one fan zone.
		#
		# Non-zoned fan control methods will attempt to utilize orphaned fan headers, though they
		# may be assigned to an unexpected fan duty category. To prevent this from happening, or to
		# resolve undesirable automatic orphan fan header assignments, purposefully declare all fan
		# header names in config (.conf) files under fan group schemas.
		#
		# UFC attempts to determine the intended purpose of any orphan fan headers based on parsing
		# the fan header name and comparing it to all fan duty category types. If the orphan fan
		# header name corresponds to a fan duty category, it will be assigned to the orphan fan.
		##

		if [ "$fan_control_method" != "zone" ]; then # 2/ is fan header likely a cpu cooling fan?
			debug_print 2 caution "Because fan control method is zoned, all orphan fan headers will be excluded from use"
			debug_print 4 "It is not posssible to know beyond a resonable doubt the fan zone ID any orphan header should belong to"
		fi # 2/

		for fan_id in "${!fan_header_name[@]}"; do # 1/ examine each fan header validated in stage 2
			[ -n "${fan_header_zone[$fan_id]}" ] && continue # not an orphan
			fan_name="${fan_header_name[$fan_id]}"

			parse_fan_label "$fan_id" "$fan_name"

			if [ -n "${fan_header_category[$fan_id]}" ]; then # 2/ matching fan duty category name found
				debug_print 3 caution "Fan header '$fan_name' (ID $fan_id) assigned to '${fan_header_category[$fan_id]}' cooling duty"
			else # 2/ no match found
				fan_header_category["$fan_id"]="exclude"
				debug_print 2 caution "Orphan fan header '$fan_name' (fan ID $fan_id) has been excluded from utilization"
				debug_print 4 "Add this fan header name to a fan zone schema in a Builder config (.conf) file to include it"
			fi # 2/
		done # 1/

	else # 1/ universal fan control method skips to here

		debug_print 4 "Fan control mode indicates all fans are controlled together and treated as a single fan group"
		only_cpu_fans=true # do not allow device fan group when universal fan control method

		# fans are always treated as cpu cooling type
		for fan_id in "${!fan_header_name[@]}"; do # 1/ all physically existing fan headers
			[ "${fan_header_category[$fan_id]}" != "exclude" ] && fan_header_category["$fan_id"]="cpu" # any fan with category != exclude should be set = cpu
			fan_header_zone["$fan_id"]=0 # assign univeral fan headers to a single zone (0)
		done # 1/

	fi # 1/

	##
	# Stage 5: Assign fan headers to category-specific fan header binaries
	#
	# 1. Assign each fan header to the fan header category binary it belongs to.
	# 2. When zoned fan control, tag each fan group/zone ID with non-excluded fan headers in its category-specific fan zone binary.
	# 3. Do not assign excluded fans to a fan group/zone binary.
	##

	for fan_id in "${!fan_header_name[@]}"; do # 1/ assign each fan header to the category fan header it belongs to
		binary_pointer="${fan_header_category[$fan_id]}_fan_header_binary"
		set_ordinal_in_binary "on" "$fan_id" "binary_pointer"
	done # 1/
}
