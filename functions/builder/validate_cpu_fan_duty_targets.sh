##
# Validate CPU fan duty level targets
#
# Validate user-declared settings with regards to fan duty level %-ages.
# Generally requires minimum 10% spread between duty levels (low/med/high).
#
# - Only matters when CPU fan control is allowed
# - Occurs after minimum CPU fan speeds have been determined
# - Occurs after lower BMC fan speed thresholds have been adjusted, if warranted
#
# Forces a 10% minimum buffer between duty cycle levels.
##

function validate_cpu_fan_duty_targets ()
{
	[ "$cpu_fan_control" != true ] && return # only relevant when actively managing cpu fan zone

	debug_print 3 "Calculate CPU fan speed (RPM) thresholds of fan duty target levels"

	if (( fan_duty_low[cpu] < fan_duty_min[cpu] )) || (( fan_duty_low[cpu] > cpu_fan_duty_high )); then # 1/
		debug_print 3 warn "Low CPU fan duty cycle (fan_duty_low[cpu]) out of range"
		debug_print 2 "fan_duty_low[cpu] value changed from ${fan_duty_low[cpu]} to ${fan_duty_min[cpu]}"
		fan_duty_low[cpu]=$((fan_duty_min[cpu]))
	fi # 1/

	if (( cpu_fan_duty_med < fan_duty_low[cpu] + 10 )); then # 1/
		debug_print 3 warn "Medium CPU fan duty cycle (cpu_fan_duty_med) cannot be less than or equal to Low fan duty setting (fan_duty_low[cpu])"
		cpu_fan_duty_med=$(( fan_duty_low[cpu] + 10 ))
		debug_print 2 "cpu_fan_duty_med value changed to $cpu_fan_duty_med"
	fi # 1/

	if (( cpu_fan_duty_high < cpu_fan_duty_med + 10 )); then # 1/
		debug_print 3 warn "Medium CPU fan duty cycle (cpu_fan_duty_med) cannot be greater than High fan duty setting (cpu_fan_duty_high)"
		cpu_fan_duty_med=$(( ( cpu_fan_duty_high + fan_duty_low[cpu] ) / 2 )) # midpoint between low and high
		debug_print 2 "cpu_fan_duty_med value changed to $cpu_fan_duty_med"
	fi # 1/

	if (( cpu_fan_duty_max < cpu_fan_duty_high )); then # 1/
		debug_print 3 warn "Maximum CPU fan duty cycle (cpu_fan_duty_max) cannot be less than High fan duty setting (cpu_fan_duty_high)"
		cpu_fan_duty_max=$((cpu_fan_duty_high))
		debug_print 2 "cpu_fan_duty_max value changed to $cpu_fan_duty_max"
	fi # 1/

	# cpu initial fan speed duty cycle when service program begins
	if (( cpu_fan_duty_start < fan_duty_min[cpu] )); then # 1/ protect cpu
		debug_print 2 "CPU fan duty start specified in configuration ($cpu_fan_duty_start%) is too low. Reset to minimum CPU fan speed ($fan_duty_min[cpu]%)"
		cpu_fan_duty_start=$((fan_duty_min[cpu])) # full power to the shields
	fi # 1/

	if (( cpu_fan_duty_start > cpu_fan_duty_max )); then # 1/ cannot exceed max
		debug_print 2 "CPU fan duty start specified in configuration ($cpu_fan_duty_start%) is too high (exceeds fan max duty $cpu_fan_duty_max%)"
		cpu_fan_duty_start=$((cpu_fan_duty_max)) # full power to the shields
	fi # 1/

	if [ "${fan_speed_min[cpu]}" -gt 0 ]; then # 1/ min cpu fan speed declared by user in config file
		debug_print 3 "Minimum rotational CPU fan speed (RPM) declared in config file"
	else # 1/ no global minimum cpu fan speed
		debug_print 4 caution "Minimum rotational CPU fan speed (RPM) not specified in config file"
		debug_print 3 "Estimated minimum rotational CPU fan speed (RPM) will be calculated based on observed maximums"
	fi # 1/
}
