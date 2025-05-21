##
# When not recycling incumbent service program and daemon service files,
# remove old Service programs file and/or daemon service files that exist.
# Also remove their directories when there is no other use for the
# directory (i.e. no other file system objects remain in them).
##

function remove_dir_and_files ()
{
	local directory
	local type

	directory="$1"
	type="$2"

	# remove pre-existing Service Launcher files and/or sub-directories
	if [ -n "$directory" ]; then # 1/
		debug_print 3 "Scrub pre-existing Service $type program directory and its files"

		if validate_file_system_object "$directory" directory; then # 2/ validate dir exists
			if set_target_permissions "$directory" PERM_WRITE_TRAVERSE; then # 3/ need traverse + write permissions to remove files from parent dir

				##
				# Note: Dir of old Service Launcher dir will not be root dir, as if it were, this
				# variable would be null (set = null by 'set_recycle_daemons_mode' subroutine).
				# However, it is possible its parent dir could be root dir.
				##

				if set_target_permissions "$(dirname "$directory")" PERM_WRITE_TRAVERSE; then # 4/ need traverse + write permissions for parent of parent dir

					##
					# Remove old dir and its contents with failsafe not to remove root dir.
					# If command fails or dir still exists afterwards, then deletion failed.
					##

					if ! run_command rm -r -f -v --preserve-root "${directory:?}" || validate_file_system_object "$directory" directory; then # 5/ file and/or dir removal failed
						bail_with_fans_optimal "Failed to remove pre-existing Service $type directory and its contents for an unknown reason: $directory"
					fi # 5/
				else # 4/ access error
					debug_print 2 warn "Current user lacks sufficient file system permissions to parent dir of old Service $type directory"
				fi # 4/
			else # 3/ access error
				debug_print 2 warn "Current user lacks sufficient file system permissions to remove old Service $type directory and its files"
			fi # 3/
		else # 2/ dir not there
			debug_print 3 caution "Could not validate directory: ${directory}/"
		fi # 2/
	fi # 1/
}

function remove_old_service_files ()
{
	local failure_handler_parent_daemon_dir
	local launcher_parent_daemon_dir
	local runtime_parent_daemon_dir

	# nothing to do when there are no pre-existing daemons
	[ -z "$recycle_service_daemons" ] && return 0

	##
	# Stop the Failure Notification Handler (FNH) daemon service if it is running.
	# This prevents automatic error messaging when other daemons are stopped.
	##

	# stop FNH daemon regardless of recycle_service_daemons mode (true/false)
	[ -n "$failure_handler_service_name" ] && stop_service_daemon "$failure_handler_service_name" "$failure_handler_daemon_service_state"

	##
	# When recycling pre-existing implementation, only remove the pre-existing
	# Service Launcher initialization file, as it will need to be re-created.
	##

	if [ "$recycle_service_daemons" = true ]; then # 1/
		debug_print 4 bold "Attempt to recycle pre-existing Service program implementation"

		if [ -n "$service_launcher_init_filename" ]; then # 2/
			debug_print 3 "Remove pre-existing Service Launcher initialization file: $service_launcher_init_filename"

			if set_target_permissions "$(dirname "$service_launcher_init_filename")" PERM_WRITE_ONLY; then # 3/ need write permission for parent dir
				if run_command rm -v "$service_launcher_init_filename"; then # 4/
					if [ -f "$service_launcher_init_filename" ]; then # 5/ old file removal failed
						debug_print 2 warn "Failed to remove pre-existing init file from incumbent Service Launcher program directory"
						debug_print 3 "Cannot replace incumbent Service Launcher initialization (.init) file"
						recycle_service_daemons=false
					fi # 5/
				else # 4/
					debug_print 2 warn "Failed to remove incumbent Service Launcher .init file"
					recycle_service_daemons=false
				fi # 4/
			else # 3/
				debug_print 2 warn "Failed to remove incumbent Service Launcher .init file due to restricted parent directory access"
				recycle_service_daemons=false
			fi # 3/
		else # 2/
			debug_print 3 warn "Something went wrong with prior determination of \$service_launcher_init_filename state"
			recycle_service_daemons=false
		fi # 2/
	fi # 1/

	# stop here when recycling pre-existing implementation
	[ "$recycle_service_daemons" = true ] && return 0

	debug_print 4 warn "Recycling pre-existing implementation not possible"

	##
	# Discard FNH daemon when not recycling incumbent install
	##

	# disable and remove pre-existing FNH daemon
	if [ -n "$failure_handler_daemon_service_state" ] && [ "$failure_handler_daemon_service_state" != "not-found" ]; then # 1/
		if drop_existing_daemon "Failure Notification Handler" "$failure_handler_daemon_service_filename" "$service_failure_handler_target_dir"; then # 2/
			unset failure_handler_service_name
			unset failure_handler_daemon_service_state
		else # 2/
			debug_print 3 caution "Failed to remove pre-existing Failure Notification Handler daemon service"
		fi # 2/
	fi # 1/

	#################################################
	# Proceed When Not Recycling Pre-Existing Install
	#################################################

	##
	# When not recycling previous installation, all pre-existing daemons
	# must be stopped and dropped. FNH daemon was stopped above. Now stop
	# Launcher and Runtime daemons, if they exist.
	##

	debug_print 2 "Disable pre-existing Service related systemd daemons"

	# disable pre-existing daemons before continuing
	if [ -n "$launcher_daemon_service_name" ]; then # 1/
		if ! stop_service_daemon "$launcher_daemon_service_name" "$launcher_daemon_service_state"; then # 2/
			bail_noop "Cannot continue due to failure to stop systemd daemon: '$launcher_daemon_service_name'"
		fi # 2/
	fi # 1/

	if [ -n "$runtime_daemon_service_name" ]; then # 1/
		if ! stop_service_daemon "$runtime_daemon_service_name" "$runtime_daemon_service_state"; then # 2/
			bail_noop "Cannot continue due to failure to stop systemd daemon: '$runtime_daemon_service_name'"
		fi # 2/
	fi # 1/

	###########################################################
	# Remove Pre-existing Daemon .service Files and Directories
	###########################################################

	# remove pre-existing Service program daemon files and directories, set parent daemon dir global variable
	if [ -n "$runtime_daemon_service_state" ] && [ "$runtime_daemon_service_state" != "not-found" ]; then # 1/
		if ! drop_existing_daemon "Runtime" "$runtime_daemon_service_filename" "$runtime_daemon_service_dir"; then # 2/
			debug_print 2 caution "Failed to remove pre-existing Service Runtime daemon service"
		fi # 2/
	fi # 1/

	if [ -n "$launcher_daemon_service_state" ] && [ "$launcher_daemon_service_state" != "not-found" ]; then # 1/
		if ! drop_existing_daemon "Launcher" "$launcher_daemon_service_filename" "$launcher_daemon_service_dir"; then # 2/
			debug_print 3 caution "Failed to remove pre-existing Service Launcher daemon service"
		fi # 2/
	fi # 1/

	##
	# Determine if pre-existing daemon service files are in a single, shared directory tree.
	# Retain the shared parent directory reference when it makes sense to do so.
	#
	# Do not force delete existing daemon .service file directories when they are not empty.
	#
	# Failure handler location is irrelevant, and thus will be ignored for this calculation.
	##

	if [ -n "$launcher_daemon_service_dir" ]; then # 1/ Launcher dir not empty
		if [ -z "$runtime_daemon_service_dir" ]; then # 2/ Runtime dir empty or not unique
			daemon_service_dir="$launcher_daemon_service_dir" # place new daemon services under single, shared dir
		else # 2/ neither Launcher nor Runtime daemon dirs are empty, are they the same dir?
			if [ "$launcher_parent_daemon_dir" = "$runtime_parent_daemon_dir" ]; then # 3/ not empty, common/shared dir
				daemon_service_dir="$launcher_parent_daemon_dir"
			else # 3/ neither dir is empty, and they are not the same
				if [ "$(dirname "$launcher_parent_daemon_dir")" = "$(dirname "$runtime_parent_daemon_dir")" ]; then # 4/ check if dir parents match
					daemon_service_dir="$(dirname "$launcher_parent_daemon_dir")" # move shared dir up one level
				else # 4/
					debug_print 4 caution "Failed to identify a common ancestor directory for all daemon service files"
				fi # 4/
			fi # 3/
		fi # 2/
	fi # 1/

	debug_print 3 "Failure Notification Handler daemon service file parent directory: $failure_handler_parent_daemon_dir"
	[ "$failure_handler_parent_daemon_dir" != "$daemon_service_dir" ] && debug_print 4 "Failure Notification Handler daemon service file parent directory differs from Launcher and Runtime daemon parent dir"

	##########################################################################
	# Delete Pre-existing Fan Controller Service Program Files and Directories
	##########################################################################

	##
	# As there should be no files in these directories other than those
	# pertaining to the Service programs, it should be safe to unilaterally
	# remove the related files and their directory trees.
	##

	# target_dir pre-defined in config file and not same as old target dir
	if [ -n "$target_dir_old" ] && [ -n "$target_dir" ] && [ "$target_dir_old" != "$target_dir" ]; then # 1/ old target dir exists and old target dir differs from new target dir
		debug_print 2 "Clean-up old Service program related directories when they differ from target directories and are now empty"

		# remove pre-existing Service Launcher files and/or sub-directories
		debug_print 2 "Remove pre-existing Service program files and directories"
		remove_dir_and_files "$service_launcher_target_dir_old" "Launcher"

		# remove pre-existing Service Runtime files and/or sub-directories
		debug_print 3 "Scrub pre-existing Service Runtime program directory and its files"
		remove_dir_and_files "$service_runtime_target_dir_old" "Runtime"

		# remove pre-existing Service Failure Notification Handler files and/or sub-directories
		debug_print 3 "Scrub pre-existing Service Failure Notification Handler program directory and its files"
		remove_dir_and_files "$service_failure_handler_target_dir_old" "Failure Notification Handler"

		# remove pre-existing Service include files and/or sub-directories
		debug_print 3 "Scrub pre-existing Service include files directory and its contents"
		remove_dir_and_files "$service_functions_target_dir_old" "include files"

		if [ -n "$target_dir_old" ] && validate_file_system_object "$target_dir_old" directory; then # 2/
			run_command rmdir -v "$target_dir_old"
		fi # 2/
	fi # 1/

	# tracking dir vars no longer needed
	unset service_launcher_target_dir_old # dir containing old Service Launcher program
	unset service_runtime_target_dir_old # dir containing old Service Runtime program
	unset service_failure_handler_target_dir_old # dir containing old FNH program
	unset service_functions_target_dir_old # dir containing old Service include files

	# alert user if any pre-existing program files were not removed
	validate_file_system_object "$service_launcher_target_filename" file && debug_print 3 warn "Failed to remove pre-existing Service Launcher program filename: $service_launcher_target_filename"
	validate_file_system_object "$service_runtime_target_filename" file && debug_print 3 warn "Failed to remove pre-existing Service Launcher program filename: $service_runtime_target_filename"

	# attempt to explicitly remove pre-existing FNH script when it was not removed previously
	if validate_file_system_object "$service_failure_handler_target_filename" file; then # 1/
		debug_print 4 "Remove pre-existing Service Launcher program filename: $service_failure_handler_target_filename"

		if ! run_command rm -f "$service_failure_handler_target_filename"; then # 2/
			if [ -f "$service_failure_handler_target_filename" ]; then # 3/
				debug_print 3 caution "Failed to remove pre-existing Service Launcher program filename: $service_failure_handler_target_filename"
			fi # 3/
		fi # 2/
	fi # 1/
}
