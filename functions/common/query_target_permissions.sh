##
# Determine whether or not indicated user has sufficient access permissions to specified file system object.
#
# Inputs:
#	1. Target file system object (full path name) [required]
#	2. Minimum access level to validate against
#		- may be a single-digit (user access level) (integer, 1-7); or
# 		- a word, so long as it can be converted by 'convert_perms_to_level' subroutine
#	3. Use declared Service program user flag (True/False flag) [optional]
#	4. Request user type relative to file system object (True/False flag) [optional]
#
# Possible outcomes:
# 	Success (status = 0) when the specified user has $level_needed or greater access permissions
# 	Fail (status = 1) when any of the following conditions occur:
#		1. A process in this function fails for some reason; or
#		2. The specified user does not have $level_needed access permissions at a minimum
#
# When requested ($4 = true), returns user type relative to file system object permissions.
##

function query_target_permissions ()
{
	local file_system_object				# full path name of file system object to test
	local level_needed					# minimum permissions level to evaluate for, single digit 1-7
	local -l force_service_username		# when true, use declared Service program username as current user (optional)

	local file_system_object_permissions	# current permissions level (3-digit magic number) of file system object
	local file_system_object_owner_id		# owner user ID the file system object belongs to
	local file_system_object_group_id		# group ID the file system object belongs to
	local return_user_type
	local user_permissions				# test user current permissions level relative to file system object
	local user_id						# user id of user to evaluate for existing file system permissions access to target object
	local user_group_id					# group ID of user to evaluate for existing file system permissions access to target object
	local user_all_group_ids				# all group IDs the user belongs to
	local user_name					# username of user to evaluate for existing file system permissions access to target object
	local -l user_type					# type of user being evaluated for access to file system target object, based on their relationship to target object

	file_system_object="$1"				# full path name of file system object to test
	level_needed="$2"					# minimum permissions level to evaluate for
	force_service_username="$3"			# when true, use declared Service program username as current user [optional]
	return_user_type="$4"				# true/false; when true return user type [optional]
	quiet_mode="$5"					# true/false; use quiet mode when true [optional]

	if [ $# -lt 2 ] || [ $# -gt 5 ]; then
		debug_print 3 warn "Invalid number of arguments in call to '${FUNCNAME[0]}' function" true
		return 1
	fi # 1/

	if [ -z "$file_system_object" ]; then # 1/
		debug_print 3 warn "Target object not defined" true
		return 1
	fi # 1/

	if [ -z "$level_needed" ]; then # 1/
		debug_print 3 warn "Nothing to do: permissions level not defined" true
		return 1
	fi # 1/

	# normalize flag usage
	[ "$force_service_username" != true ] && force_service_username=false # make it true or false for clarity
	[ "$return_user_type" != true ] && return_user_type=false
	[ "$quiet_mode" != true ] && quiet_mode=false

	##
	# Convert permissions level input
	#
	# The input can be a permissions term of a known meaning (e.g. PERM_ALL); or
	# a single-digit file system permissions number (e.g. 1, 5, 7, etc.).
	#
	# If input is text, it must match the name of a known permissions term that is
	# understood by the 'convert_perms_to_level' subroutine.
	##

	level_needed="$(convert_perms_to_level "$level_needed")" || unset level_needed

	if [ -z "$level_needed" ] || [ -n "${level_needed//[0-7]/}" ] || [ "${#level_needed}" -gt 1 ]; then # 1/ contains non-numeric characters
		debug_print 3 warn "Invalid permissions level argument (\$level_needed): $level_needed" true
		return 1
	fi # 1/

	# confirm object exists and is reachable
	if ! validate_file_system_object "$file_system_object"; then # 1/ target object does not exist or cannot be accessed by current user
		debug_print 3 warn "Target object is inaccessible or does not exist: $file_system_object" true
		return 1
	fi # 1/

	#############################
	# Determine Username to Query
	#############################

	##
	# NOTE: Logic below handles a corner case where current user is the
	# same username as Service user, request is to validate permissions
	# for Service user, and current user currently has elevated
	# priviliges via sudo.
	##

	# check if Service program user is query target
	if [ "$force_service_username" = true ]; then # 1/ Service program user is target user of permissions query
		user_name="$service_username" # effective user is specified Service username
		[ "$quiet_mode" = false ] && debug_print 4 "Confirm Service program user '${user_name}' has sufficient access permissions"
	else # 1/ check against current user
		user_name="$USER" # effective user is current user
		[ "$quiet_mode" = false ] && debug_print 4 "Confirm current user '${user_name}' has sufficient access permissions"
	fi # 1/

	##
	# Disable redundant user type flag when relevant.
	#
	# When access permissions status request is relative to Service user, yet the Service
	# username and current username are the same, there is no point in branching to the
	# Service username logic. It's more efficient to simply treat the user being queried
	# for access rights as the current user.
	##

	# when current user and Service program user are the same, treat effective user as current user
	{ [ "$force_service_username" = true ] && [ "$user_name" = "$USER" ]; } && force_service_username=false

	# lookup user ID and group IDs
	user_id="$(id -u "$user_name" 2>/dev/null)"
	user_group_id=$(id -g "$user_name" 2>/dev/null)
	user_all_group_ids=$(id -G "$user_name" 2>/dev/null) # list of all group IDs user belongs to, separated by spaces

	# trap odd errors (should never happen)
	if [ -z "$user_name" ] || [ -z "$user_group_id" ]; then # 1/ one or more lookups failed
		debug_print 2 warn "Indicated Username, its User ID, and/or its User Group could not be determined" true
		return 1
	fi # 1/

	###########################
	# Quantify Root User Status
	###########################

	if [ "$user_name" = "root" ]; then # 1/ user is root or elevated to root via sudo
		if [ -n "$user_id" ]; then # 2/
			if (( user_id == 0 )); then # 3/ should be de-facto root

				# warn when user id does not match user name (root user only)
				[ "$user_name" != "root" ] && debug_print 4 warn "Username identifies as 'root' however user ID is non-zero"

				if [ "$SUDO_USER" = "$user_name" ]; then # 4/
					[ "$quiet_mode" = false ] && debug_print 4 "Current user is elevated to 'root' status via 'sudo' interactive mode ('sudo -i')"
				else # 4/
					[ "$quiet_mode" = false ] && debug_print 4 "Current user is root (natively)"
				fi # 4/
			fi # 3/
		else # 2/ should only occur when this program is run indirectly via sudo command from terminal command line
			if [ "$SUDO_USER" = "$user_name" ]; then # 3/ current user is elevated to root via sudo
				[ "$quiet_mode" = false ] && debug_print 4 "Current username is '$SUDO_USER' elevated to 'root' status via 'sudo' command"
			else # 3/
				[ "$quiet_mode" = false ] && debug_print 4 caution "User is purportedly 'root' however various checks indicate this may be untrue"
			fi # 3/
		fi # 2/

		[ "$quiet_mode" = false ] && debug_print 4 "Effective user is root"
		user_type="root"
	fi # 1/

	##
	# Determine user access rights when user is not treated as root
	##

	if [ "$user_type" != "root" ]; then # 1/

		############################################
		# Get Current File System Object Permissions
		############################################

		##
		# Continue processing when effective user != root
		##

		# retrieve file system object permissions,owner ID, group numeric ID, and read them into discrete variables
		if ! read -r file_system_object_permissions file_system_object_owner_id file_system_object_group_id < <(stat -c "%a %u %g" "$file_system_object"); then # 2/
			debug_print 3 warn "'stat' command failed for an unknown reason when querying $file_system_object" true
			return 1
		fi # 2/

		# when magic number is 4 digits, drop 1st digit
		[ ${#file_system_object_permissions} -eq 4 ] && file_system_object_permissions="${file_system_object_permissions:1}"

		if [ ${#file_system_object_permissions} -ne 3 ]; then # 2/
			debug_print 3 warn "'stat' command parsing failure"
			return 1
		fi # 2/

		# split permission string into its digits
		owner_permissions=${file_system_object_permissions:0:1}
		group_permissions=${file_system_object_permissions:1:1}
		other_permissions=${file_system_object_permissions:2:1}

		#############################################
		# Determine User Relationship and Permissions
		#############################################

		# determine relationship of effective user to file system object
		if [ "$user_id" -eq "$file_system_object_owner_id" ]; then # 2/
			user_type="owner"
			user_permissions=$((owner_permissions))
		else # 2/
			if printf "%s" "$user_all_group_ids" | grep -qw "$file_system_object_group_id"; then # 3/ parse list of file system object group IDs (separated by spaces)
				user_type="group"
				user_permissions=$((group_permissions))
			else # 3/
				user_type="other"
				user_permissions=$((other_permissions))
			fi # 3/
		fi # 2/

		{ [ "$quiet_mode" = false ] || [ "$return_user_type" = true ]; } && debug_print 4 "User '${user_name}' is type '${user_type}' relative to $file_system_object"

	fi # 1/

	#################################
	# Report User Type When Requested 
	#################################

	# when requested, return user type relative to file system object permissions
	[ "$return_user_type" = true ] && printf "%s" "$user_type"

	################################################
	# Validate User Vs. Requested Permissions Levels
	################################################

	# for each required permission bit, check if it is present:
	if [ "$user_type" = "root" ] || (( ( user_permissions & level_needed ) == level_needed )); then # 1/ user has sufficient rights
		return 0
	else # 1/
		[ "$quiet_mode" = false ] && debug_print 3 "User $user_name does NOT meet minimum permissions level ($level_needed) for file system object $file_system_object"
		return 1
	fi # 1/
}
