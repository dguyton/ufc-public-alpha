##
# Cross-reference expected versus actual fan inventory
#
# Polls current fan inventory, cross checks it against fan header level metadata
# passed to Launcher from Builder via .init file, and creates fan header binary
# strings. The latter then become authoritative and will be passed on to the
# Runtime program.
#
# Service Launcher only.
#
# Unknown fans (not indicated via Builder created .init file) are not allowed.
# If a new, unrecognized fan header is discovered, the program aborts.
##

function validate_fan_inventory ()
{
	local error_condition
	local fan_category
	local fan_id			# numeric fan id number
	local fan_info			# each line of IPMI sensor output to be parsed
	local -u fan_name		# name of fan reported by IPMI
	local schema_type

	debug_print 1 "Cross-reference physical fan headers against expected inventory"

	[ "$fan_control_method" = "zone" ] && schema_type="zone" || schema_type="group"

	# begin with a blank slate
	fan_header_binary="$(flush "$fan_header_binary_length")"

	# also flush category-level fan header binaries
	for fan_category in "${fan_duty_category[@]}"; do # 1/
		fan_header_binary["$fan_category"]="$(flush "$fan_header_binary_length")"
	done # 1/

	##
	# Poll the current environment of fans. This will be the starting reference point
	# to which fan metadata passed from the Builder will be compared. These data sets
	# should match. If there is a discrepancy, it is a sign of one of two possible
	# causes:
	#
	# 1) something in the server environment has changed since the Builder
	# was run; OR
	# 2) there is an inconsistency with how IPMI is returning fan header
	# information - particularly fan header order - meaning the order is random
	# depending on when the IPMI command is run.
	#
	# In theory, error scenario 2 should never occur. However, if it ever does, UFC
	# is not designed to handle such an anomaly and will not fit this use case.
	##

	while read -r fan_info; do # 1/ parse each line of IPMI fan sensor scan

		parse_ipmi_column "fan_name" "sensor" "fan" "name" "$fan_info"
		[ -z "$fan_name" ] && continue # skip lines with no fan name

		debug_print 2 "Discovered fan header $fan_name"

		# lookup fan header id
		fan_id="${fan_header_id["$fan_name"]}"

		# bail when an unknown fan header is discovered
		if [ -z "$fan_id" ]; then # 1/
			debug_print 1 critical "Discovered non-recognized fan header '$fan_name' (not cataloged by Builder)"
			bail_noop "Builder must be re-run in order to resolve this anomaly"
		fi # 1/

		debug_print 4 "Fan header '$fan_name' = ID $fan_id"

		# validate category-specific fan header binary
		fan_category="${fan_header_category[$fan_id]}"

		if [ -z "$fan_category" ]; then # 1/ trap missing fan category association
			debug_print 2 warn "Excluding fan header '$fan_name' (fan ID $fan_id) because its fan duty category is unknown"
			fan_header_category["$fan_id"]="exclude"
			error_condition=true
			continue
		fi # 1/

		# when fan header not found in its expected category specific fan header binary, exclude it from further consideration
		if query_ordinal_in_binary "$fan_id" "fan_header_binary" "$fan_category"; then # 1/ duplicate fan entry
			debug_print 2 warn "Ignoring duplicate fan header entries found for fan ID '$fan_id'" true
			error_condition=true
			continue
		fi # 1/

		set_ordinal_in_binary "on" "$fan_id" "fan_header_binary"
		set_ordinal_in_binary "on" "$fan_id" "fan_header_binary"

	done <<< "$($ipmitool sensor | grep -i fan)" # 1/ use short-hand IPMI output for brevity

	if binary_is_empty "$fan_header_binary"; then # 1/ bail when no fans were assigned to master fan header binary tracker
		debug_print 1 critical "No fan headers were discovered that align with fan header metadata cataloged by Builder"
		bail_noop "Re-run Builder to resolve this discrepancy"
	fi # 1/

	[ "$error_condition" = true ] && debug_print 1 critical "Re-run Builder to resolve discovered anomalies"

	if declare -p exclude_fan_zone_binary &>/dev/null; then # 1/
		debug_print 1 critical "Program error: 'exclude_fan_zone_binary' created, but never should be" true
		unset exclude_fan_zone_binary
	fi # 1/

	return 0
}
