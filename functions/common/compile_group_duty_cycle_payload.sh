##
# Compile sequential array of pending fan duty settings for all fan headers.
#
# Group fan control method only: all fan speeds must be compiled at once
#
# Inputs:
#	1. Target: fan type target; must be a valid fan duty category or 'all'
#	2. Fan duty: new fan duty (percentage) to set target fan type to
#
# When the target is 'all' fans, this means set all fans to the specified fan duty.
# All fans matching the 'target' fan duty type will have their fan duty (fan speed setting) modified.
##

##
# The "group" fan control method is very similar to the "direct" fan control
# method. Both methods control fans at the individual fan level. The difference
# between them is that group-controlled fans must be addressed all together,
# simultaneously in the same command. Whereas direct-controlled fans may have
# commands addressed to each fan separately.
#
# Compile IPMI fan header write fan speeds. Called when any fan speed changes.
# Assign CPU and Device fan header speeds to respective fan header positions.
# Fan duty speed value is integer.
#
# Updates $ipmi_group_fan_payload[] array, an indexed array composed of sequentially
# ordered fan header duty cycles and special flags. The array contents are suitable
# for copying directly into an IPMI command line as the raw data payload when fan
# control method = Group.
#
# Fan speeds of excluded fans are not modified unless they have no prior fan speed
# record.
#
# Fans not the subject of the target fan type are not modified.
#
# Logic:
#	--> 1. Update all fans at once.
#	--> 2. Do not change fan duty for target when it is already at that speed.
#	--> 3. Update non-target fans by simply copying their last fan speed update when known.
#	--> 4. When non-target previous fan speed is not known, update them with last known fan speed for given cooling duty type.
#	--> 5. For non-target cooling duty type, when prior speed is not known, use starting speed for type.
##

##
# Note on Excluded Fan Headers
#
# Excluded fan headers should have already previously been set to automatic fan
# mode when possible. However, when the group fan control method is utilized, these
# fans still require a placeholder of some sort. This section substitutes the "dummy"
# value in place of actual fan speeds for these fans. These dummy values should be
# ignored.
#
# Any fan speed entry for an excluded fan header should be ignored, presuming the fan
# header is running in automatic mode as would be expected. However, in the event this
# is not the case, this process ensures its value is set correctly either way.
#
# Even though the fan duty category of each fan header and fan zone are known, and therefore
# it is possible to skip making changes to current fan speeds, fan speed updates are forced
# on a per fan header basis unless the specific fan header's prior fan speed assignment
# is known and equals the new (current) fan speed request for the given fan header.
# This ensures that if this is the first time fan speeds are being updated or if a fan
# header's speed incumbent value is not known for some reason, that a command to update
# the speed to the current (desired) speed is processed. The key is to prevent any
# circumstance where a given fan header is not set and/or prevent it from being
# accidentally set to 0 or another potentially incorrect value.
##

##
# Input: arrays of write-ordered data payload types and positions calculated by order_fan_headers_by_write_position subroutine
#	1. $ipmi_write_position_fan_id[] array   : [write position] = fan id
#	2. $ipmi_write_position_fan_name[] array : [write_position] = fan name
#
# Output:
#	1. ipmi_group_fan_payload[] : [write position] = fan duty or special function byte
##

function compile_group_duty_cycle_payload ()
{
	# applicable to group fan control method only
	if [ "$fan_control_method" != "group" ]; then # 1/
		debug_print 1 warn "Inappropriate subroutine call (fan_control_method=$fan_control_method)" true
		debug_print 4 "function 'compile_group_duty_cycle_payload' is applicable to group type fan control method only"
		return 1
	fi # 1/

	local dummy
	local existing_duty
	local fan_category
	local fan_duty					# decimal fan speed to set fans in target fan group to
	local fan_id
	local fan_name
	local index
	local ipmi_data_payload_length	# length of IPMI data payload before padding
	local match
	local target					# fan cooling type or group to have its fan speeds modified (e.g. cpu or device)
	local write_position			# position in write position order a given data byte belongs to

	dummy=0 # default 'dummy' placeholder value

	target="$1"	# fan group type to apply new fan duty cycle to (e.g. cpu, device, etc.)
	fan_duty="$2"	# new fan duty cycle (fan speed) expressed as integer

	debug_print 4 "Compile duty cycle payload: set target fan cooling duty category '${target}' to fan duty ${fan_duty}%"

	##
	# Create $ipmi_group_fan_payload[] array sequentially based on ipmi command fan order.
	# Array index correlates to IPMI data payload order (not fan header IDs), and contains
	# new fan duty or special function byte for each position in the data payload.
	##

	if [ -z "$target" ]; then # 1/
		debug_print 3 warn "Missing target fan duty category" true
		return 1
	fi # 1/

	if [ -z "$fan_duty" ]; then # 1/
		debug_print 3 warn "Undefined fan duty cycle" true
		return 1
	fi # 1/

	# validate fan duty category of target (fan type to modify)
	if [ "$target" != "all" ]; then # 1/ target must be legit value when not all fans
		if validate_fan_category_name "$target"; then # 2/
			fan_category="$target"
		else # 2/ no match means target is invalid
			debug_print 2 warn "Invalid fan duty category provided to fan group duty cycle compiler: $target" true
			return 1
		fi # 2/
	fi # 1/

	##
	# Verify required global arrays exist (created by Builder via 'order_fan_headers_by_write_position' subroutine).
	##

	# IPMI write position array maps not defined
	if [ "${#ipmi_write_position_fan_name[@]}" -eq 0 ] || [ "${#ipmi_write_position_fan_id[@]}" -eq 0 ]; then # 1/
		if [ "$program_module" = "builder" ]; then # 2/ can only re-evaluate when this sub is called by Builder
			debug_print 3 warn "One or more IPMI write position arrays are not defined" true

			# try to get the missing arrays built
			debug_print 4 "Nudge fan ordering process"
			ipmi_order_fan_header_names

			if [ "${#ipmi_write_position_fan_id[@]}" -eq 0 ]; then # 3/ required array construction failed
				debug_print 2 warn "Failed to reconstruct IPMI write position array" true
				debug_print 3 warn "Blocked from updating fan duty cycle payload array due to undefined fan write position array"
				return 1
			fi # 3/
		else # 2/ current main program not Builder
			debug_print 4 critical "Re-run Builder to define IPMI fan write-order arrays"
			bail_noop "IPMI write position arrays not defined" true
			return 1
		fi # 2/
	fi # 1/

	# analyze IPMI write position arrays
	for write_position in "${!ipmi_write_position_fan_id[@]}"; do # 1/ process every write position object in sequential order

		fan_id="${ipmi_write_position_fan_id[$write_position]}" # value is either fan id or special placeholder object
<<>>
		# something wrong with look-up table when result is null or empty
		if [ -z "$fan_id" ]; then # 1/ no write position for known fan id
			debug_print 2 critical "No write position record found for fan ID '${fan_id}' in '\${ipmi_write_position_fan_id[$write_position]}' array" true
			debug_print 3 critical "Non-recoverable error; aborting group method IPMI data payload compilation"
			return 1
		fi # 1/

		##
		# Screen write position parameter.
		#
		# Write position value may be a special placeholder (e.g., cpu override flag)
		# or a fan ID.
		#
		# When the arg is numeric, it should be a fan header ID.
		# When the arg is not numeric, it should be a special placeholder designator.
		##

		# handle parsing differently depending on whether or not fan name is a fan id or a name reference
		if [ -n "${fan_id//[0-9]/}" ]; then # 1/ special data type (i.e., not fan id, not numeric)

			fan_name="${ipmi_write_position_fan_name[$write_position]}"

			# something wrong with look-up table when result is null or empty
			if [ -z "$fan_name" ]; then # 2/ no fan name or special placeholder value to evaluate
				debug_print 2 critical "Empty write-position placeholder: position '${write_position}' in '\${ipmi_write_position_fan_id[$write_position]}'" true
				return 1
			fi # 2/

			# process data payload fillers for special data bytes
			case "$fan_name" in # 1/
				cpu_override|override)
					if [ "$cpu_fan_control" = true ]; then # 1/ pad cpu sub-group with override flags when cpu fans are actively managed
						cpu_fan_override=1 # enable cpu override (overrides automatic cpu fan mode)
					else # 1/ do not override
						cpu_fan_override=0 # disable cpu override (reverts cpu fans to automatic mode)
					fi # 1/

					ipmi_group_fan_payload["$write_position"]="$cpu_fan_override" # insert CPU override value
				;;

				dummy)
					ipmi_group_fan_payload["$write_position"]="$dummy" # insert dummy placeholder value
				;;

				*)
					debug_print 4 warn "Invalid fan name reference in lookup table: \$ipmi_write_position_fan_name[]"
					debug_print 3 critical "Non-recoverable error; aborting group method IPMI data payload compilation" true
					return 1
				;;
			esac # 1/

		else # 1/ write position corresponds to a fan header id (happy path)

			##
			# Fan ID write new fan duty level decision tree
			# 
			# 1. When all fan headers must be updated, force update of each fan header
			# fan duty level.
			#
			# When a specific fan category is targeted for change:
			# 2. Make no changes when stored fan duty level = requested fan duty level.
			# 3. When current fan header position is not part of target fan category,
			# use its last known fan duty level.
			# 4. When current fan header position is not part of target fan category,
			# and its last known fan duty level is unknown, use its starting fan duty level.
			##

			existing_duty="${ipmi_group_fan_payload[$write_position]}"

			if [ -n "$existing_duty" ] && (( existing_duty == fan_duty )); then # 2/ skip when current fan speed is known and = existing (previous) fan speed
				debug_print 4 "No change to fan duty level for write position $write_position"
				continue
			fi # 2/

			if [ "$target" = "all" ]; then # 2/ apply target fan duty to all fan headers
				ipmi_group_fan_payload["$write_position"]="$fan_duty" # assign new fan duty
				debug_print 4 "Set Fan ID $fan_id duty cycle to ${fan_duty}%"

			else # 2/ not all fans

				# pre-test fan IDs to force excluded fans to be treated as dummy fan positions
				if query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 2/
					debug_print 4 "Fan '${fan_header_name[$fan_id]}' (fan ID $fan_id) is excluded -- setting default fan duty ($dummy)"
					ipmi_group_fan_payload["$write_position"]="$dummy"
					continue
				fi # 2/

				if query_ordinal_in_binary "$fan_id" "fan_header_binary" "$fan_category"; then # 3/ does current fan id belong to target fan duty category?
					ipmi_group_fan_payload["$write_position"]="$fan_duty" # assign new fan duty
					debug_print 4 "Set Fan ID $fan_id duty cycle to ${fan_duty}%"
				else # 3/ fan header belongs to a different fan category (not same as target fan category)
					[ -n "$existing_duty" ] && continue # use previously set fan speed when known

					if [ -n "${fan_duty_last[$fan_category]}" ]; then # 4/ recycle last known fan speed assignment for this write position
						ipmi_group_fan_payload["$write_position"]="${fan_duty_last[$fan_category]}"
					else # 4/ substitute fan duty category starting fan speed as alternative solution, when known
						if [ -n "${fan_duty_start[$fan_category]}" ]; then # 5/
							ipmi_group_fan_payload["$write_position"]="${fan_duty_start[$fan_category]}"
						else # 5/
							debug_print 4 "No fallback fan duty value found for Fan ID $fan_id -- defaulting to 0"
						fi # 5/
					fi # 4/
				fi # 3/
			fi # 2/
		fi # 1/

		# catch any edge cases where a value was not assigned
		[ -z "${ipmi_group_fan_payload[$write_position]}" ] && ipmi_group_fan_payload["$write_position"]="$dummy"

	done # 1/

	# determine length of IPMI data payload before padding
	ipmi_data_payload_length="${#ipmi_group_fan_payload[@]}"

	# cannot proceed when fan data payload missing
	if (( ipmi_data_payload_length == 0 )); then # 1/ trap ordered fan speed array creation failure
		debug_print 2 warn "Ordered list of fan header duty cycle array is empty or does not exist"
		return 1
	fi # 1/

	# confirm number of data points in pending fan duty payload array equals number of elements in write position array
	if (( ipmi_data_payload_length != ${#ipmi_write_position_fan_name[@]} )); then # 1/ structural error — mismatch between payload byte length and fan name count
		debug_print 3 warn "Number of IPMI data payload elements does not match expected number" true
		debug_print 4 "Length mismatch: ipmi_data_payload_length=$ipmi_data_payload_length, array size=${#ipmi_write_position_fan_name[@]}"
		debug_print 4 "Dumping ipmi_write_position_fan_name[]:"

		for index in "${!ipmi_write_position_fan_name[@]}"; do # 2/
			debug_print 4 "  [$index] = '${ipmi_write_position_fan_name[$index]}'"
		done # 2/

		unset ipmi_group_fan_payload # discard compiled data payload elements
		return 1
	fi # 1/

	##
	# Pad end of group method data payload with dummy bytes. Need for this
	# depends on BMC schema.
	#
	# Padding is not required. When a BMC does not require padding or padding
	# the IPMI string is not desired or shunned, leaving the byte count input
	# blank (empty) or set = 0 will cause this subrotine to skip the padding
	# process. This is a perfectly acceptable outcome that is sometimes desirable.
	##

	# do not pad data payload (use as-is length) when fixed length is not defined or = 0
	(( ipmi_payload_byte_count == 0 )) && return 0

	debug_print 4 "Padding end of \"\$ipmi_group_fan_payload[]\" array with $(( ipmi_payload_byte_count - ipmi_data_payload_length )) dummy byte(s) (\"0x00\")"

	# pad end of array with dummy bytes
	for (( index = ipmi_data_payload_length; index < ipmi_payload_byte_count; index++ )); do # 1/
		ipmi_group_fan_payload+=( "$dummy" )
	done # 1/

	debug_print 4 "Compiled IPMI group fan payload:"

	for index in "${!ipmi_group_fan_payload[@]}"; do # 1/
		debug_print 4 "  [$index] = ${ipmi_group_fan_payload[$index]}"
	done # 1/

	return 0
}
