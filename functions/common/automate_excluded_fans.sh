##
# Isolate excluded fan headers and set their state to automatic fan control.
# For all other fan headers, set their state to allow manual fan control.
#
# Note that in many cases this is a matter of semantics in terms of the
# terminology. Namely, "enable automatic mode" means the same thing as
# "disable manual control mode" and vice-versa. This is poignant because
# many motherboard manufacturers refer to this process as "disabling auto
# mode" rather than "enabling manual mode." The difference in perspectives
# can create confusion.
##

function automate_excluded_fans ()
{
	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Missing array name" true
		return 1
	fi # 1/

	local disable_auto_mode
	local enable_auto_mode
	local fan_id
	local limit
	local write_position

	local -n array_pointer="$1" # name of array to populate with results

	enable_auto_mode="$2"	# value to assign to array index in order to enable automatic fan mode for given fan position
	disable_auto_mode="$3"	# value to assign to array index in order to disable automatic fan mode for given fan position
	limit="$4"			# number of array elements to populate is specified (optional)

	if [ -z "$2" ]; then # 1/
		debug_print 3 warn "Missing enable auto mode value" true
		return 1
	fi # 1/

	if [ -z "$3" ]; then # 1/
		debug_print 3 warn "Missing disable auto mode value" true
		return 1
	fi # 1/

	[ -z "$limit" ] && limit=$((fan_header_binary_length))

	if (( ${#ipmi_fan_id_write_position[@]} > 0 )); then # 1/ command bytes need to be arranged in specified write order
		for (( fan_id=0; fan_id<limit; fan_id++ )); do # 1/
			if query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 2/ fan header is excluded
				write_position="${ipmi_fan_id_write_position[$fan_id]}"

				if [ -z "$write_position" ]; then # 3/ write position undefined
					if [ -z "${array_pointer[$fan_id]}" ]; then # 4/ fan id index not already in use
						array_pointer["$write_position"]="$enable_auto_mode"
					fi # 4/
				fi # 3/
			else # 2/
				if [ -z "${ipmi_fan_id_write_position[$fan_id]}" ]; then # 3/ write position undefined
					if [ -z "${array_pointer[$fan_id]}" ]; then # 4/ fan id index not already in use
						array_pointer["${ipmi_fan_id_write_position[$fan_id]}"]="$disable_auto_mode"
					fi # 4/
				fi # 3/
			fi # 2/
		done # 1/
	else # 1/ arrange command bytes in sequential fan id order
		for (( fan_id=0; fan_id<limit; fan_id++ )); do # 1/
			if query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 2/ fan header is excluded
				array_pointer["$fan_id"]="$enable_auto_mode"
			else # 2/ arrange command bytes in sequential fan id order
				array_pointer["$fan_id"]="$disable_auto_mode"
			fi # 2/
		done # 1/
	fi # 1/
}
