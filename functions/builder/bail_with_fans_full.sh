##
# Catastrophic failure
#	1. Stop fan controller daemon if running
# 	2. Force fan duty cycle to full
#	3. Exit program
##

function bail_with_fans_full ()
{
	local message="$1"

	debug_print 1 critical "Shutting down pre-existing daemon services as a failsafe due to critical program failure"
	command -v system_logger &>/dev/null && system_logger "disable pre-existing daemon services and force full fan mode"

	stop_service_daemon "$launcher_daemon_service_name" "$launcher_daemon_service_state"
	stop_service_daemon "$runtime_daemon_service_name" "$runtime_daemon_service_state"
	stop_service_daemon "$failure_handler_service_name" "$failure_handler_daemon_service_state"

	if [ -n "$message" ]; then # 1/
 		debug_print 1 critical "$message" false true # print to log reason for failure when known
		command -v system_logger &>/dev/null && system_logger "$message"
	fi # 1/

	debug_print 1 critical "Exit with fans set to full speed"

	# trap missing fan write order when fan control method requires it
	case "$fan_control_method" in # 1/

		direct)
			if [ "${#ipmi_write_position_fan_id[@]}" -eq 0 ]; then # 1/
				bail_noop "Missing required fan write order array"
			fi # 1/
		;;

		group)
			if [ "${#ipmi_write_position_fan_id[@]}" -eq 0 ]; then # 1/
				bail_noop "Missing required fan write order array"
			fi # 1/
		;;

	esac # 1/

	debug_print 1 bold "Setting BMC Fan Mode to FULL power mode and bailing!" true

	set_all_fans_mode full
	exit # sayonara
}
