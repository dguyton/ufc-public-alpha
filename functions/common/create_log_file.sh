##
# Shared subroutine designed to validate the directory and filename
# of a proposed log file, and to create said log file when current
# user permissions allow it.
#
# Return status: 0 (success) or 1 (failure)
##

function create_log_file ()
{
	local filename_archive			# archived pre-existing log file with same filename
	local filename_base
	local file_extension			# filename extension
	local log_dir					# parent directory of log file (full path)
	local log_dir_parent			# parent directory of directory containing log file
	local -l service_user_override	# when = true, Service user treated as log file owner

	if [ -z "$1" ]; then # 1/
		debug_print 2 warn "Global variable name containing log filename not specified in function call (\$1)" true
		return 1
	fi # 1/

	local -n log_file="$1" # indirect pointer to name of global log filename variable containing full path log filename

	# determines whether target user type is Service user (true) or not (false)
	service_user_override="$2"
	[ "$service_user_override" != true ] && service_user_override=false

	debug_print 1 "Create new log file: $log_file"

	file_extension="${log_file##*.}"

	case "$file_extension" in # 1/
		log|json)
			debug_print 3 "Log file extension: .${file_extension}"
		;;

		*)
			[ -n "$file_extension" ] && debug_print 4 caution "Non-standard file extension: $file_extension"
		;;
	esac # 1/

	if [ -z "$file_extension" ]; then # 1/
		file_extension="log"
		debug_print 3 "Failed to deduce log file extension from log filename" true
		debug_print 2 "Log file extension set to default: .${file_extension}"
	fi # 1/

	##
	# Verify log dir exists in the first place.
	# If it does not, create it.
	##

	log_dir="$(dirname "$log_file")"
	trim_trailing_slash "log_dir"

	if [ -z "$log_dir" ]; then # 1/ log dir cannot be root dir
		debug_print 2 warn "Log files cannot be stored in root directory"
		debug_print 3 warn "Abort new log file creation"
		log_file=""
		return 1
	fi # 1/

	if ! validate_file_system_object "$log_dir" directory "$service_user_override"; then # 1/
		debug_print 3 "Specified log directory '$log_dir' does not exist and must be created"

		log_dir_parent="$(dirname "$log_dir")"

		# when parent dir of log dir exists, current user needs ability to create log dir under it as sub-dir
		if validate_file_system_object "$log_dir_parent" directory "$service_user_override"; then # 2/ parent dir exists and is accessible to specified user
			if ! set_target_permissions "$log_dir_parent" PERM_WRITE_TRAVERSE "$service_user_override"; then # 3/ failed to grant sufficient access to parent dir
				debug_print 2 warn "Cannot create new log file because current user lacks sufficient access rights to its parent directory"
				debug_print 3 warn "Abort new log file creation"
				log_file=""
				return 1
			fi # 3/
		fi # 2/

		# create new log directory
		if ! run_command mkdir -p -v "$log_dir"; then # 2/ creation failed
			debug_print 2 warn "Failed to create new log directory for an unknown reason"
			debug_print 3 warn "Abort new log file creation"
			log_file=""
			return 1
		fi # 2/
	fi # 1/

	##
	# Ensure user has sufficient permissions at the parent directory
	# level of the proposed log file path name to create a new log file.
	##

	debug_print 3 "Verify related file system permissions"

	# verify log directory and its parent directory permissions are suitable relative to Service user
	if ! set_target_permissions "$log_dir" PERM_WRITE_TRAVERSE "$service_user_override"; then # 1/
		debug_print 2 warn "Cannot create new log file because current user lacks sufficient permissions for its directory"
		return 1
	fi # 1/

	debug_print 4 "User has sufficient permissions to directory of log file: ${log_dir}/"

	# deal with pre-existing file system object with same filename path as proposed new log file
	debug_print 4 "Check for pre-existing, conflicting file system objects"

	##
	# 1. When specified log filename is already in use, attempt to archive/rename it before continuing.
	# 2. If old file exists and cannot be archived, delete it.
	# 3. When old file exists and cannot be archived or removed, abort.
	##

	if [ -e "$log_file" ]; then # 1/ any type of file system object with same name and path is pre-existing
		debug_print 3 caution "Attempt to archive pre-existing log file with identical filename and path"

		##
		# Do not attempt to archive it when it is not a normal file
		##

		if ! validate_file_system_object "$log_file" file "$service_user_override"; then # 2/
			debug_print 3 warn "Cannot archive and replace pre-existing file system object, because it is not a regular file"
			debug_print 2 warn "Abort new log file creation"
			log_file=""
			return 1
		fi # 2/

		##
		# Attempt to archive pre-existing file
		##

		# pre-existing file exists with identical filename and path
		debug_print 3 caution "Archive pre-existing log file"

		# separate base filename
		filename_base="${log_file%.*}"

		# calculate archive filename to use
		filename_archive="${filename_base}_backup.${file_extension}"

		##
		# When log file should be archived, but there is also a pre-existing file system object
		# conflicting with archive filename and path, attempt to resolve the conflicting archive
		# filename first, before attempting to archive pre-existing log file.
		##

		if [ -e "$filename_archive" ]; then # 2/ file system object with archive log filename also already exists
			debug_print 3 caution "Detected pre-existing file system object with same name and path as proposed archive filename"

			if ! validate_file_system_object "$filename_archive" file; then # 3/ do not try to remove it when not a normal file
				debug_print 2 warn "Failed to create new log file due to conflicting pre-existing file system object"
				debug_print 3 warn "Pre-existing archived file system object will not be removed because it is not a normal file"
				debug_print 4 "Abort new log file creation"
				log_file=""
				return 1
			fi # 3/

			##
			# Attempt to replace old archive file with pre-existing, old log file
			##

			debug_print 3 caution "Remove pre-existing archive file"

			if ! run_command rm -f "$filename_archive"; then # 3/ remove failed
				debug_print 2 warn "Failed to create new log file due to conflicting pre-existing file system object"
				debug_print 3 warn "Failed to remove pre-existing archive file"
				debug_print 4 "Abort creation of new log file"
				log_file=""
				return 1
			fi # 3/

			# rename current log filename to archive filename
			debug_print 2 "Archive (rename) pre-existing log file to: $filename_archive"

			if ! run_command mv "$log_file" "$filename_archive" || validate_file_system_object "$log_file" file; then # 3/ removal failed
				debug_print 3 warn "Failed to rename pre-existing log file (to archive filename)"
				debug_print 2 warn "Failed to create new log file due to conflicting pre-existing file system objects"
				debug_print 4 "Abort creation of new log file"
				log_file=""
				return 1
			fi # 3/
		fi # 2/

		##
		# Store new log file location in the old log file before passing the baton, but
		# only when log type is a program log (e.g. do not do this for other log types,
		# such as JSON format logs).
		#
		# Append archived log with pointer to new log filename for continuity.
		##

		# only append new log file path to archive when program style log (.log file extension)
		[ "$file_extension" = "log" ] && printf "Next log file in sequence: %s\n" "$log_file" &>> "$filename_archive"

		# modify permission levels on archive file to read-only access for all users
		! set_target_permissions "$filename_archive" 444 "$service_user_override" && debug_print 3 caution "Failed to set archive file permissions to read-only for all users: $filename_archive"

	fi # 1/

	##
	# Now that any potential archiving has been sorted, return focus to
	# new log file creation.
	##

	debug_print 3 "Create new log file: $log_file"

	if ! run_command touch "$log_file" || ! validate_file_system_object "$log_file" file; then # 1/ file not there
		debug_print 3 warn "Failed to create new log file"
		debug_print 4 "Abort new log file creation"
		log_file=""
		return 1
	fi # 1/

	debug_print 3 "New log file created successfully: $log_file"

	##
	# Set full permissions for current user and read-only access for all other users.
	#
	# Some file operations may require read capability for user currently manipulating
	# the log file. However, all other users should only need read access.
	##

	debug_print 3 "Set log file permissions bias"

	# all users get read-only access
	! set_target_permissions "$log_file" 444 && debug_print 3 warn "Failed to restrict log file access for most users to read-only"

	# bias log file permissions toward current user
	! set_target_permissions "$log_file" PERM_ALL "$service_user_override" && debug_print 3 caution "New log file access permissions may be sub-optimal"

	debug_print 1 "Log file started: $log_file"
}
