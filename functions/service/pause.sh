##
# Helper function to manage short pauses in program operations.
# After a brief wait period, the current time tracker should be
# reset, in order to properly handle various timer expirations.
##

function pause ()
{
	local wait_for_it

	# validate indicated wait timer
	if [ -n "$1" ]; then # 1/
		wait_for_it="$1"
		wait_for_it=$((wait_for_it)) # must be an integer
	fi # 1/

	# use global default when not specified or invalid
	(( wait_for_it == 0 )) && wait_for_it=$((wait_timer))

	# pause/wait (in seconds)
	sleep $((wait_for_it))

	# set global current time tracker after wait period
	check_time="$(current_time)" # current time in seconds (from Epoch)
}
