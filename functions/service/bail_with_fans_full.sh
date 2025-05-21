##
# Catastrophic failure
#	1. Stop fan controller daemon if running
# 	2. Force fan duty cycle to full
#	3. Exit program
##

function bail_with_fans_full ()
{
	local message="$1"

	# notify systemd the Service program is stopping
	systemd-notify --stop

	if [ -n "$message" ]; then # 1/
 		[ -n "$log_filename" ] && debug_print 1 critical "$message" # print to log reason for failure when known
		send_to_syslog "$message"
	fi # 1/

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

	bail_noop
}
