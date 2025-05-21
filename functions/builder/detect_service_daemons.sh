##
# Detect presence of previously installed Service program daemons.
#
# Determine whether or not Service Launcher program, Service Runtime program,
# and Failure Notification Handler daemon services exist. If they do, evaluate
# their current operating status, determine location of their incumbent
# daemon service files, determine the program files pointed by them, and
# their program file version. Then determine if all metrics match those of
# current Builder version.
##

function detect_service_daemons ()
{
	local version

	##
	# 1. Evaluate pre-existing daemon services, if any.
	# 2. Search for daemon service templates and perform related preparatory work.
	# 3. Identify incumbent service program directories when relevant.
	# 4. Determine if pre-existing service daemons can be recycled (re-used).
	#
	# NOTE: When a decision is made to recycle a pre-existing Service implementation, if the
	# user specified a different directory location in the Builder config file (.conf), the
	# latter will be ignored.
	##

	debug_print 2 "Scan for incumbent fan controller systemd daemon services"

	##
	# Scan for pre-existing Service Launcher daemon service.
	#
	# This command below gathers data on the most probable pre-existing
	# daemon service, if there is one.
	##

	#######################################################
	# Evaluate Pre-Existing Service Launcher Daemon Service
	#######################################################

	##
	# Set daemon service name to scan for to default name. The default name
	# should be an amalgamation of the overall Service Name of the program,
	# along with a unique identifier string that corresponds with the purpose
	# of the given daemon service (e.g. "launcher" for the Service Launcher
	# daemon).
	#
	# After running this name through the daemon scanner, it is possible to
	# determine success/fail of the scanning operation, based on the actions
	# taken by the daemon scanner function.
	#
	# The outcome of the daemon scan directly influences pre-existing daemon
	# validation, which in turn directly influences the decision of whether
	# or not to recycle pre-existing Service program daemons, when they exist.
	#
	# If the daemon scan successfully validated the provided default/expected
	# daemon service name, then it means there is a pre-existing service daemon
	# matching the expected (default) service name.
	##

	# default/presumed pre-existing daemon service name, if there is one
	[ -z "$launcher_daemon_service_name_default" ] && return 1 # connot proceed

	launcher_daemon_service_name="$launcher_daemon_service_name_default"

	##
	# Search for presence of default Launcher daemon service name and get its .service filename.
	#
	# args: {$1:daemon service name} {$2: daemon service filename} {$3: daemon service directory} {$4: daemon name filter}
	##

	if ! daemon_scan launcher_daemon_service_name launcher_daemon_service_filename launcher_daemon_service_dir launcher; then # 1/
		debug_print 2 "Discovered pre-existing fan controller Service Launcher daemon service: $launcher_daemon_service_name"

		##
		# Follow-up by getting the current state of the known Service Launcher
		# daemon service.
		##

		if launcher_daemon_service_state="$(get_daemon_property "$launcher_daemon_service_name" ActiveState)"; then # 2/
			debug_print 4 "Current Service Launcher daemon state: $launcher_daemon_service_state"

			##
			# Launcher daemon provides custom status updates to systemd, which may not resemble
			# typical status messages. Therefore, they need to be parsed.
			##

			case "${launcher_daemon_service_state,,}" in # 1/

				*active*)
					launcher_daemon_service_state="active"
				;;

				*error*)
					launcher_daemon_service_state="error"
				;;

				fail*)
					launcher_daemon_service_state="failed"
				;;

				stop*)
					launcher_daemon_service_state="stop"
				;;
			esac # 1/

			# branch based on derived daemon state
			case "$launcher_daemon_service_state" in # 1/
				active)
					debug_print 3 "Pre-existing daemon service exists and is currently active"
					bail_noop "Service Launcher is currently running; run Builder after it finishes"
					;;

				error)
					debug_print 3 "Pre-existing Launcher daemon service exited with an unknown error (FAILED)"
					;;

				inactive)
					debug_print 3 "Pre-existing daemon service exists, but is not currently active"
					debug_print 4 "This behavior is expected"
					;;

				failed)
					debug_print 3 warn "Pre-existing daemon service exists but failed for an unknown reason"
					;;

				stop|stopped)
					debug_print 3 warn "Pre-existing daemon service exists but was stopped for an unknown reason"
					debug_print 4 "Treat Launcher daemon service state as INACTIVE"
					launcher_daemon_service_state="inactive"
					;;

				*)
					debug_print 3 warn "Status of pre-existing daemon service could not be determined, and will be treated as FAILED"
					launcher_daemon_service_state="failed"
					;;
			esac # 1/

			##
			# Extract pre-existing Service program location.
			#
			# Attempt to extrapolate Service program (.sh) filenames from daemon service file.
			# Daemon service files contain a pointer to the path of their related executable file.
			##

			if [ -n "$launcher_daemon_service_filename" ]; then # 3/
				debug_print 3 "Parse pre-existing fan controller Service Launcher program location from its daemon .service file"

				##
				# When the daemon service program executable pointer filename
				# cannot be verified, the Service Launcher executable target
				# value will be set to null. This will cause the Builder program
				# to populate it with a default path.
				##

				if ! service_launcher_target_filename="$(extract_daemon_executable "$launcher_daemon_service_name")"; then # 4/
					debug_print 2 caution "Pre-existing Service Launcher daemon service existence could not be confirmed"
					unset launcher_daemon_service_name
					unset launcher_daemon_service_state
				fi # 4/
			fi # 3/
		else # 2/
			debug_print 2 caution "Pre-existing Service Launcher daemon service existence could not be confirmed"
			unset launcher_daemon_service_name
			unset launcher_daemon_service_state
		fi # 2/
	else # 1/ drop name and state but keep filename for future use
		debug_print 2 caution "Could not confirm existence of incumbent Service Launcher daemon service"
		unset launcher_daemon_service_name
		unset launcher_daemon_service_state
	fi # 1/

	######################################################
	# Evaluate Pre-Existing Service Runtime Daemon Service
	######################################################

	# search for pre-existing Service Runtime daemon service
	runtime_daemon_service_name="$runtime_daemon_service_name_default"

	if ! daemon_scan runtime_daemon_service_name runtime_daemon_service_filename runtime_daemon_service_dir runtime; then # 1/
		debug_print 2 "Discovered pre-existing fan controller Service Runtime daemon service: $runtime_daemon_service_name"

		# get current state of daemon service
		if runtime_daemon_service_state="$(get_daemon_property "$runtime_daemon_service_name" ActiveState)"; then # 2/
			debug_print 4 "Current Service Runtime daemon state: $runtime_daemon_service_state"

			# branch based on derived daemon state
			case "$runtime_daemon_service_state" in # 1/
				active)
					debug_print 3 "Pre-existing daemon service exists and is currently active"
					debug_print 4 "This behavior is expected"
					;;

				inactive)
					debug_print 3 "Pre-existing daemon service exists, but is not currently active"
					debug_print 4 "Check logs if service was not disabled intentionally"
					;;

				fail|failed)
					debug_print 3 warn "Pre-existing daemon service exists but failed for an unknown reason"
					debug_print 4 "Check logs for clues on possible cause"
					runtime_daemon_service_state="failed"
					;;

				stop|stopped)
					debug_print 3 warn "Pre-existing daemon service exists but was stopped for an unknown reason"
					debug_print 4 "Check logs if service was not stopped intentionally"
					runtime_daemon_service_state="inactive"
					;;
			esac # 1/

			# get pointers to executable program within each daemon .service file (execstart)
			if [ -n "$runtime_daemon_service_filename" ]; then # 3/
				debug_print 3 "Parse pre-existing fan controller Service Runtime program location from its daemon .service file"

				if ! service_runtime_target_filename="$(extract_daemon_executable "$runtime_daemon_service_name")"; then # 4/
					debug_print 2 caution "Pre-existing Service Launcher daemon service existence could not be confirmed"
					unset runtime_daemon_service_name
					unset runtime_daemon_service_state
				fi # 4/
			fi # 3/
		else # 2/
			debug_print 2 caution "Pre-existing Service Runtime daemon service existence could not be confirmed"
			unset runtime_daemon_service_name
			unset runtime_daemon_service_state
		fi # 2/
	else # 1/
		debug_print 2 caution "Could not confirm existence of incumbent Service Runtime daemon service"
		unset runtime_daemon_service_name
		unset runtime_daemon_service_state
	fi # 1/

	###################################################################
	# Evaluate Pre-Existing Failure Notification Handler Daemon Service
	###################################################################

	##
	# The daemon scanner only validates whether or not the expected (default) daemon
	# name exists, and if so, its associated executable file location. It does not
	# evaluate the corresponding executable's suitability (e.g. proper file type and
	# matching version).
	#
	# When no match is found, it scans for possible matches and seeds the program log
	# with its findings.
	#
	# When there is no pre-existing daemon and/or related FNH program script found,
	# or there is a problem with the daemon, the error condition will be handled by
	# other processes (e.g. set_recycle_daemons_mode subroutine).
	##

	failure_handler_service_name="$failure_handler_service_name_default"

	if daemon_scan failure_handler_service_name failure_handler_daemon_service_filename service_failure_handler_target_dir failure; then # 1/
		debug_print 2 "Discovered pre-existing fan controller Service Failure Notification Handler daemon service: $failure_handler_service_name"

		if failure_handler_daemon_service_state="$(get_daemon_property "$failure_handler_service_name" ActiveState)"; then # 2/
			debug_print 4 "Current Service Failure Notification Handler daemon state: $failure_handler_daemon_service_state"

			case "$failure_handler_daemon_service_state" in # 1/ branch based on derived daemon state
				fail|failed)
					debug_print 3 warn "Pre-existing daemon service exists but failed for an unknown reason"
					debug_print 4 "This will disallow the possibility of recycling pre-existing Service program implementation"
					failure_handler_daemon_service_state="failed"
					;;

				stop|stopped)
					debug_print 3 warn "Pre-existing daemon service exists but was stopped for an unknown reason"
					debug_print 4 "Check logs if service not stopped intentionally"
					failure_handler_daemon_service_state="inactive"
					;;
			esac # 1/

			# get pointers to executable program within each daemon .service file (execstart)
			if [ -n "$failure_handler_daemon_service_filename" ]; then # 3/
				debug_print 3 "Parse pre-existing Failure Notification Handler program location from its daemon .service file"

				if ! service_failure_handler_target_filename="$(extract_daemon_executable "$failure_handler_service_name")"; then # 4/
					debug_print 3 caution "Failure Notification Handler daemon could not be confirmed"
					unset failure_handler_service_name
					unset failure_handler_daemon_service_state
				fi # 4/
			fi # 3/
		else # 2/
			debug_print 3 caution "Pre-existing Failure Notification Handler daemon service existence could not be confirmed"
			unset failure_handler_service_name
			unset failure_handler_daemon_service_state
		fi # 2/
	else # 1/
		debug_print 3 caution "Could not confirm existence of incumbent Failure Notification Handler daemon service"
		unset failure_handler_service_name
		unset failure_handler_daemon_service_state
	fi # 1/

	#########################################################
	# Stop when Either Launcher or Runtime Service is Missing
	#########################################################

	# stop when either Service Launcher or Runtime daemon is not pre-existing
	if [ -z "$launcher_daemon_service_name" ]; then # 1/
		if [ -z "$runtime_daemon_service_name" ]; then # 2/
			debug_print 1 "No pre-existing Service daemons found"
			return 1
		else # 2/
			debug_print 4 "Pre-existing Service Runtime daemon found, but corresponding Launcher daemon not found"
			return 1
		fi # 2/
	else # 1/
		if [ -z "$runtime_daemon_service_name" ]; then # 2/
			debug_print 4 "Pre-existing Service Launcher daemon found, but corresponding Runtime daemon not found"
			return 1
		fi # 2/
	fi # 1/

	####################################################################################
	# Compare Pre-Existing Service Program Executable Version Numbers to Builder Version
	####################################################################################

	debug_print 3 "Deduce version of each pre-existing Service program executable"
	debug_print 4 "Daemon .service file versions match, but ExecStart pointers need to be confirmed as well"

	if [ -n "$service_launcher_target_filename" ]; then # 1/ pre-existing filename detected above
		if query_target_permissions "$service_launcher_target_filename" PERM_READ_ONLY; then # 2/
			if service_program_version_old="$(parse_file_version "$service_launcher_target_filename")"; then # 3/ parse Launcher version, ok if null/empty
				if [ -n "$service_program_version_old" ]; then # 4/
					debug_print 3 "Pre-existing Service Launcher program version: $service_program_version_old"
				else # 4/
					debug_print 3 "Service Launcher program version undefined or could not be determined"
				fi # 4/

				if [ "$service_program_version_old" = "$builder_program_version" ]; then # 4/ must match Builder version
					debug_print 2 "Pre-existing Service Launcher program version matches that of this Builder program"
					return 0 # ok to re-use pre-existing Service programs when their version known and matches current Builder
				else # 4/ investigate further when not obviously a match
					if [ -n "$service_runtime_target_filename" ]; then # 5/
						if version="$(parse_file_version "$service_runtime_target_filename")"; then # 6/ ensure version check process does not fail and sets value of $version
							if [ "$version" = "$service_program_version_old" ]; then # 7/ compare Runtime program version to Launcher
								debug_print 2 "Pre-existing Runtime program version matches pre-existing Launcher and this Builder"
							else # 7/
								debug_print 2 "Pre-existing Service Runtime program version does NOT match pre-existing Launcher version"
								service_program_version_old="fail"
							fi # 7/
						else # 6/ no program version reference at all
							debug_print 3 "Pre-existing Service Runtime program version is invalid or could not be determined"
							service_program_version_old="fail"
						fi # 6/
					else # 5/ no Runtime program to inspect
						debug_print 3 "Pre-existing Service Runtime program file not found"
						service_program_version_old="fail" # automatic failure when process parsing old Runtime program version fails
					fi # 5/
				fi # 4/
			else # 3/
				debug_print 3 "An error occurred while attempting to parse this file: $service_launcher_target_filename"
				service_program_version_old="fail"
			fi # 3/
		else # 2/
			debug_print 3 "Current user lacks sufficient file system permissions to analyze referenced program executable"
			service_program_version_old="fail"
		fi # 2/
	else # 1/ no Launcher program to inspect
		debug_print 3 "Pre-existing Service Launcher program file not found"
		service_program_version_old="fail"
	fi # 1/

	##
	# When version matching fails, return an explicit condition of failure.
	# This prevents confusion between circumstances when null or no match is
	# a success state because there is no program version number (which is ok),
	# versus when there was a failure in the process to determine version
	# number of one or more components.
	#
	# Thhe use of a "fail" version ID allows for globally understood, and
	# explicit error condition handling.
	##

	# automatic failure when old Runtime version is incorrect
	[ "$service_program_version_old" = "fail" ] && return 1
}
