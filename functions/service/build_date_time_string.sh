##
# Report current date/time in human-readable date/24-hour format.
#
# When an input argument is specified, report the date/time of
# the specified epoch time (in seconds), converted to human-
# readable format.
##

function build_date_time_string ()
{
	local result

	if [ -n "$1" ]; then # 1/
		result="$(date "+%Y-%m-%d %T" -d "$1")" # date/time of epoch time $1
	else # 1/
		result="$(date "+%Y-%m-%d %T")" # date/time of current epoch time
	fi # 1/

	printf "%s" "$result"
}
