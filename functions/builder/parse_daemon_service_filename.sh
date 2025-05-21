##
# Determine full filename path of systemd daemon service (.service) file
# belonging to specified systemd daemon name.
#
# Parameters:
#	$1 - daemon service name
#
# Returns full filename path of daemon .service file belonging to $1 daemon service name.
##

function parse_daemon_service_filename ()
{
	local daemon_service_name			# daemon service name
	local daemon_service_filename_parsed
	local service_daemon_dump

	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Daemon service name to be parsed not specified (\$1)" true
		return 1
	fi # 1/

	daemon_service_name="$1"

	debug_print 4 "Name of global variable to populate with filename path of pre-existing daemon .service file: $1"
	debug_print 4 "Name of daemon service to evaluate: $daemon_service_name"

	# bail when no daemon service name provided
	[ -z "$daemon_service_name" ] && return 1

	# extract full path and directory of pre-existing daemon .service file
	service_daemon_dump="$(systemctl cat "$daemon_service_name")"
	daemon_service_filename_parsed="$(printf "%s" "$service_daemon_dump" | head -n 1)" # first line contains the path
	daemon_service_filename_parsed="${daemon_service_filename_parsed#*# }" # retain full path filename

	if [ -n "$daemon_service_filename_parsed" ]; then # 1/ found existing daemon and successfully parsed its .service filename path
		debug_print 3 "Daemon service filename is valid: $daemon_service_filename_parsed"
		printf "%s" "$daemon_service_filename_parsed" # return result (.service full filename path) via indirect global var reference
		return 0
	else # 1/ failed to parse .service file path

		##
		# Try alternate method of determining .service filename and directory paths when
		# process above fails.
		##

		debug_print 3 warn "Failed to parse full path of daemon .service file"
		debug_print 4 "Attempt alternate .service path detection method to parse file location"

		daemon_service_filename_parsed="$(systemctl status "$daemon_service_name" | grep -i 'loaded:')"
		daemon_service_filename_parsed="${daemon_service_filename_parsed#* (}" # drop text before open parentheses
		daemon_service_filename_parsed="${daemon_service_filename_parsed%%;*}" # parse full filename path before first close bracket

		if [ -n "$daemon_service_filename_parsed" ]; then # 2/
			debug_print 3 "Pre-existing daemon .service file location: $daemon_service_filename_parsed"
			prntif "%s" "$daemon_service_filename_parsed" # return .service full filename path
			return 0
		else # 2/ still failed to parse daemon .service file path
			debug_print 4 "Failed to identify an existing .service filename path matching indicated daemon service name"
			return 1
		fi # 2/
	fi # 1/
}
