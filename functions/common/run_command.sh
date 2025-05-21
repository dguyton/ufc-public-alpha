##
# Take a command and its arguments as parameters.
#
# Branch output redirection based on whether or not program logging is enabled.
##

function run_command ()
{
	local output
	local status

	# run command (provided as separate arguments) and capture all output
	output=$("$@" 2>&1)

	# capture the exit status immediately after execution
	status=$?

	debug_print 3 "$output"

	# return status to caller
	return $status
}
