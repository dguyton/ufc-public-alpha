##
# Retrieve property of a daemon service via systemctl.
#
# Parameters:
#   $1 - Name of daemon service name
#   $2 - Property filter to use with systemctl
#
# Return daemon value of $filter
##

function get_daemon_property ()
{
	local daemon_service_name
	local daemon_state
	local filter

	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Daemon service name is missing from function call (\$1)"
		return 1
	fi # 1/

	if [ -z "$2" ]; then # 1/
		debug_print 4 warn "Daemon search property filter is missing from function call (\$2)" true
		return 1
	fi # 1/

	daemon_service_name=$1
	filter="$2" # systemctl property to filter

	# verify no errors in command, record its output to program log, and assign its output to a variable
	if run_command systemctl show "$daemon_service_name" -p "$filter"; then # 1/
		daemon_state="$(systemctl show "$daemon_service_name" -p "$filter")"
	else # 1/
		debug_print 4 warn "systemctl command failed for daemon service name: $daemon_service_name"
		return 1
	fi # 1/

	daemon_state="${daemon_state#*=}" # parse right of first = after indicated daemon property

	##
	# Look for file path information if daemon property contains it
	# Note there are many daemon properties, and most do not contain a file path.
	##

	if grep -qi 'path=' <<< "$daemon_state"; then # 1/ parse file path when one exists
		daemon_state="${daemon_state#*path=}"
		daemon_state="${daemon_state%% ;*}"
	fi # 1/

	# no daemon state found
	if [ -z "$daemon_state" ]; then # 1/
		debug_print 4 warn "Failed to determine daemon state"
		return 1
	else # 1/
		debug_print 4 "Daemon state: $daemon_state"
		printf "%s" "$daemon_state"
		return 0
	fi # 1/
}
