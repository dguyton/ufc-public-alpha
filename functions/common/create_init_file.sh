##
# Creates new .init file.
# Removes pre-existing file with same fileanme first, if present.
##

function create_init_file ()
{
	local directory	# parent directory of filename
	local filename		# filename to create or replace
	local -l user_type

	filename="$1"

	debug_print 3 "Create new .init file: $filename"

	if [ -z "$filename" ]; then # 1/
		debug_print 4 warn "Request is missing filename" true
		return 1
	fi # 1/

	directory="$(dirname "$filename")" # strip basename to get dir path

	trim_trailing_slash "directory"

	if [ -z "$directory" ]; then # 1/
		debug_print 3 warn ".init file directory cannot be root"
		return 1
	fi # 1/

	debug_print 3 "Check parent directory permissions"

	##
	# In order to create a new file in a directory, the current user needs
	# traverse + write rights at the directory level.
	##

	if ! set_target_permissions "$directory" PERM_WRITE_TRAVERSE; then # 1/
		debug_print 3 "Current user ($USER) lacks sufficient permissions to remove pre-existing .init file: $filename"
		user_type="$(query_target_permissions "$directory" PERM_WRITE_TRAVERSE false true true)"
		return 1
	fi # 1/

	##
	# The Service user needs to be capable of reading and traversing the directory
	# in order to read the new file in its directory, and will need read access to
	# the file itself.
	##

	# Service user lacks required access to parent directory of file system object
	if ! set_target_permissions "$directory" PERM_READ_TRAVERSE true; then # 1/ Service user fails dir permissions test
		debug_print 3 "Service user ($USER) lacks sufficient permissions to remove pre-existing .init file: $filename"
		user_type="$(query_target_permissions "$directory" PERM_READ_TRAVERSE true true true)"
		return 1
	fi # 1/

	# check if file already exists
	if validate_file_system_object "$filename" "file"; then # 1/ object exists and is a normal file
		debug_print 3 caution "Remove pre-existing file: $filename"

		if ! run_command rm -f "$filename" || [ -f "$filename" ]; then # 2/ command failed to remove pre-existing file
			debug_print 3 warn "Failed to remove pre-existing file system object"
			return 1
		fi # 2/
	else # 1/
		if [ -e "$filename" ]; then # 2/
			debug_print 3 warn "Specified filename is in use and is not a normal file type"
			return 1
		fi # 2/
	fi # 1/

	# create new .init file
	if ! run_command touch "$filename" || ! validate_file_system_object "$filename" file; then # 1/
		debug_print 3 warn "Failed to create new init file for an unknown reason"
		return 1
	fi # 1/

	# set appropriate file access permissions
	if ! set_target_permissions "$filename" PERM_WRITE_ONLY; then # 1/ minimum access level for current user
		debug_print 3 warn "Failed to set minimal access level on new .init file for current user"
		return 1
	fi # 1/

	if ! set_target_permissions "$filename" PERM_READ_ONLY true; then # 1/ minimum access level for Service user
		debug_print 3 warn "Failed to set minimal access level on new .init file for Service user"
		return 1
	fi # 1/
}
