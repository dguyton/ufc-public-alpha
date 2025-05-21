# ensure no fan zone contains any excluded fans
function cleanup_excluded_fans ()
{
	local fan_category
	local fan_id
	local fan_name
	local zone_category
	local zone_id

	for fan_id in "${!fan_header_name[@]}"; do # 1/

		zone_id="${fan_header_zone[$fan_id]}" # fan zone id fan header is assigned to
		[ -z "$zone_id" ] && continue # nothing to cross-check

		fan_category="${fan_header_category[$fan_id]}" # prefix of fan group/zone binary to manipulate

		if [ -z "$fan_category" ]; then # 1/ correct errant fan header metadata
			fan_category="exclude"
			fan_header_category["$fan_id"]="exclude"
			debug_print 2 warn "Fan header '${fan_header_name[$fan_id]}' (fan ID $fan_id) had no category defined; set to 'exclude'" true
		fi # 1/

		# only process fans explicitly marked for exclusion
		[ "$fan_category" != "exclude" ] && continue

		# when fan is excluded, remove it from any fan zone in which it exists
		fan_name="${fan_header_name[$fan_id]}"

		# probe master fan zone binary
		if query_ordinal_in_binary "$zone_id" "fan_zone_binary" "master"; then # 1/
			set_ordinal_in_binary "off" "$zone_id" "fan_zone_binary" "master"
			debug_print 2 warn "Removed incorrectly tagged fan header '$fan_name' (fan ID $fan_id) from master fan zone binary" true
		fi # 1/

		for zone_category in "${fan_duty_category[@]}"; do # 2/

			[ "$zone_category" = "exclude" ] && continue # no such fan zone should exist

			if [ -n "${fan_zone_binary[$zone_category]}" ]; then # 1/
				if query_ordinal_in_binary "$zone_id" "fan_zone_binary" "$zone_category"; then # 2/
					set_ordinal_in_binary "off" "$zone_id" "zone_binary_pointer" "$zone_category"
					debug_print 2 warn "Removed incorrectly tagged fan header '$fan_name' (fan ID $fan_id) from fan zone binary: \$${zone_category}_fan_zone_binary" true
				fi # 2/
			fi # 1/
		done # 2/
	done # 1/
}
