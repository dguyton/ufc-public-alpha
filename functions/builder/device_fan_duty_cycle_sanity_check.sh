# Validate device cooling fan duty cycle settings. Do fan speed limits and duty cycles make sense?
function device_fan_duty_cycle_sanity_check ()
{

for key in "${!fan_duty_min[@]}"; do # 1/

<<>>

	if [ "$device_fan_duty_low" -lt "$device_fan_duty_min" ]; then # 2/
		debug_print 2 warn "Invalid program setting --> Low device fan duty cycle cannot be less than device fan minimum duty setting"
		debug_print 3 "device_fan_duty_low < device_fan_duty_min ($device_fan_duty_low < $device_fan_duty_min)"
		device_fan_duty_low=$(( device_fan_duty_min + 1 ))
		debug_print 3 "device_fan_duty_low value changed to $device_fan_duty_low"
	fi # 2/

	if [ "$device_fan_duty_med" -le "$device_fan_duty_low" ]; then # 2/
		debug_print 2 warn "Invalid program setting --> Medium device fan duty cycle cannot be less than Low device fan duty setting"
		debug_print 3 "device_fan_duty_med <= device_fan_duty_low ($device_fan_duty_med <= $device_fan_duty_low)"
		[ "$device_fan_duty_low" -lt "$fan_duty_limit" ] && device_fan_duty_med=$(( device_fan_duty_low + 1 )) || device_fan_duty_med="$device_fan_duty_low"
		debug_print 3 "device_fan_duty_med value changed to $device_fan_duty_med"
	fi # 2/

	if (( device_fan_duty_high <= device_fan_duty_med )); then # 2/
		debug_print 2 warn "Invalid program setting --> High device fan duty cycle cannot be less than Medium device fan duty setting"
		debug_print 3 "device_fan_duty_high <= device_fan_duty_med ($device_fan_duty_high <= $device_fan_duty_med)"
		[ "$device_fan_duty_med" -lt "$fan_duty_limit" ] && device_fan_duty_high=$((device_fan_duty_med + 1 )) || device_fan_duty_high="$device_fan_duty_med"
		debug_print 3 "device_fan_duty_high value changed to $device_fan_duty_high"
	fi # 2/

	if [ "$device_fan_duty_high" -gt "$device_fan_duty_max" ]; then # 2/
		debug_print 2 warn "Invalid program setting --> High device fan duty cycle cannot be higher than Maximum device fan duty setting"
		debug_print 3 "device_fan_duty_high > device_fan_duty_max ($device_fan_duty_high > $device_fan_duty_max)"
		device_fan_duty_high="$device_fan_duty_max"
		debug_print 3 "device_fan_duty_high value reduced from $device_fan_duty_high to $device_fan_duty_max"
	fi # 2/

	{ [ "$device_fan_duty_start" -lt "$device_fan_duty_min" ] || [ "$device_fan_duty_start" -eq 0 ]; } && device_fan_duty_start="$device_fan_duty_min" # validate starting duty cycle
}
