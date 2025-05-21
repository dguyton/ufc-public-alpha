# report current time in human-readable 24-hour format
function build_time_string ()
{
	local result
	result="$(date +%H:%M:%S)" # HH:MM:SS
	printf "%s" "$result"
}
