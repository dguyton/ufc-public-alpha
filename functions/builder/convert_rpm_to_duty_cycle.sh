##
# Convert current fan RPM speed to corresponding fan speed percentage
#
# Note: a small offset is added for duty cycles < 50% to account for tendency
# of formula to under-estimate actual required fan duty when fan speed is low.
##

function convert_rpm_to_duty_cycle ()
{
	local fan_speed_rpm
	local speed_limit_rpm
	local fan_duty_cycle

	fan_speed_rpm="$(printf "%0.f" "$1")"
	speed_limit_rpm="$(printf "%0.f" "$2")"

	if [ "$speed_limit_rpm" -gt 0 ]; then # 1/ return percentage $1 of $2
		fan_duty_cycle="$(printf "%.0f" "$(awk "BEGIN { print ( (int( $fan_speed_rpm / $speed_limit_rpm ) * 100 )) }")")"

		# pad ratios below 50% to compensate for typical fan undervolting at low speeds
		[ "$fan_duty_cycle" -lt 50 ] && fan_duty_cycle=$(( fan_duty_cycle + 10 ))
	else # 1/ return zero when denominator invalid
		fan_duty_cycle=0
	fi # 1/

	# cap maximum at highest allowed fan duty percentage
	[ "$fan_duty_cycle" -gt "$fan_duty_limit" ] && fan_duty_cycle="$fan_duty_limit"

	printf "%d" "$fan_duty_cycle"
}
