# disable specified daemon service
function stop_service_daemon ()
{
	local daemon_name	# daemon service to be stopped
	local daemon_state	# daemon service state when known

	daemon_name="$1"
	daemon_state="$2"

	[ -z "$daemon_name" ] && return 0

	debug_print 2 "Stop daemon service: $daemon_name"

	if [ "$daemon_state" = "not-found" ] || [ -z "$daemon_state" ]; then # 1/
		debug_print 1 "Daemon service not stopped because it was not found: $daemon_name"
		return 0
	fi # 1/

	send_to_syslog "stop daemon service: $daemon_name"

	if ! run_command systemctl stop "$daemon_name"; then # 1/
		debug_print 1 warn "Failed to stop daemon service '$daemon_name'"
		return 1
	fi # 1/

	debug_print 1 caution "Disabling daemon service: $daemon_name"
	send_to_syslog "disable daemon service: $daemon_name"

	# prevent automatic restart
	if ! run_command systemctl disable "$daemon_name" --now; then # 1/
		debug_print 1 warn "Failed to disable automatic daemon restarts for systemd daemon service '$daemon_name'"
		return 1
	fi # 1/

	# get daemon state again after attempting to stop it
	if daemon_state="$(get_daemon_property "$daemon_name" CollectMode)"; then # 1/
		if [ "$daemon_name" != "active" ]; then # 2/
			debug_print 4 "Stopped daemon service '$daemon_state'"
		else # 2/ failed to stop it
			debug_print 1 warn "Failed to stop daemon service '$daemon_name'"
			return 1
		fi # 2/
	else # 1/
		debug_print 1 warn "Failed to query state of daemon service '$daemon_name' after stop attempt"
		return 1
	fi # 1/

	# branch when systemctl command failed silently
	! run_command systemctl daemon-reload && debug_print 4 warn "systemctl encountered an error for an unknown reason: systemctl daemon-reload"

	# failed pre-existing daemons require complete removal
	if [ "$daemon_state" = "failed" ]; then # 1/
		! run_command systemctl reset-failed && debug_print 4 warn "systemctl encountered an error for an unknown reason: systemctl reset-failed"
	fi # 1/
}
