# adjust fan speed monitoring targets associated with fan duty cycles
function cleanup_fan_speed_arrays ()
{
	local fan_id
	local -a fan_array

	convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/
		[ "${fan_speed_duty_low[$fan_id]}" -lt "${fan_speed_limit_min[$fan_id]}" ] && fan_speed_duty_low[$fan_id]="${fan_speed_limit_min[$fan_id]}"
		[ "${fan_speed_duty_med[$fan_id]}" -lt "${fan_speed_duty_low[$fan_id]}" ] && fan_speed_duty_med[$fan_id]="${fan_speed_duty_low[$fan_id]}"
		[ "${fan_speed_duty_high[$fan_id]}" -lt "${fan_speed_duty_med[$fan_id]}" ] && fan_speed_duty_high[$fan_id]="${fan_speed_duty_med[$fan_id]}"
		[ "${fan_speed_duty_max[$fan_id]}" -lt "${fan_speed_duty_high[$fan_id]}" ] && fan_speed_duty_max[$fan_id]="${fan_speed_duty_high[$fan_id]}"
	done # 1/
}
