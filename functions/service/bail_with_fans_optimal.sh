##
# When a catastrophic failure occurs, try to force fan duty cycle to full and exit program.
# When a pre-existing daemon service.
##

function bail_with_fans_optimal ()
{
	local message="$1"

	# notify systemd the Service program is stopping
	systemd-notify --stop

	# set fan mode to optimal when feasible, otherwise punt to bail_noop
	case "$fan_control_method" in # 1/

		direct)
			if [ "${#ipmi_write_position_fan_id[@]}" -eq 0 ]; then # 1/
				bail_noop "$message"
			fi # 1/
		;;

		group)
			if [ "${#ipmi_write_position_fan_id[@]}" -eq 0 ]; then # 1/
				bail_noop "$message"
			fi # 1/
		;;

	esac # 1/

	if [ -n "$message" ]; then # 1/
 		[ -n "$log_filename" ] && debug_print 1 critical "$message" # log reason for failure when known
		send_to_syslog "$message"
	fi # 1/

	debug_print 1 warn "Exiting program: IPMI fan mode set to OPTIMAL or AUTOmatic mode when possible" true

	# attempt to set fans to automatic mode, and if that fails then use optimal speed
	set_all_fans_mode optimal

	bail_noop
}
