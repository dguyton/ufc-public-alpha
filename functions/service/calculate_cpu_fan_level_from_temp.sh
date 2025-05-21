##
# Translate CPU temperature to human-readable level.
# This subroutine applies to CPU fan zone only.
##

function calculate_cpu_fan_level_from_temp ()
{
	local temperature="$1"
	local result

	(( temperature < cpu_temp_med )) && result="low"
	(( temperature >= cpu_temp_med )) && result="medium"
	(( temperature >= cpu_temp_high )) && result="high"

	{ (( cpu_temp_override > 0 )) && (( temperature >= cpu_temp_override )); } && result="maximum"

	printf "%s" "$result" # return human-readable CPU temp level (low/medium/high)
}
