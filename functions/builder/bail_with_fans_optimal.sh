##
# When a catastrophic failure occurs, try to force fan duty cycle to full and exit program.
# When a pre-existing daemon service.
##

function bail_with_fans_optimal ()
{
	local message="$1"

	# return control to pre-existing daemon service fan controller as alternative to optimal mode exit
	[ -n "$runtime_daemon_service_state" ] && bail_noop "$message"

	if [ -n "$message" ]; then # 1/
 		debug_print 1 critical "$message" true # log reason for failure when known
		command -v system_logger &>/dev/null && system_logger "$message"
	else # 1/
		command -v system_logger &>/dev/null && system_logger "exit with fans set to optimal fan speed"
		debug_print 1 critical "Exit with fans set to optimal fan speed"
	fi # 1/

	# set fan mode to optimal when feasible, otherwise punt to bail_noop
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

	debug_print 1 warn "Exiting program: IPMI fan mode set to OPTIMAL or AUTOmatic mode when possible" true

	stop_service_daemon "$launcher_daemon_service_name" "$launcher_daemon_service_state"
	stop_service_daemon "$runtime_daemon_service_name" "$runtime_daemon_service_state"
	stop_service_daemon "$failure_handler_service_name" "$failure_handler_daemon_service_state"

	# attempt to set fans to automatic mode, and if that fails then use optimal speed
	set_all_fans_mode optimal
	exit # sayonara
}
