##
# Bail with NO OPeration
#
# failure mode when fan execution models have not yet been configured
##

function bail_noop ()
{
	local message="$1"
	local verbose_exit="$2"

	# presume verbosity is desired unless explicitly excluded
	[ "$verbose_exit" != false ] && verbose_exit=true

	if [ -n "$message" ]; then # 1/ log reason for failure when known
		if [ "$verbose_exit" = true ]; then # 2/ output trace debug to terminal
			debug_print 1 critical "$message" true true
		else # 2/
			debug_print 1 critical "$message" false true # no trace debug
		fi # 2/

		# add note in system log
		command -v system_logger &>/dev/null && system_logger "$message"
	else # 1/
		debug_print 1 bold "Critical program failure. Dirty exit (no failsafe action possible)" true "$verbose_exit"
	fi # 1/

	##
	# daemon states are used as the logic branch below because they will only be non-null after
	# any existing daemon service has been validated. Whereas other daemon related variables may
	# be false positives, depending on when in the program workflow this exit routine is triggered.
	##

	stop_service_daemon "$launcher_daemon_service_name" "$launcher_daemon_service_state"
	stop_service_daemon "$runtime_daemon_service_name" "$runtime_daemon_service_state"
	stop_service_daemon "$failure_handler_service_name" "$failure_handler_daemon_service_state"

	exit 255 # sayonara
}
