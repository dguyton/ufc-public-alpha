##
# Determine full filename path of executable program file referenced in systemd daemon
# service (.service) file.
#
# Parameters:
#	$1 - daemon service name
#
# Returns full filename path of daemon .service file belonging to $1 daemon service name.
##

function extract_daemon_executable ()
{
	local daemon_service_name
	local daemon_service_exec_filename
	local service_daemon_dump

	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Missing daemon service name (\$1)" true true
		return 1
	fi # 1/

	daemon_service_name="$1"

	debug_print 3 "Identify pre-existing fan controller program executable path for daemon service name '$daemon_service_name'"

	# get daemon program executable pointer
	if ! daemon_service_exec_filename="$(get_daemon_property "$daemon_service_name" ExecStart)"; then # 1/ {var to populate in this subroutine} {name of global var} {filter}
		debug_print 3 warn "Failed to extract associated executable program file path"
		return 1
	fi # 1/

	daemon_service_exec_filename="${daemon_service_exec_filename#*{ path=}"
	daemon_service_exec_filename="${daemon_service_exec_filename%% ;*}"
	daemon_service_exec_filename="${daemon_service_exec_filename}//[\'\"]/}" # remove single and dual quotation marks

	# try alternate method when parsing .service config file failed
	if [ -z "$daemon_service_exec_filename" ]; then # 1/ alternatively, parse results of systemctl cat
		debug_print 4 "Attempt alternate method of parsing .service file after systemctl query failed"

		daemon_service_exec_filename="$(printf "%s" "$service_daemon_dump" | grep -i 'execstart=')"
		daemon_service_exec_filename="$(printf "%s" "$daemon_service_exec_filename" | sed "s/execstart=/execstart=/I")"
		daemon_service_exec_filename="${daemon_service_exec_filename#*execstart=}"
		daemon_service_exec_filename="${daemon_service_exec_filename}//[\'\"]/}"
	fi # 1/

	# verify parsed filename is legitimate
	if validate_file_system_object "$daemon_service_exec_filename" "file"; then # 1/
		debug_print 4 "ExecStart file path: $daemon_service_exec_filename"
		printf "%s" "$daemon_service_exec_filename" # return result indirectly via global var
		return 0
	else # 1/
		debug_print 4 warn "ExecStart file path could not be determined"
		return 1
	fi # 1/
}
