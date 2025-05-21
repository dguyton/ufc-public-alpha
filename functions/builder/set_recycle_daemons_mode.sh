##
# Evaluate whether or not a pre-existing implmentation of the Universal
# Fan Controller (UFC) exists, and if so, whether or not it can
# potentially be re-used.
#
# If a pre-existing daemon service exists, examine various criteria in
# order to make a decision on whether or not to recycle / re-use the
# incumbent installation.
#
# If an install is recycled, its behavior may still be impacted by any
# changes made to the Builder configuration file.
#
# Outcome/Output: Sets the value of $recycle_service_daemons. Possible
# values:
#	- null = there is no pre-existing daemon
#	- false = there is a pre-existing daemon, but do not use it
#	- true = there is a pre-existing daemon, re-use it if feasible
##

##
# Methodology
#
# Process of elimination / last man standing. Cannot recycle if any disqualifying condition is true.
#
# Rules are applied below which disqualify pre-existing installations from recycling when various
# criteria are not met. If a pre-existing install is not disqualified by the end of the rule tests,
# then it is suitable for recycling.
#
# What are the critera for recycling? (much of this is vetted in other subroutines)
#	--> 1. service version = builder version
#	--> 2. service launcher program file exists
#	--> 3. service runtime program file exists
#	--> 4. service user has read/execute permission to both files
#	--> 5. service user has traverse/read permissions to launcher directory
#	--> 6. service user has traverse/read/write permissions to runtime directory
#	--> 7. launcher daemon exists and has not failed
#	--> 8. runtime daemon exists and has not failed
#	--> 9. required include files exist
##

function set_recycle_daemons_mode ()
{
	local file_count
	local target_dir_parent_old
	local version

	# leave recycling flag = null when no related pre-existing daemons exist
	if [ -z "$launcher_daemon_service_state" ] && [ -z "$runtime_daemon_service_state" ] && [ -z "$failure_handler_daemon_service_state" ]; then # 1/
		debug_print 3 "No pre-existing implementation of $program_name daemonized services were found"
		return 0 # no pre-existing installation
	fi # 1/

	# presumptive condition when pre-existing install exists is that it will be removed and not recyled
	recycle_service_daemons=false

	##
	# Disqualify the possibility of recycling pre-existing install based on certain criteria
	##

	# no access or invalid pointers to one or both program file dirs; or bad link; or no common daemon parent dir
	if [ "$service_program_version_old" = "fail" ] || [ -z "$launcher_daemon_service_name" ] || [ -z "$runtime_daemon_service_name" ] || [ -z "$service_launcher_target_filename" ] || [ -z "$service_runtime_target_filename" ]; then # 1/
		return 1
	fi # 1/

	debug_print 3 "Explore possibility of recycling pre-existing Service programs"

	#####################################
	# Validate Pre-existing Daemon States
	#####################################

	##
	# This section utilizes metadata derived from the
	# 'detect_service_daemons' subroutine.
	##

	# evaluate pre-existing Launcher daemon
	case "$launcher_daemon_service_state" in # 1/
		fail|failed)
			debug_print 2 caution "Pre-existing installation will not be recycled: Service Launcher daemon service reported as non-operational"
			return 1
		;;
	esac # 1/

	# evaluate pre-existing Runtime daemon
	case "$runtime_daemon_service_state" in # 1/
		fail|failed)
			debug_print 2 caution "Pre-existing installation will not be recycled: Service Runtime daemon service reported as non-operational"
			return 1
		;;
	esac # 1/

	##########################################
	# Validate Pre-existing Daemon Directories
	##########################################

	service_launcher_target_dir_old="$(dirname "$service_launcher_target_filename")"
	trim_trailing_slash "service_launcher_target_dir_old"

	if [ -z "$service_launcher_target_dir_old" ]; then # 1/ use of root dir not permitted as program dir
		debug_print 2 critical "Cannot recycle previous installation, because Service Launcher directory is root"
		return 1
	fi # 1/

	debug_print 3 "Pre-existing Service Launcher program directory: ${service_launcher_target_dir_old}/"

	service_runtime_target_dir_old="$(dirname "$service_runtime_target_filename")"
	trim_trailing_slash "service_runtime_target_dir_old"

	if [ -z "$service_runtime_target_dir_old" ]; then # 1/	use of root dir not permitted as program dir
		debug_print 2 critical "Cannot recycle previous installation, because Service Runtime directory is root"
		return 1
	fi # 1/

	debug_print 3 "Pre-existing Service Runtime program directory: ${service_runtime_target_dir_old}/"

	####################################################
	# Validate Pre-Existing Failure Notification Service
	####################################################

	##
	# While both Launcher and Runtime Service daemons and programs are required,
	# the Failure Notification Handler (FNH) is not. However, when determining
	# whether or not a pre-existing installation can be recycled/re-used or not,
	# the question of whether or not the Builder configuration file currently
	# requests enabling the FNH, versus whether or not the FNH was previously
	# installed and configured, may determine whether or not recycling the prior
	# installation is possible.
	#
	# The Failure Notification Handler (FNH) daemon is not fully validated in
	# previous steps, because its use is optional. However, if it exists and
	# pre-existing Service programs can be recycled, its integrity needs to be
	# checked here. This includes validating whether or not it is currently
	# desired, relative to whether or not it was previously installed.
	##

	##
	# Working variables
	#
	# 1. $service_failure_handler_target_filename
	#	- assigned by 'detect_service_daemons' subroutine
	#	- full filename path of pre-existing FNH program file
	# 2. $failure_handler_daemon_service_filename
	#	- assigned by 'detect_service_daemons' subroutine
	#	- full filename path of pre-existing FNH daemon .service file
	# 3. $failure_handler_daemon_service_state
	#	- assigned by 'detect_service_daemons' subroutine
	#	- current operational state of pre-existing FNH daemon
	##

	if [ "$enable_failure_notification_service" = true ]; then # 1/ user wants FNH daemon service
		if [ -z "$failure_handler_daemon_service_state" ] && [ -z "$failure_handler_daemon_service_filename" ] && [ -z "$service_failure_handler_target_filename" ]; then # 2/ not pre-existing
			debug_print 2 warn "Cannot recycle previous installation, because Service Failure Notification Handler is requested but not already installed"
			return 1 # cannot recycle because FNH needs to be installed and was not previously
		fi # 2/

		# desired + is pre-existing + daemon failed
		if [ "$failure_handler_daemon_service_state" = "failed" ]; then # 2/
			debug_print 3 warn "Pre-existing Service Failure Notification Handler daemon service failure"
			return 1 # existing process failed for unknown reason
		fi # 2/

		# desired + pre-existing + not failed = might be ok to re-use
		if [ -n "$service_failure_handler_target_filename" ]; then # 2/ pre-existing program file location previously verified
			service_failure_handler_target_dir_old="$(dirname "$service_failure_handler_target_filename")" # get pre-existing Failure Notification Handler dir
			trim_trailing_slash "service_failure_handler_target_dir_old"

			if [ -z "$service_failure_handler_target_dir_old" ]; then # 3/ cannot recycle when any pre-existing program located in root dir
				debug_print 2 warn "Cannot recycle previous installation, because Service Failure Notification Handler was installed in root dir, which is not allowed"
				return 1
			fi # 3/

			# desired + pre-existing + not failed + exec file exists + exec file parent dir not root = check program version
			if version="$(parse_file_version "$service_failure_handler_target_filename")"; then # 3/
				if [ "$version" = "$service_program_version_old" ]; then # 4/ program versions match
					debug_print 2 "Pre-existing Failure Notification Handler program version matches pre-existing Service Launcher and Runtime programs" # version pass; recycle = ok
				else # 4/ version check failed
					debug_print 4 "Pre-existing Failure Notification Handler program version does NOT match this Builder"
					return 1
				fi # 4/
			else # 3/
				debug_print 4 "Pre-existing Failure Notification Handler program version does NOT match this Builder"
				return 1
			fi # 3/

			##
			# Confirm Service user has rights to modify FNH .service file dynamically.
			#
			# This ability will be required later on in the Builder in order to assign
			# its pointers correctly.
			##

			if ! set_target_permissions "$service_failure_handler_target_dir_old" PERM_ALL true; then # 3/
				debug_print 4 "Failure Notification Handler daemon service cannot be recycled because Service user lacks sufficient permissions to its parent directory"
				return 1
			fi # 3/

			if ! set_target_permissions "$(dirname "$service_failure_handler_target_dir_old")" PERM_WRITE_TRAVERSE true; then # 3/
				debug_print 4 "Failure Notification Handler daemon service cannot be recycled because Service user lacks sufficient permissions to a higher level directory"
				return 1
			fi # 3/
		else # 2/ desired by user + pre-existing daemon + daemon not failed + exec file missing
			debug_print 3 warn "Cannot recycle previous installation, because Service Failure Notification Handler program file is missing"
			return 1
		fi # 2/
	else # 1/ user does not want FNH service
		if [ -n "$failure_handler_daemon_service_state" ] || [ -n "$failure_handler_daemon_service_filename" ] || [ -n "$service_failure_handler_target_filename" ]; then # 2/ is pre-existing
			debug_print 2 "Cannot recycle because previous installation of Failure Notification Handler exists, but is not currently requested"
			return 1 # cannot recycle because Failure Notification Handler daemon is pre-existing and must be expunged first
		fi # 2/
	fi # 1/

	#################################################################################################
	# Confirm Service User has Sufficient Access Permissions to Utilize Pre-Existing Service Programs
	#################################################################################################

	##
	# When Service Launcher and Runtime programs share the same parent directory,
	# the Service user will need access, read, and write rights (i.e. all rights)
	# to the parent directory. However, because write rights are only needed
	# relative to the Runtime program .init file, if the programs belong to
	# different parent directories, then only the Runtime directory requires only
	# write rights for the Service user.
	##

	if [ "$service_runtime_target_dir_old" = "$service_launcher_target_dir_old" ]; then # 1/ shared parent directory
		debug_print 4 "Probe Service user access rights to pre-existing shared Service program directory"

		if ! set_target_permissions "$service_launcher_target_dir_old" PERM_ALL true; then # 2/ service needs all file perms to support clean-up of Runtime dir
			debug_print 3 warn "Access modification attempt failed for an unknown reason"
			return 1 # just say no to recycling
		fi # 2/

		# single common shared pre-existing parent dir
		target_dir_old="$service_launcher_target_dir_old"
	else # 1/ not shared parent dir; pre-existing Launcher and Runtime program files are in different dirs
		debug_print 4 "Probe Service user access rights to pre-existing Service Launcher directory"

		if ! set_target_permissions "$service_launcher_target_dir_old" PERM_READ_TRAVERSE true; then # 2/ service user has sufficient access permissions for Launcher dir (access + read)
			debug_print 3 "Access modification attempt failed for an unknown reason"
			return 1 # recycling not possible
		fi # 2/

		# confirm Service user has necessary access to Runtime executable dir
		debug_print 4 "Probe Service user access rights to pre-existing Service Runtime directory"

		if ! set_target_permissions "$service_runtime_target_dir_old" PERM_ALL true; then # 2/ Service user needs ability to write/update Runtime init files + access + read
			debug_print 3 "Access modification attempt failed for an unknown reason"
			return 1
		fi # 2/

		##
		# When Service Launcher and Runtime programs do not share the same parent directory,
		# they must be nested under a common parent-of-parents (or grand-parent) directory.
		#
		# If not, the Builder will not plausibly be capable of validating other aspects of
		# any previous installation in subsequent function calls, and therefore the
		# pre-existing install will be disqualified from recycling/re-use.
		##

		if [ "$(dirname "$service_runtime_target_dir_old")" != "$(dirname "$service_launcher_target_dir_old")" ]; then # 2/ not common parent dir
			debug_print 3 warn "Cannot recycle previous installation, because Service files do not belong to a common ancestor directory"
			return 1
		fi # 2/

		debug_print 3 "Validate access through pre-existing top-level parent directories"

		# Service Launcher and Runtime program directories share a common parent directory
		target_dir_old="$(dirname "$service_launcher_target_dir_old")"
		trim_trailing_slash "target_dir_old"

		if [ -n "$target_dir_old" ]; then # 2/ pre-existing top-level target directory is not root and there is also a higher level ancestor dir

			# verify service user has sufficient rights to traverse pre-existing top-level target directory
			target_dir_parent_old="$(dirname "$target_dir_old")"
			trim_trailing_slash "target_dir_parent_old"

			if [ -n "$target_dir_parent_old" ]; then # 3/ grand-parent dir not root
				debug_print 4 "Probe Service user access rights to pre-existing top-level target directory: $target_dir_parent_old"

				if ! set_target_permissions "$target_dir_parent_old" PERM_TRAVERSE true; then # 4/ need access via parent of target dir level
					debug_print 3 warn "Service user lacks sufficient access rights to parent directory of pre-existing top-level target directory"
					unset target_dir_old # ensure no attempt is made to re-use dir
					return 1
				fi # 4/

				if ! set_target_permissions "$target_dir_old" PERM_READ_TRAVERSE true; then # 4/
					debug_print 3 "Service user has insufficient access permissions to pre-existing target directory"
					unset target_dir_old # ensure no attempt is made to re-use dir
					return 1
				fi # 4/
			else # 3/ grand-parent ancestor of pre-existing target dir is root dir
				debug_print 2 critical "Previous installation parent directory of Service file common nested ancestor directory is root"

				if ! set_target_permissions "/" PERM_TRAVERSE true; then # 4/ user needs traverse access
					debug_print 3 "Service user has insufficient access permissions to root directory"
					unset target_dir_old # ensure no attempt is made to re-use dir
					return 1
				fi # 4/
			fi # 3/
		else # 2/ pre-existing target dir is root dir, and therefore there is no higher level ancestor dir
			debug_print 2 critical "Previous installation Service file common nested ancestor directory is root"
			if ! set_target_permissions "/" PERM_TRAVERSE true; then # 3/ user needs traverse access
				debug_print 3 "Service user has insufficient access permissions to root directory"
				return 1
			fi # 3/
		fi # 2/
	fi # 1/

	######################################################
	# Validate Pre-Existing Service Include File Directory
	######################################################

	##
	# Now confirm include files are located where expected. They must be
	# located in their own sub-directory, under the top-level dir.
	#
	# If not, recycling is aborted.
	##

	debug_print 3 "Validate pre-existing Service include files directory"

	# presumed location of pre-existing include files
	service_functions_target_dir_old="${target_dir_old}/functions/"
	trim_trailing_slash "service_functions_target_dir_old"

	if [ -z "$service_functions_target_dir_old" ]; then # 1/
		debug_print 2 warn "Cannot recycle previous installation, because Service include files directory is not allowed to be root dir"
		return 1
	fi # 1/

	if ! validate_file_system_object "$service_functions_target_dir_old" directory; then # 1/ no such directory
		debug_print 3 warn "Failed to locate pre-existing Service program include files directory: $service_functions_target_dir_old"
		debug_print 4 "Service program recycling failed because pre-existing program include files directory could not be determined"
		debug_print 4 "Recycling pre-existing implementation is not possible"
		return 1
	fi # 1/

	debug_print 4 "Found pre-existing Service program include files directory: ${service_functions_target_dir_old}/"

	# confirm service user will be capable of traversing pre-existing include files directory
	if ! set_target_permissions "$service_functions_target_dir_old" PERM_READ_TRAVERSE true; then # 1/ parent of target dir level
		debug_print 3 warn "Service user lacks sufficient access rights to pre-existing directory containing required Service program include files"
		return 1
	fi # 1/

	######################################################################
	# Validate Pre-Existing Service Failure Notification Handler Directory
	######################################################################

	# check pre-existing failure handler files and dir access permissions when it exists
	if [ -n "$service_failure_handler_target_dir_old" ] && [ "$service_failure_handler_target_dir_old" != "$service_launcher_target_dir_old" ]; then # 1/ not shared parent directory
		debug_print 4 "Probe Service user access rights to pre-existing Service Failure Notification Handler program directory"

		if ! set_target_permissions "$service_failure_handler_target_dir_old" PERM_READ_TRAVERSE true; then # 2/ # need access + read
			debug_print 3 warn "Service user lacks sufficient access rights to pre-existing Failure Notification Handler program directory"
			return 1
		fi # 2/
	fi # 1/

	######################################################################################
	# Confirm Service User has Sufficient Access Permissions to Pre-Existing Program Files
	######################################################################################

	debug_print 4 "Probe Service user access rights to pre-existing Service Launcher program file"

	if ! set_target_permissions "$service_launcher_target_filename" PERM_READ_TRAVERSE true; then # 1/ need read + execute
		debug_print 3 "Access modification attempt failed for an unknown reason"
		return 1 # just say no to recycling
	fi # 1/

	debug_print 4 "Probe Service user access rights to pre-existing Service Runtime program file"

	if ! set_target_permissions "$service_runtime_target_filename" PERM_READ_TRAVERSE true; then # 1/
		debug_print 3 warn "Service user lacks sufficient access rights to pre-existing Service Runtime program file"
		return 1 # just say no to recycling
	fi # 1/

	#########################################################################
	# Confirm Pre-existing Launcher Init File Location and Access Permissions
	#########################################################################

	# pre-existing Service Launcher .init file location scan
	debug_print 3 "Check for pre-existing Service Launcher initialization file location"

	# warn when there is more than one possible .init file candidate in case wrong one is chosen
	file_count="$(find "$service_launcher_target_dir_old" -maxdepth 1 -iname '*.init' -type f | wc -l)"
	(( file_count > 1 )) && debug_print 3 caution "$file_count potential .init files exist in pre-existing Service Launcher directory"

	# {var name to hold target filename} {directory to scan} {string to match} {version} {file extension} {depth}
	if ! service_launcher_init_filename="$(find_best_file_version_match "$service_launcher_target_dir_old" "launcher" "$service_program_version_old" "init" 1)"; then # 1/ no match found
		debug_print 3 warn "Failed to identify pre-existing Service Launcher .init file location"
		return 1
	fi # 1/

	if ! set_target_permissions "$service_launcher_init_filename" PERM_READ_ONLY true; then # 1/
		debug_print 3 warn "Service user lacks sufficient access rights to pre-existing Service Launcher initialization file"
		return 1
	fi # 1/

	###########################################################
	# Determine Whether Required Include Files are Pre-Existing
	###########################################################

	##
	# Confirm required Service program include files are present in the pre-existing installation.
	# This process involves first probing the manifest listing related include files, which is located
	# in a source file directory for the current version, and comparing each program type manifest of
	# filenames to the pre-existing directory where those files are expected to be found.
	#
	# If any step fails, the process is aborted and by default recycling the current installation will
	# be rejected.
	#
	# The process is:
	#
	# 1. Determine filename of current source files manifest for Service Launcher and Runtime programs
	# 2. Leverage current Service program version source file manifests to validate pre-existing include files
	# 3. In order to recycle a pre-existing installation, all program include file manifest scans must pass
	##

	debug_print 3 "Validate Service program include file manifests against pre-existing include files"

	##
	# Validate current Service Launcher manifest against pre-existing include files. Existing daemons cannot
	# be recycled if these tests fail.
	#
	# 1. Locate current Service Launcher include files manifest
	# 2. Confirm current manifest matches Builder program version
	# 3. Confirm all files mentioned in manifest are present in pre-existing include files directory
	##

	# validate based on {global var name} {service type} {incumbent manifest directory} {incumbent include files top-level dir}
	if ! service_launcher_manifest_filename="$(validate_service_file_manifest "launcher" "$config_source_dir" "$service_functions_target_dir_old")"; then # 1/
		debug_print 3 "Cannot recycle pre-existing Service programs because Service Launcher manfiest or its files were invalidated"
		return 1
	fi # 1/

	# repeat process above for incumbent Service Runtime manifest and include files
	if ! service_runtime_manifest_filename="$(validate_service_file_manifest "runtime" "$config_source_dir" "$service_functions_target_dir_old")"; then # 1/
		debug_print 3 "Cannot recycle pre-existing Service programs because Service Runtime manfiest or its files were invalidated"
		return 1
	fi # 1/

	#####################################
	# Recycling Criteria Met Successfully
	#####################################

	##
	# When logic makes it this far down, ability to recycle pre-existing installation = true
	##

	recycle_service_daemons=true

	debug_print 3 bold "Flagging previous installation top-level target Service files directories for re-use"
	debug_print 3 "Utilize pre-existing Service programs shared top-level parent directory: $target_dir_old"

	target_dir="$target_dir_old"

	service_launcher_target_dir="$service_launcher_target_dir_old"
	service_runtime_target_dir="$service_runtime_target_dir_old"
	service_functions_target_dir="$service_functions_target_dir_old"
	service_failure_handler_target_dir="$service_failure_handler_target_dir_old"
}
