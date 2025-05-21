function validate_cpu_fan_speed_levels ()
{
	debug_print 4 "Estimate rotational fan speed equivalents of CPU fan duty cycles"

	# calculate minimum fan speed for each active cpu fan
	convert_binary_to_array "${fan_header_active_binary[cpu]}" "cpu_fan_list"

	##
	# For each fan, calculate expected fan speed equivalent of CPU fan duty cycles.
	##

	for fan_id in "${!cpu_fan_list[@]}"; do # 1/ calibrate RPM speed for each fan duty cycle, for each CPU fan
		if (( fan_speed_limit_max["$fan_id"] > 0 )); then # 1/ individual cpu max fan speed is known
			fan_speed_duty_low["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_low[cpu]}" "${fan_speed_limit_max[$fan_id]}")"
			fan_speed_duty_med["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_med[cpu]}" "${fan_speed_limit_max[$fan_id]}")"
			fan_speed_duty_high["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_high[cpu]}" "${fan_speed_limit_max[$fan_id]}")"
			fan_speed_duty_max["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_max[cpu]}" "${fan_speed_limit_max[$fan_id]}")"
		else # 1/ use universal max fan speed when particular fan max speed is unknown
			debug_print 4 "Fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) has unknown maximum fan speed"
			debug_print 3 "Settings for ${fan_header_name[$fan_id]} (fan ID $fan_id) based on slowest observed maximum speed of all CPU fans"

			fan_speed_duty_low["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_low[cpu]}" "${fan_speed_lowest_max[cpu]}")"
			fan_speed_duty_med["$fan_id"]="$(convert_duty_cycle_to_rpm "$cpu_fan_duty_med" "${fan_speed_lowest_max[cpu]}")"
			fan_speed_duty_high["$fan_id"]="$(convert_duty_cycle_to_rpm "$cpu_fan_duty_high" "${fan_speed_lowest_max[cpu]}")"
			fan_speed_duty_max["$fan_id"]="$(convert_duty_cycle_to_rpm "$cpu_fan_duty_max" "${fan_speed_lowest_max[cpu]}")"
		fi # 1/
	done # 1/
}
