##
# Initial identification of active fan headers and fan zones.
#
# Called by Service Launcher only.
#
# 1. Cross-reference fan header states on system startup, relative to their expected state.
# 2. Bail when fans do not conform to expected state and discrepancy is significant.
# 3. Tag fans exhibiting certain unexpected behaviors as suspicious, for follow-up by Runtime.
##

function initialize_active_fan_headers ()
{
	local fan_category
	local fan_id
	local fan_name
	local fan_status
	local target
	local zone_id

	local -a fan_array

	debug_print 2 "Initialize active fan header and zone binary trackers"

	[ -z "$fan_header_binary" ] && bail_noop "Core fan header binary not found"

	# loop through each existing fan header as reported by Builder
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/ cycle through each inventoried fan header

		fan_name="${fan_header_name[$fan_id]}"

		if [ -z "$fan_name" ]; then # 1/
			bail_noop "Cannot continue because fan ID $fan_id has no corresponding fan header name"
			return 1
		fi # 1/

		debug_print 2 "Processing fan header '$fan_name' (fan ID $fan_id)"

		fan_status="${fan_header_status[$fan_id]}"
		debug_print 3 "Fan state: $fan_status"


--> no. this type of check will be for runtime.
--> for launcher we need to establish which fans are active, not cross-check them against known list
--> i.e. here we create the list of active fan headers, not cross-check it

		if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/ expected to be active?
			debug_print 4 "Fan '$fan_name' reference found in active fan header binary"

			if [ "$fan_status" = "active" ]; then # 2/ BMC reports fan is currently active
				debug_print 4 "BMC reports fan '$fan_name' (fan ID $fan_id) is active"

				# try to find it in one of the active fan header binaries
				for target in "${fan_duty_category[@]}"; do # 2/ scan each fan cooling type (e.g., cpu, device) for a match
					if declare -p "${target}_fan_header_active_binary" &>/dev/null; then # 3/ only check valid active binary string names
						local -n target_fan_header_active_binary="${target}_fan_header_active_binary" # indirect pointer
						query_ordinal_in_binary "$fan_id" "$target_fan_header_active_binary" && debug_print 2 caution "Assigned fan duty category: $target"
					fi # 3/
				done # 2/

--> no. move this to runtime version of this sub only.

# continuing the happy path
if (( fan_header_speed[$fan_id] > 0 )); then # 3/
	debug_print 4 "Fan header '${fan_name}' (fan ID $fan_id) reported a rotational speed of ${fan_header_speed[$fan_id]} RPM"
else # 3/
	debug_print 1 warn "Fan header '$fan_name' is active, but its reported speed is low"
	debug_print 2 warn "Marking fan header '$fan_name' as suspicious, pending follow-up"
	suspicious_fan_list["$fan_id"]="low"
	fan_header_status["$fan_id"]="unknown"
fi # 3/

				# cross-reference fan zone relationship when using zoned fan control method
				if [ "$fan_control_method" = "zone" ]; then # 3/
					zone_id="${fan_header_zone[$fan_id]}"

					if [ -n "$zone_id" ]; then # 4/
						debug_print 3 "Fan header '${fan_name}' (fan ID $fan_id) belongs to fan zone $zone_id"
					else # 4/
						debug_print 2 warn "No Zone ID found for fan header '${fan_name} (fan ID $fan_id)"
						debug_print 2 warn "Skipping fan zone association"
						bail_noop "Builder program must be re-run to generate new Service Launcher init file with corrected fan zone assignments"
						return 1
					fi # 4/
				fi # 3/
			else # 2/ fan expected to be active, but is not
				debug_print 1 critical "Fan header '$fan_name' (fan ID $fan_id) expected to be active, but is not"
				bail_with_fans_full "Re-run Builder program to generate new Service Launcher init file with corrected fan zone assignments"
				return 1
			fi # 2/
		else # 1/ master active fan binary indicates fan should be inactive
			if [ "$fan_status" = "active" ]; then # 2/ fan reported currently active (should not be)
				debug_print 1 warn "Fan '$fan_name' not expected to be active, but BMC reports it as active"

--> no dont do this - handle it better
--> if we can figure out what type of fan header it is and as necessary which zone it belongs to, then use it
--> if we cannot, then bail and force user to re-run builder

bail_noop "Re-run Builder program to generate new Service Launcher init file with correct fan header configuration"
return 1
			fi # 2/
		fi # 1/
	done # 1/
}
