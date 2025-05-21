##
# Set directory or file to specified permissions level.
#
# Checks if requested user permissions are already at requested level and if so does nothing.
# When current permissions level is insufficient to satisfy reuqest, attempt to modiey
# permissions level of the file system object.
#
# When $override_current_user is not true, permissions are changed for the current effective user,
# which is the username running the current script. This may or may not be the same username as
# the username designated to run the service programs. If the actual or real user is running the
# script via sudo, the effective username will always be root.
#
# Operating modes/use cases:
# --> 1. elevate current user permissions for given file/dir
#	--> input: file/dir + permission level (0-7)
# --> 2. elevate Service program user for given file/dir
#	--> input: file/dir + permission level + override_current_user = true (service user)
# --> 3. assign specified raw permission to given file/dir
#	--> input: file/dir + raw permissions (3-digit)
#
# Inputs:
#	$1 = full pathname to target directory or filename
#	$2 = permissions level to set target to (may be single digit or 3-digits)
#	$3 = when true, set permissions for Service program user rather than current user
##

function set_target_permissions ()
{
	local computed_mode				# computed permissions level to apply to file system object
	local current_permissions		# current permissions levels of the file system object
	local file_system_object			# filename or directory name to modify permissions of
	local level_requested			# file system permisisons level desired of the file system object
	local -l override_current_user	# when true, apply to service program user instead of current user
	local parent_dir				# parent directory the target object belongs to
	local -l user_type				# rank of user in file permissions hierarchy ( owner | group member | other )

	file_system_object="$1"			# file/dir target object to check/set permissions level of user [required]
	level_requested="$2"			# permissions level to set permission level to if not already there (1 or 3 digits) [required]
	override_current_user="$3"		# when true = apply to $service_username; otherwise, target is current user [optional]

	if [ $# -lt 2 ] || [ $# -gt 3 ]; then
		debug_print 3 warn "Invalid number of arguments in call to '${FUNCNAME[0]}' function" true
		return 1
	fi # 1/

	if [ -z "$file_system_object" ]; then # 1/
		debug_print 3 "Target file or directory not specified" true
		return 1
	fi # 1/

	debug_print 3 "Validate user file system permissions for object $file_system_object"

	if [ -z "$level_requested" ]; then # 1/
		debug_print 3 warn "Value for requested file system object permissions level is missing (\$2)" true
		return 1
	fi # 1/

	# standardize Service user override flag setting
	if [ "$override_current_user" != true ]; then # 1/
		override_current_user=false
	else # 1/
		debug_print 4 "Target user is effective Service username"
	fi # 1/

	##
	# Convert permissions level input (name) to magic number.
	#
	# Ensure requested permissions level contains only integers between 0-7.
	# Since these integers equate to file system permissions, they cannot be
	# higher than 8, since the only relevant bits are 0, 1, and 2.
	#
	# The screening below blocks any possibility of digits outside acceptable
	# range (i.e. > 7).
	#
	# The input can be a permissions term of a known meaning (e.g. PERM_ALL); or
	# a single-digit file system permissions number (e.g. 1, 5, 7, etc.).
	#
	# If input is text, it must match the name of a known permissions term that is
	# understood by the 'convert_perms_to_level' subroutine.
	##

	level_requested="$(convert_perms_to_level "$level_requested")" || unset level_requested

	if [ -z "$level_requested" ] || [ "${#level_requested}" -gt 3 ]; then # 1/ invalid characters or number too long
		debug_print 3 warn "Required permissions level argument (\$level_requested) is invalid: $level_requested" true
		return 1
	fi # 1/

	##
	# In order to 'stat' file system object, the current user must have at a minimum, access/traverse
	# rights to its parent directory, and then depending on what type of object it is, traverse or
	# read rights on the object itself may also be required.
	##

	parent_dir="$(dirname "$file_system_object")"

	if [ "$parent_dir" != "$file_system_object" ]; then # 1/ not the same
		debug_print 4 "Verify user can traverse its parent directory"

		if ! query_target_permissions "$parent_dir" PERM_TRAVERSE false false true; then # 2/
			debug_print 3 warn "User lacks right to traverse parent directory of target object: $parent_dir" true
			return 1
		fi # 2/
	fi # 1/

# when object is a directory, need rights on object itself (x or traverse)
#	if [ -d "$file_system_object" ]; then # 1/ object is a directory
#		if ! query_target_permissions "$file_system_object" PERM_TRAVERSE false; then # 2/ traverse right on dir itself is required
#			debug_print 3 warn "Target object is inaccessible (cannot process 'stat' command)" true
#			return 1
#		fi # 2/
#	fi # 1/

	##
	# Get current file system object permissions level, as it is needed regardless of whether
	# 1-digit or 3-digit permissions level access is requested.
	##

	! stat_file_system_object "$file_system_object" current_permissions && return 1

	#########################################
	# 3-digit General Permissions Modificaton
	#########################################

	##
	# When requested permissions level is 3 digits, attempt to modify existing
	# file system object permissions, regardless of relationship of user to
	# pre-existing target object.
	##

	if [ "${#level_requested}" -eq 3 ]; then # 1/ set 3-digit permissions level for file system object

		# confirm raw mode file permissions request is within possible value range
		if [ "$level_requested" -lt 100 ] || [ "$level_requested" -gt 777 ]; then # 2/
			debug_print 4 warn "Requested file system object 3-digit permissions level is out of range: $level_requested" true
			return 1
		fi # 2/

		if [ "$current_permissions" -ne "$level_requested" ]; then # 2/ attempt to force permissions change

			# attempt to force permissions change, and bail if an error occurs
			if ! run_command chmod -f "$level_requested" "$file_system_object"; then # 3/
				debug_print 3 warn "'chmod' command failed for an unknown reason" true
				return 1
			fi # 3/

			# stat file system object again to verify stat change occurred
			! stat_file_system_object "$file_system_object" computed_mode && return 1

			if [ -z "$computed_mode" ] || (( computed_mode != level_requested )); then # 3/ fail
				debug_print 3 warn "Failed to modify file system permissions level from $current_permissions to $computed_mode"
				return 1 # failure
			fi # 3/
		fi # 2/

		# already at requested permissions level
		debug_print 4 "No permissions changes necessary: pre-existing permissions level matches requested permissions level"
		return 0
	fi # 1/

	###############################################
	# 1-Digit User-Specific Permissions Modificaton
	###############################################

	##
	# When permissions level ($level_requested) is only 1 digit, evaluate current permissions level
	# of specified user (current or Service program user).
	##

	if [ "$level_requested" -lt 1 ]; then # 1/ permissions change request cannot be magic number of 0 (no rights)
		debug_print 4 warn "Requested file system object permissions level '${level_requested}' is not a logical request" true
		return 1
	fi # 1/

	##
	# Confirm file system object exists before proceeding further.
	#
	# Also determine whether user already has requested permission level relative to target file system object.
	# If user already has requested access, then exit as there is nothing to do here.
	##

	# permissions level inquiry can be either permissions terminology or magic number
	user_type="$(query_target_permissions "$file_system_object" "$level_requested" "$override_current_user" true false)" || unset user_type

	##
	# When conditional above does not cause this subroutine to exit, it means the
	# specified user does not have sufficient access permissions. Next, determine
	# what permissions level would be required in order to grant access to the
	# specified user, based on $user_type, which will have been populated by the
	# function call above.
	##

	if [ -n "$user_type" ]; then # 1/ nothing else to do when user already has sufficient permissions
		return 0
	else # 1/
		debug_print 3 warn "Failed to determine pre-existing permissions level of current user relative to $file_system_object"
		debug_print 4 "'\$user_type' is undefined"
		return 1
	fi # 1/

	##
	# When user does not already have access, flip bit(s) in file system object permission
	# corresponding to user type of target user.
	#
	# Calculate new permissions level for file system object and apply.
	#
	# Current permission settings not related to requested user type are not altered.
	##

	if [ "$user_type" = "owner" ]; then # 1/ target owned by specified user
		computed_mode=$(( level_requested * 100 + current_permissions % 100 ))
	else # 1/ target not owned by user
		if [ "$user_type" = "group" ]; then # 2/ user belongs to group that owns target object
			computed_mode=$(( ( ( current_permissions / 100 ) * 100 ) + ( level_requested * 10 ) + ( current_permissions % 10 ) ))
		else # 2/ others user type permission
			if [ "$user_type" = "other" ]; then # 3/
				computed_mode=$(( ( ( current_permissions / 100 ) * 100 ) + ( ( ( current_permissions / 10 ) % 10 ) * 10 ) + level_requested ))
			else # 3/
				debug_print 4 warn "Logic error encountered; invalid user type '${user_type}"
				return 1
			fi # 3/
		fi # 2/
	fi # 1/

	# modify file system object permissions to new, computed value
	debug_print 4 "Modify file system object permissions value from $current_permissions to $computed_mode"

	# attempt to force permissions change
	if ! run_command chmod -f "$computed_mode" "$file_system_object"; then # 1/ bail when it failed
		debug_print 3 warn "'chmod' command failed for an unknown reason" true
		return 1
	fi # 1/

	# confirm change occurred
	! stat_file_system_object "$file_system_object" current_permissions && return 1

	if (( current_permissions != computed_mode )); then # 1/
		debug_print 3 warn "Failed to modify file system permissions level from $current_permissions to $computed_mode"
		return 1
	fi # 1/
}
