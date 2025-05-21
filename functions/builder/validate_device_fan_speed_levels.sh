##
# Determine RPM fan speed equivalent of device cooling fan duty cycle
# power percentages applied to each individual fan header. Record the
# results for each fan header.
#
# Set fan speed thresholds associated with different fan speed levels.
#
# Calculate approximate RPM speed expected that is equivalent to fan speed level,
# based on maximum fan speed of each particular fan.
#
# When a particular fan maximum speed is unknown, use the maximum speed of the
# slowest device cooling fan to calculate an equivalent fan duty cycle. While this
# creates a risk of artificially inflating the starting point of each fan duty
# cycle level, this practice ensures the duty cycle level will not be set to a
# proportionally lower level than that which any given fan should be operating.
# In other words, this practice ensures that no fan spins too slowly in order to
# attain the desired fan duty performance level (e.g. low/medium/high cooling).
##

function validate_device_fan_speed_levels ()
{
	local fan_category
	local fan_id

	local -a fan_array

	[ "$only_cpu_fans" = true ] && return # no independent disk device fans

	fan_category="$1"

	debug_print 4 "Estimate rotational fan speed equivalents of '$fan_category' fan duty cycles"

	# estimate equivalent rotational fan speed for each active device header at each fan duty cycle level
	convert_binary_to_array "${fan_header_active_binary[$fan_category]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/
		if [ -n "${fan_speed_limit_max[$fan_id]}" ]; then # 2/
			fan_speed_duty_low["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_low" "${fan_speed_limit_max[$fan_id]}")"
			fan_speed_duty_med["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_med" "${fan_speed_limit_max[$fan_id]}")"
			fan_speed_duty_high["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_high" "${fan_speed_limit_max[$fan_id]}")"
			fan_speed_duty_max["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_max" "${fan_speed_limit_max[$fan_id]}")"
		else # 2/ calculate ratios based on slowest top speed of any device fan
			fan_speed_duty_low["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_low" "${fan_speed_lowest_max[default]}")"
			fan_speed_duty_med["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_med" "${fan_speed_lowest_max[default]}")"
			fan_speed_duty_high["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_high" "${fan_speed_lowest_max[default]}")"
			fan_speed_duty_max["$fan_id"]="$(convert_duty_cycle_to_rpm "$device_fan_duty_max" "${fan_speed_lowest_max[default]}")"
		fi # 2/
	done # 1/
}
