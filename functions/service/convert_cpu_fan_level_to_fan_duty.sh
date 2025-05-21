##
# Convert human-readable CPU fan speed level to CPU fan duty cycle percentage.
#	- extrapolate cpu fan duty cycle from cpu duty level
#	- return fan duty cycle (corresponding fan speed %age)
#
# This subroutine applies to CPU fan zone only.
#
# "maximum" level does not apply, as it is only invoked when CPUs cooling is in
# panic mode (i.e. highest CPU temp exceeds critical threshold).
##

function convert_cpu_fan_level_to_fan_duty ()
{
	local level="$1" # cpu duty level (low/medium/high)
	local result

	[ "$level" = "low" ] && result=$((fan_duty_low[cpu]))
	[ "$level" = "medium" ] && result=$((cpu_fan_duty_med))
	[ "$level" = "high" ] && result=$((cpu_fan_duty_high))

	printf "%s" "$result" # return cpu duty cycle (cpu fan speed percentage)
}
