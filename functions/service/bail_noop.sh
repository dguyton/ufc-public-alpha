##
# Bail with NO OPeration
#
# failure mode when fan execution models have not yet been configured
##

function bail_noop ()
{
	local message="$1"

 	if command -v debug_print &>/dev/null; then # 1/
		if [ -n "$message" ]; then # 2/
 			debug_print 1 critical "$message" true # print to log reason for failure when known
			send_to_syslog "$message"
		else # 2/
			debug_print 1 bold "Critical program failure. Dirty exit (no failsafe action possible)" true
		fi # 2/
	fi # 1/

	# turn off Failure Notification Handler daemon to prevent false alerts when program closes
	disable_failure_handler_daemon

	exit 255 # sayonara with exit code
}
