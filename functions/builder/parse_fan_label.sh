##
# Parse orphan fan header names and determine how they should be classified.
#
# Compares fan name to fan schema group label names.
#
# Run by Builder only.
##

function parse_fan_label ()
{
	local matching_fan_duty_category
	local fan_id
	local fan_name
	local group_id
	local group_label

	fan_id="$1"
	fan_name="$2"

	[ "$fan_control_method" = "zone" ] && return 1 # no match

	# prioritize CPU cooling fans
	if grep -qi cpu <<< "$fan_name" ; then # 1/ search inside fan name for 'cpu' string
		fan_header_category["$fan_id"]="cpu"
		return 0
	fi # 1/

	if [ "$only_cpu_fans" = true ]; then # 1/ go with the flow established via other fan header group assignments
		fan_header_category["$fan_id"]="cpu"
		return 0
	fi # 1/

	# compare fan header name to each fan group schema label
	for group_label in "${!fan_group_category[@]}"; do # 1/ compare fan name (value) to each fan group schema label (array key)
		matching_fan_duty_category="${fan_group_category[$group_label]}" # fan duty category associated with fan group label

		if grep -qi "$group_label" <<< "$fan_name" ; then # 1/ search for presence of fan group label in fan name
			fan_header_category["$fan_id"]="$matching_fan_duty_category" # if so, assign corresponding fan duty category
			debug_print 3 "Orphan fan header '$fan_name' (ID $fan_id) seems associated with fan group label '$group_label' with fan duty category type '$matching_fan_duty_category'"
		else # 1/

			##
			# 2nd tier pass.
			# If fan group label name not found in fan header name, then check if
			# fan duty category pointed to by current fan group schema label name
			# being reviewed is found in the fan header name.
			##

			if grep -qi "$matching_fan_duty_category" <<< "$fan_name" ; then # 2/ search for presence of fan duty category name in fan name
				fan_header_category["$fan_id"]="$matching_fan_duty_category" # assign the fan duty category type
				debug_print 3 warn "Fan header '$fan_name' (ID $fan_id) appears to belong to fan group '$group_label' with fan duty category type '$matching_fan_duty_category'"
			else # 2/
				debug_print 3 warn "Failed to determine a suitable fan duty category for fan header '$fan_name' (ID $fan_id)"
				return 1
			fi # 2/
		fi # 1/

		# reverse lookup the group id 
		for group_id in "${!fan_duty_category[@]}"; do # 2/ find group/zone id corresponding to fan duty type
			if [ "${fan_duty_category[$group_id]}" = "$matching_fan_duty_category" ]; then # 2/
				fan_header_zone["$fan_id"]="$group_id" # assign zone id related to fan duty category
				return 0
			fi # 2/
		done # 2/
	done # 1/

	debug_print 3 warn "Failed to determine a suitable fan duty category for fan header '$fan_name' (ID $fan_id)"
	return 1
}
