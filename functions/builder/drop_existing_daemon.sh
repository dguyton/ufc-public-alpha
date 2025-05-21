##
# Remove pre-existing service daemon .service file.
# Also remove its directory if empty after file removal.
##

function drop_existing_daemon ()
{
	local daemon_service_filename		# 
	local daemon_service_directory	# 
	local daemon_service_name		# human-readable daemon service type (e.g. Launcher)
	local parent_daemon_directory		# 

	if (( $# < 3 )); then # 1/
		debug_print 4 warn "Missing one or more required input(s)" true
		return 1
	fi # 1/

	if (( $# > 3 )); then # 1/
		debug_print 4 warn "Too many input arguments" true
		return 1
	fi # 1/

	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Missing service type designation (\$1)" true
		return 1
	fi # 1/

	if [ -z "$2" ]; then # 1/
		debug_print 3 warn "Missing or invalid daemon service filename (\$2)" true
		return 1
	fi # 1/

	if [ -z "$3" ]; then # 1/
		debug_print 3 warn "Missing or invalid daemon service directory (\$3)" true
		return 1
	fi # 1/

	daemon_service_name="$1"
	daemon_service_filename="$2"
	daemon_service_directory="$3"

	debug_print 3 "Remove pre-existing ${daemon_service_name^} daemon .service file: $daemon_service_filename"

	##
	# Remove existing daemon .service file
	##

	if [ -f "$daemon_service_filename" ]; then # 1/ daemon .service filename
		daemon_service_directory="$(dirname "$daemon_service_filename")"

		if set_target_permissions "$daemon_service_directory" PERM_WRITE_ONLY; then # 2/ minimum required access permission to remove just the target daemon .service file
			if run_command rm -f "$daemon_service_filename"; then # 3/

				##
				# Remove pre-existing daemon .service directory when it is devoid of other file system objects,
				# and dir is not root dir.
				##

				# remove trailing slash if there is one (parent dir is root)
				trim_trailing_slash daemon_service_directory

				if [ -n "$daemon_service_directory" ]; then # 4/
					if set_target_permissions "$daemon_service_directory" PERM_READ_TRAVERSE; then # 5/ need perms to scan for files and sub-dirs
						if ! run_command find "$daemon_service_directory" -type f -o -type d -o -type l -print -quit; then # 6/ no files, directories, or symbolic links remain in directory tree
							debug_print 3 "Remove empty pre-existing daemon service directory: ${daemon_service_directory}/"

							parent_daemon_directory="$(dirname "$daemon_service_directory")" # assign var to parent directory of daemon service directory
							trim_trailing_slash parent_daemon_directory

							if [ -z "$parent_daemon_directory" ]; then # 7/ parent dir of daemon service dir is root dir
								if run_command rmdir -v "$daemon_service_directory"; then # 8/ remove only the empty daemon service dir
									debug_print 2 "Successfully removed obsolete daemon service directory: $daemon_service_directory"
								else # 8/
									debug_print 2 "Failed to remove obsolete daemon service directory: $daemon_service_directory"
								fi # 8/

								return 0
							else # 7/ parent dir of daemon service dir is not root dir
								if run_command rmdir -p -v "$daemon_service_directory"; then # 8/ remove current dir and its parents/ancestors that are empty when its parent is not root dir
									debug_print 2 "Successfully removed obsolete daemon service directory: $daemon_service_directory"
								else # 8/
									debug_print 2 "Failed to remove obsolete daemon service directory: $daemon_service_directory"
								fi # 8/

								return 0
							fi # 7/

							if [ -d "$daemon_service_directory" ]; then # 7/ remove var reference after confirming dir removed
								debug_print 3 caution "Empty daemon service directory removal failed for an unknown reason: ${daemon_service_directory}/"
								return 0
							fi # 7/
						else # 6/
							debug_print 3 "Cannot remove daemon service directory because it is not empty: ${daemon_service_directory}/"
							return 0
						fi # 6/
					else # 5/
						debug_print 1 warn "Current user lacks sufficient file system permissions for daemon service parent directory: ${daemon_service_directory}/"
						return 0
					fi # 5/
				else # 4/
					debug_print 3 caution "Cannot remove directory because is is root dir"
					return 0
				fi # 4/
			else # 3/ file deletion failed
				debug_print 2 warn "Failed to remove pre-existing daemon service \"$daemon_service_filename\" for an unknown reason"
				return 1
			fi # 3/
		else # 2/
			debug_print 1 warn "Current user lacks sufficient file system permissions for daemon service parent directory: ${daemon_service_directory}/"
			return 1
		fi # 2/
	else # 1/
		if [ -e "$daemon_service_filename" ]; then # 2/
			debug_print 3 warn "Related file system object name does not exist: $daemon_service_filename"
		else # 2/
			debug_print 3 warn "Related file system object is not a normal file, and cannot be processed further"
		fi # 2/

		return 1
	fi # 1/
}
