##
# Active fan header discovery
#
# Examine state of every fan header.
# Refresh list of currently active fan headers.
#
# Tag fans as suspicious when a fan header shows
# signs of odd behavior, or a fan header appears active
# that was previously marked inactive.
##

function active_fan_sweep ()
{
	local counter
	local fan_id
	local fan_name

	local -a fan_array
	local -a fan_mismatch_active		# messaging tracker related to suspicious fans presumed active which are acting inactive
	local -a fan_mismatch_inactive	# messaging tracker related to suspicious fans presumed inactive which are acting active

	# skip when server in CPU panic cooling mode
	[ "$device_fan_override" = true ] && return 0

	# validate current fan status snapshots against active fan header records
	debug_print 2 "Starting active fan header discovery"

	# get quantified state (not simplified state) of all fans
	get_fan_info all quiet false

	##
	# Since this subroutine gets run periodically, it provides
	# a good opportunity to cross-check for condition when all
	# fan headers appear to be offline, as a precaution.
	##

	# houston, we have a problem - no active fan headers
	binary_is_empty "$fan_header_active_binary" && bail_with_fans_optimal "Aborting program because no actve fan headers were detected"

	# gather list of all existing fan headers, regardless of recorded state or fan duty category
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/ check every fan header
		if query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 1/ ignore when previously excluded
			[ "${fan_header_status[$fan_id]}" != "panic" ] && continue
			debug_print 2 warn "Excluded fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) observed in panic mode" # unless they are in panic mode, in which case advise
			continue
		fi # 1/

		debug_print 3 "$fan_id state: ${fan_header_status[$fan_id]}"

		case "${fan_header_status[$fan_id]}" in # 1/

			##
			# Watch for signs of inactive fans showing evidence of activity.
			# But ignore those fans if they are on the exclusionary list.
			##

			ok|active)
				if ! query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/ fan expected to be inactive / bad / unknown, but detected as active
					debug_print 2 caution "Fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) observed state change to \"ACTIVE\" status"
					debug_print 3 caution "Fan will be marked as suspicious and monitored"
					fan_mismatch_active[$fan_id]="${fan_header_status[$fan_id]}" # fan expected to be inactive / bad / unknown, but detected as active
				fi # 1/
			;;

			panic)
				if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/
					debug_print 3 warn "Fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) in panic mode"
				else # 1/
					debug_print 3 caution "Inactive fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) in panic mode"
					debug_print 4 "This could be normal, depending on server state and motherboard design"
				fi # 1/
			;;

			bad|inactive)
				if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/ previously reported active
					debug_print 2 caution "Fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) expected state ACTIVE but observed state is ${fan_header_status[$fan_id]^^}"
					fan_mismatch_inactive[$fan_id]="${fan_header_status[$fan_id]}" # fan expected to be active, but detected as inactive, bad, or unknown
				fi # 1/
			;;

			unknown)
				if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/ previously reported active
					debug_print 2 caution "Fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) expected state ACTIVE but observed state is ${fan_header_status[$fan_id]^^}"
					fan_mismatch_inactive[$fan_id]="${fan_header_status[$fan_id]}" # fan expected to be active, but detected as inactive, bad, or unknown
				fi # 1/
			;;

			*)
				debug_print 3 warn "Invalid fan state \"${fan_header_status[$fan_id]}\" for ${fan_header_name[$fan_id]} (fan ID $fan_id)" true
				debug_print 4 "Ignoring for now"
			;;
		esac # 1/

		##
		# When current fan header was previously tagged as suspicious,
		# store the prior reading separately. In order to be confirmed
		# as suspicous, a fan header must report an odd status at least
		# twice, on consecutive scans. This prevents the program from
		# alerting the end user unnecessarily when an unusual fan status
		# report is a one-time or brief anomaly or due to a one-off poor
		# or failed sensor read.
		##

		# discovered fan state mis-match
		if [ -n "${fan_mismatch_active[$fan_id]}" ] || [ -n "${fan_mismatch_inactive[$fan_id]}" ]; then # 1/
			[ -n "${suspicious_fan_list[$fan_id]}" ] && suspicious_fan_list_old[$fan_id]="${suspicious_fan_list[$fan_id]}" # archive prior suspicious state when there is one
			suspicious_fan_list[$fan_id]="${fan_header_status[$fan_id]}" # mark fan as suspicious for follow-up investigation
			debug_print 3 caution "Fan header ID $fan_id ( ${fan_header_name[$fan_id]} ) flagged as suspicious, pending follow-up investigation before final disposition is determined"
		else # 1/ reset suspicous fan tracker when fan header state matches its expected fan state
			if [ -n "${suspicious_fan_list[$fan_id]}" ]; then # 2/
				unset "suspicious_fan_list[$fan_id]"
				debug_print 4 caution "Reset suspicious fan state as fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) appears to have normalized"
			fi # 2/
		fi # 1/
	done # 1/

	# mark unusual fans as suspicious when fan header anomalies are discovered
	if (( ${#fan_mismatch_active[@]} > 0 )) || (( ${#fan_mismatch_inactive[@]} > 0 )); then # 1/
		(( ${#fan_mismatch_active[@]} > 0 )) && debug_print 4 "Suspicious fan(s) alert: ${#fan_mismatch_active[@]} fans presumed active, but reported as inactive"
		(( ${#fan_mismatch_inactive[@]} > 0 )) && debug_print 4 "Suspicious fan(s) alert: ${#fan_mismatch_inactive[@]} fans presumed inactive, but reported as active"

# report number of fans of each type when they changed

<<>>

--> this might need to be re-factored to include:
--> 1. new array that tracks number of fans assigned to each fan type so we can track when it changes
--> 2. replace code block below with a loop that compares all fan duty categories with >0 fans associated

		counter=0 # set default in case function call fails for any reason
		count_active_ordinals_in_binary "fan_header_active_binary" "cpu" "counter"

		if (( counter != cpu_fan_count )); then # 2/
			debug_print 2 "Total number of CPU cooling fans : $counter"
			count_active_ordinals_in_binary "fan_header_active_binary" "cpu" "counter"
			debug_print 2 "Number of active CPU cooling fans: $counter"
		fi # 2/
	fi # 1/

	##
	# Set timer for suspicious fan validation when one or more
	# fan headers were flagged as suspicious by this subroutine,
	# and the timer was not already active.
	##

	if (( ${#suspicious_fan_list[@]} > 0 )); then # 1/
		if [ -z "$suspicious_fan_timer" ]; then # 2/ suspicious fans found and timer not already set
			suspicious_fan_timer=$(( $(current_time) + suspicious_fan_validation_delay ))
			debug_print 3 "Start suspicious fan validation countdown timer"
		else # 2/
			debug_print 4 "Suspicious fan timer already set"
		fi # 2/
	fi # 1/
}
