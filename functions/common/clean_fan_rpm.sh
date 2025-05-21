##
# Get threshold RPM value and clean it up.
# Returns integer or null.
#
# arg1: fan info to be parsed
##

function clean_fan_rpm ()
{
	local fan_speed
	local rpm

	fan_speed="$1"

	[ -z "$fan_speed" ] && return # no value to clean (input is null)

	printf "%.0f" "${fan_speed//[!.0-9]/}" # strip non-numeric characters except decimal, round up result which also drops decimal
}
