# calibrate and report active fan headers
function calibrate_active_fan_headers ()
{
	local fan_category
	local fan_id
	local fan_state_change

	local -a fan_array

	debug_print 1 "Calibrate active fan headers"

	# level set fan states
	get_fan_info all verbose true

	# comb through list of known fan headers
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/

		if [ -z "${fan_header_category[$fan_id]}" ]; then # 1/
			debug_print 4 warn "Fan ID $fan_id has no category; skipping"
			continue
		fi # 1/

		unset fan_state_change

		if [ "${fan_header_category[$fan_id]}" != "exclude" ] && [ "${fan_header_status[$fan_id]}" = "active" ]; then # 1/

			# set fan id in master tracker
			if ! query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 2/
				set_ordinal_in_binary "on" "$fan_id" "fan_header_active_binary"
				fan_state_change=true
				debug_print 4 "Fan header '${fan_header_name[$fan_id]}' (fan ID $fan_id) marked active"
			fi # 2/

			# fan zone binary string array key
			fan_category="${fan_header_category[$fan_id]}"

			if ! query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "$fan_category"; then # 2/ fan not flagged active, but it should be
				set_ordinal_in_binary "on" "$fan_id" "fan_header_active_binary" "$fan_category"
				[ "$fan_state_change" != true ] && debug_print 4 "Fan header '${fan_header_name[$fan_id]}' (fan ID $fan_id) marked active"
				fan_state_change=true
			fi # 2/

		else # 1/ fan is excluded or inactive

			# unset fan id in master tracker
			if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 2/
				set_ordinal_in_binary "off" "$fan_id" "fan_header_active_binary"
				fan_state_change=true
				debug_print 4 "Fan header '${fan_header_name[$fan_id]}' (fan ID $fan_id) marked inactive"
			fi # 2/

			fan_category="${fan_header_category[$fan_id]}"

			if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "$fan_category"; then # 2/ fan not flagged active, but it should be
				set_ordinal_in_binary "off" "$fan_id" "fan_header_active_binary" "$fan_category"
				[ "$fan_state_change" != true ] && debug_print 4 "Fan header '${fan_header_name[$fan_id]}' (fan ID $fan_id) marked inactive"
				fan_state_change=true				
			fi # 2/
		fi # 1/

		[ "$fan_state_change" = true ] && debug_print 3 "Fan header '${fan_header_name[$fan_id]}' (fan ID $fan_id) activity state changed"

	done # 1/
}
