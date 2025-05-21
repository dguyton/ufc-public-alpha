##
# Re-calibrate active fan zones.
#
# Service Runtime use only.
#
# Should be run anytime a fan header is enabled or disabled.
#
# - Applies only when operating with zoned fan control method.
# - Re-calibrates which fan zones are active.
##

function calibrate_active_fan_zones ()
{
	[ "$fan_control_method" != "zone" ] && return # no point in executing this sub

	local fan_category
	local fan_id
	local fan_name
	local zone_id

	local -a fan_array

	# reset master record of all active fan zones (agnostic to their fan duty category)
	fan_zone_active_binary="$(flush_binary "$fan_zone_binary_length")"

	# Reset state of every possible active fan zone.
	#
	# Note this skips the "exclude" fan duty category, because while it is a valid fan duty category,
	# it can never be active as it is simply a placeholder binary string for disqualified fan headers.
	# In other words, there is no such fan zone prefix.
	#
	# Also, we do not want to eliminate the master list of all existing fan zones, the goal here is to
	# re-evaluate all _active_ fan zones in case they have changed due to a recent change in teh state
	# of one or more fan headers.
	##

	# reset all active fan zone duty categories
	for fan_category in "${fan_duty_category[@]}"; do # 1/
		if declare -p "${fan_category}_fan_zone_active_binary" &>/dev/null; then # 1/ skip non-existent active fan zone binaries

			# redirect pointer to each fan duty category of active fan zone binary tracker
			local -n category_fan_zone_active_binary="${fan_category}_fan_zone_active_binary"

			# reset each fan duty category active fan zone binary tracker
			category_fan_zone_active_binary="$(flush_binary "$fan_zone_binary_length")"
		fi # 1/
	done # 1/

	##
	# Restore active fan zone binaries, with each fan one-by-one
	##

	# review each active fan header and tag its associated fan zone
	convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/ loop thru every active fan header
		fan_name="${fan_header_name[$fan_id]}"
		zone_id="${fan_header_zone[$fan_id]}" # lookup its fan zone id

		if [ -z "$zone_id" ]; then # 1/ bail when fan zone id is unknown because cannot reset active fan zones (should never happen)
			bail_with_fans_full "Failed to identify fan zone of fan header '$fan_name' (fan ID $fan_id)"
			return 1
		fi # 1/

		# bail when zone id of current fan header is invalid (not found set in any fan duty category binary)
		for fan_category in "${fan_duty_category[@]}"; do # 2/

			# trap unknown/invalid fan duty categories (no corresponding fan header binary)
			if ! declare -p "${fan_category}_fan_zone_binary" &>/dev/null; then # 1/
				debug_print 1 critical "Fan duty category associated with fan header '$fan_name' is invalid: $fan_category"
				bail_noop "Fan header '$fan_name' (fan ID $fan_id) reported an invalid active fan zone binary tracker name of '${fan_category}_fan_zone_binary'"
			fi # 1/

			# set uber active fan zone binary
			if ! query_ordinal_in_binary "$zone_id" "$fan_zone_active_binary"; then # 1/ zone not set yet
				set_ordinal_in_binary "on" "$zone_id" "fan_zone_active_binary"
				debug_print 4 "Tagged fan zone ID $zone_id as active in master active fan zone binary tracker"
			fi # 1/

			# mark fan zone active in specific fan duty category tracker
			local -n fan_category_zone_active_binary="${fan_category}_fan_zone_active_binary"

			if ! query_ordinal_in_binary "$zone_id" "$fan_category_zone_active_binary"; then # 1/ duty category specific active zone binary not set yet
				set_ordinal_in_binary "on" "$zone_id" "fan_category_zone_active_binary"
				debug_print 4 "Related fan zone ID $zone_id to fan duty category '$fan_category' active fan zone binary tracker"
			fi # 1/
		done # 2/
	done # 1/
}
