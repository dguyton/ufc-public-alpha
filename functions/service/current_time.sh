# report current time as epoch time
function current_time ()
{
	local result
	result="$(date +%s)" # epoch time, in seconds
	printf "%s" "$result"
}
