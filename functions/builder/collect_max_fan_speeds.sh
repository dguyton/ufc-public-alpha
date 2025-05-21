# Record maximum fan speeds (RPMs) for every fan, regardless of state
function collect_max_fan_speeds ()
{
	local fan_category
	local fan_id
	local highest_rpm
	local rpm

	# explicitly set fan control mode to manual (i.e. not automatic)
	debug_print 3 "Establish IPMI manual fan control"
	debug_print 2 "Spin all fans up to maximum allowed speed"

	# Set IPMI fan mode to Full. This allows fan duty cycles to be manipulated.
	set_all_fans_mode full # this also sets fan speed to max duty cycle

	# wait a bit to ensure fans gain momentum before reading their speeds
	debug_print 3 "Waiting for fans to ramp up..."

	# wait a bit for fans to adjust
	sleep "$fan_speed_delay"

	# refresh current speeds of all active fan headers and get current BMC thresholds
	get_fan_info all quiet true

	debug_print 2 "Calculate top speed of each fan"

	# parse all fans, even those not marked active
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array"

	# analyze fan data for each member of this category
	for fan_id in "${!fan_array[@]}"; do # 1/

		# record top speed RPM value for each fan
		fan_speed_limit_max["$fan_id"]="${fan_header_speed[$fan_id]}"

		fan_category="${fan_header_category[$fan_id]}"
		[ "$fan_category" = "exclude" ] && continue # skip excluded fan headers

		if [ -z "${fan_speed_lowest_max[$fan_category]}" ] || [ "${fan_speed_limit_max[$fan_id]}" -lt "${fan_speed_lowest_max[$fan_category]}" ]; then # 1/
			fan_speed_lowest_max["$fan_category"]="$fan_speed_limit_max[$fan_id]}"
		fi # 1/

	done # 1/

	highest_rpm=0
	for rpm in "${fan_speed_limit_max[@]}"; do
		(( rpm > highest_rpm )) && highest_rpm=$rpm
	done # 1/ find highest rpm

	debug_print 2 "Highest observed RPM of all fans: $highest_rpm"
}
