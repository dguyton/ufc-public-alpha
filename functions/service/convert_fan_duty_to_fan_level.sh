##
# Converts fan zone duty cycle (% power) to human-readable fan level (low/medium/high/maximum).
# Sets value of specified input variable name.
#
# This subroutine is agnostic with regards to fan zone.
##

function convert_fan_duty_to_fan_level ()
{
	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Fan duty level variable name is missing"
		return
	fi # 1/

	if [ ! -v "$1" ]; then # 1/ name of global variable to assign new filename path to
		debug_print 3 warn "Invalid target variable name: $1" true
		return
	fi # 1/

	local -n duty_level_var_name="$1"

	local duty_cycle
	local duty_level
	local duty_type

	duty_type="$2"

	if [ -z "$duty_type" ]; then # 1/
		debug_print 4 warn "No fan duty category provided (\$2); nothing to analyze" true
		return
	fi # 1/

	if [ -z "${fan_duty_category[$duty_type]}" ]; then # 1/
		debug_print 4 warn "'$duty_type' is not a recognized fan duty category" true
		return
	fi # 1/

	duty_cycle=$(( ${duty_type}_fan_duty))

	duty_level="min"

	(( duty_cycle >= ${duty_type}_fan_duty_low )) && duty_level="low"
	(( duty_cycle >= ${duty_type}_fan_duty_med )) && duty_level="medium"
	(( duty_cycle >= ${duty_type}_fan_duty_high )) && duty_level="high"

	##
	# When $device_fan_override = true, non-CPU fans should be at maximum.
	# When duty type is not CPU fans, there is no minimum and the lowest
	# possible fan speed level is minimum.
	##

	if [ "$duty_type" != "cpu" ]; then # 1/
		[ "$device_fan_override" = true ] && duty_level="max"
		[ "$duty_level" = "min" ] && duty_level="low" # guard against possible invalid value
	fi # 1/

	duty_level_var_name="$duty_level"
}
