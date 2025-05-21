##
# When not recycling pre-existing implementation, copy files and set file system pointers
# to target locations.
#
# The "Launcher" program is launched by the service daemon, or manually.
# The "runtime" program is started by the launcher is the primary Service workhorse,
# while the launcher acts as a setup and configuration tool which preps the
# runtime program parameters, such as environmental variables.
##

##
# This subroutine performs the following functions involved in configuring
# the Service Launcher and Service Runtime programs:
# 
# 1. create target directories when necessary
# 2. copy Service Launcher and Service Runtime program executables to target dirs
# 3. copy global variable declarations files for Service Launcher and Service Runtime programs to target dirs
# 4. copy include file manifests for Service Launcher program and Service Runtime program to their respective target directories
# 5. copy include files mentioned in Service Launcher and Runtime manifests to target dirs
# 6. copy motherboard manufacturer specific include files to target include files dir
# 7. set target file and directory permissions ownership to service user 
# 8. set target file and directory access permissions to allow service user required access
##

# copy Service program file to service folder
function copy_service_program_files ()
{
	local copy_failure
	local filename
	local permissions

	debug_print 2 "Copy Service program files from parent source directory: ${service_source_dir}/"
	debug_print 2 "Copy Service program files to parent target directory: $target_dir"

	if [ "$recycle_service_daemons" = true ]; then # 1/
		debug_print 3 "Service files will not be copied, because pre-existing Service files will be recycled"
		return
	fi # 1/

	#################################################
	# Copy Service Program Executables to Target Dirs
	#################################################

	# copy Service Launcher program executable to its target location
	debug_print 3 "Copy Service Launcher program executable file to its target destination: $service_launcher_target_filename"

	run_command cp -f -v "$service_launcher_source_filename" "$service_launcher_target_filename"

	[ ! -f "$service_launcher_target_filename" ] && bail_noop "Creation of Service Launcher target program file failed for an unknown reason"

	# copy Service Runtime program executable to its target location
	debug_print 3 "Copy Service Runtime program executable file to its target destination: $service_runtime_target_filename"

	run_command cp -f -v "$service_runtime_source_filename" "$service_runtime_target_filename"

	[ ! -f "$service_runtime_source_filename" ] && bail_noop "Creation of Service Runtime target program file failed for an unknown reason"

	########################################
	# Copy Global Variable Declaration Files
	########################################

	# copy Service program global variable declaration files to their target locations
	debug_print 3 "Copy Service program global variable declarations files"

	service_launcher_declarations_target_filename="${service_launcher_target_dir}/$(basename "$service_launcher_declarations_filename")"
	service_runtime_declarations_target_filename="${service_runtime_target_dir}/$(basename "$service_runtime_declarations_filename")"

	# global declarations file required for Service Launcher program
	debug_print 3 "Copy $service_launcher_declarations_filename to $service_launcher_declarations_target_filename"
	run_command cp -f -v "$service_launcher_declarations_filename" "$service_launcher_declarations_target_filename"

	! set_target_permissions "$service_launcher_declarations_target_filename" PERM_READ_ONLY true && bail_noop "Failed to set permissions correctly for an unknown reason: $service_launcher_declarations_target_filename"

	# global declarations file required for Service Runtime program
	debug_print 3 "Copy $service_runtime_declarations_filename to $service_runtime_declarations_target_filename"
	run_command cp -f -v "$service_runtime_declarations_filename" "$service_runtime_declarations_target_filename"

	! set_target_permissions "$service_runtime_declarations_target_filename" PERM_READ_ONLY true && bail_noop "Failed to set permissions correctly for an unknown reason: $service_runtime_declarations_target_filename"

	############################################
	# Copy Include File Manifests to Target Dirs
	############################################

	# copy include file manifests to Service program directories
	debug_print 3 "Copy manifests of Service include files to target directories"

	# copy both manifests to the Launcher target dir as only the Launcher will evaluate them
	service_launcher_manifest_target_filename="${service_launcher_target_dir}/$(basename "$service_launcher_manifest_filename")"
	service_runtime_manifest_target_filename="${service_runtime_target_dir}/$(basename "$service_runtime_manifest_filename")"

	debug_print 3 "Copy Service Launcher manifest file to target directory"
	debug_print 4 "Copy $service_launcher_manifest_filename to $service_launcher_manifest_target_filename"

	run_command cp -f -v "$service_launcher_manifest_filename" "$service_launcher_manifest_target_filename"

	[ ! -f "$service_launcher_manifest_target_filename" ] && bail_noop "Failed to copy Service Launcher manifest file to target directory for an unknown reason"

	debug_print 3 "Copy Service Runtime manifest file to target directory"
	debug_print 4 "Copy $service_runtime_manifest_filename to $service_runtime_manifest_target_filename"

	run_command cp -f -v "$service_runtime_manifest_filename" "$service_runtime_manifest_target_filename"

	[ ! -f "$service_runtime_manifest_target_filename" ] && bail_noop "Failed to copy Service Runtime manifest file to target directory for an unknown reason: $service_runtime_manifest_target_filename"

	##########################################################################
	# Parse Service Launcher Manifest and Copy its Include Files to Target Dir
	##########################################################################

	##
	# Certain Service include files are manufacturer-specific. These reside in
	# /source_dir/functions/service/manufacturer/{manufacturer name}/
	#
	# Any files in the manufacturer directory corresponding to the motherboard
	# manufacturer of the server the Builder program is being run on will take
	# precedence over the identically named include files (if any) in either
	# the Service or Common include file directories.
	#
	# This means manufacturer-specific versions of these include files will
	# overwrite and replace the generic versions when there is a conflict.
	#
	# Furthermore, manufacturer-specific include filenames must be appended to
	# the Service manifests, to ensure the Service-side include file validation
	# process accounts for them.
	##

	# copy include files mentioned in Service Launcher manifest to Service program target include files directory
	debug_print 3 "Copy Service include files mentioned in Launcher manifest to target Service include files directory"

	##
	# NOTE: Existence of source file manifests was previously validated by inventory_service_program_files
	# subroutine against the same manifests used here for the include files copy process. However, the
	# files themselves referenced in the manifests are not checked until here.
	##

	while read -r filename; do # 1/ import each filename from manifest

		{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue # skip headers and empty lines

		##
		# Skip duplicate files as they should have been copied previously,
		# during the Launcher file copy process above.
		##

		debug_print 4 "Copying $filename"

		##
		# When same filename exists in target directory, it is presumed the current file
		# to be copied is the same as or newer than the incumbent file, since the manifest
		# file versions in the source file directory have previously been validated against
		# the current Builder program version.
		#
		# An alternative approach would be to validate the version of any pre-existing file
		# in the target directory before deciding whether or not to overwrite it, however
		# even then it is possible the current source file is a more recently updated iteration
		# of the file than the incumbent file. Either way, it is presumed the "safer" option
		# is to always overwrite conflicting filenames, and this is the approach utilized below.
		#
		# This method also ensures the prioritization order of how source files are selected
		# is maintained. For example, if a manufacturer-specific file version exists, but did
		# not exist when the incumbent file was copied in the past, then the newer, more
		# specific manufacturer-centric file will replace the incumbent file, ensuring the most
		# recent version of the file is implemented in the target location.
		##

		# file already exists in target dir
		validate_file_system_object "${service_functions_target_dir}/${filename}" "file" && debug_print 3 caution "Pre-existing file system object exists in target directory, and may be overwritten"

		##
		# Locate each source file mentioned in manifest.
		#
		# 1. Verify file path exists and is accessible by current user.
		# 2. Confirm current user has both access + read file permissions.
		# 3. If user lacks sufficient file access rights, attempt to grant them.
		#
		# The set_target_permissions query for each file and location combination will fail when
		# any of these conditions are true:
		#
		# 1. File does not exist
		# 2. User did not already have required access rights to file
		# 3. Failed to grant requested file access to current user
		##

		# reset filename path indicator for each file check
		unset filename_source_path

		##
		# Comb through sub-directories in priority order:
		# 1. Manufacturer specific dir
		# 2. Service files dir
		# 3. Common files dir
		##

		if [ -n "$manufacturer_include_files_dir" ]; then # 1/ manufacturer-specific dir exists
			if set_target_permissions "${functions_service_source_dir}/manufacturer/${mobo_manufacturer}/${filename}" PERM_READ_ONLY; then # 2/ highest priority location is manufacturer-specific sub-dir, when one exists
				filename_source_path="${functions_service_source_dir}/manufacturer/${mobo_manufacturer}/${filename}"
				debug_print 4 "Found in manufacturer-specific directory"
			fi # 2/
		fi # 1/

		# file not found in or could not be read from manufacturer-specific sub-directory, or there is no manufacturer-specific directory
		if [ -z "$filename_source_path" ]; then # 1/ not found in manufacturer-specific dir
			filename_source_path="${functions_service_source_dir}/${filename}"

			if set_target_permissions "$filename_source_path" PERM_READ_ONLY; then # 2/
				debug_print 4 "Found in Service program include files directory"
			else # 2/ file not found in or cannot be read in Service-specific sub-dir
				filename_source_path="${functions_common_source_dir}/${filename}"

				if set_target_permissions "$filename_source_path" PERM_READ_ONLY; then # 3/
					debug_print 4 "Found in Common (shared) program include files directory"
				else # 3/ file not found in or cannot be read from shared files sub-dir
					debug_print 2 warn "Failed to locate file required per manifest: $filename"
					copy_failure=true
					continue
				fi # 3/
			fi # 2/
		fi # 1/

		##
		# Attempt to force copying current file to target directory.
		# When a pre-existing filename is present, overwrite it.
		#
		# If the file copy command fails, make a note in program log,
		# set copy failure flag, and move on to the next file.
		#
		# Note if the copy_failure flag is ever set = true, this will
		# cause the file copy process to fail, which will in turn cause
		# the program to exit on catastrophic failure. However, this will
		# not happen until after all problematic filenames are first
		# reported in the program log, to aid follow-up debugging.
		##

		# force copy file to target dir, with verbosity
		if ! cp -f -v "$filename_source_path" "$service_functions_target_dir" 2>&1; then # 1/
			debug_print 3 warn "Copy command failed for an unknown reason"
			copy_failure=true # this flag does not get reset once it has been triggered
			continue
		fi # 1/

	done < <(sort -u "$service_launcher_manifest_filename" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames

	if [ "$copy_failure" = true ]; then # 1/
		debug_print 1 warn "Aborting Service program file copy process due to an unrecoverable error"
		return 1 # inform caller this function failed
	fi # 1/

	#########################################################################
	# Parse Service Runtime Manifest and Copy its Include Files to Target Dir
	#########################################################################

	# copy include files mentioned in Service Runtime manifest to Service program target include files directory
	debug_print 3 "Copy Service include files mentioned in Runtime manifest to target include directory"

	while read -r filename; do # 1/ import each filename from manifest

		{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue

		if [ -f "${service_functions_target_dir}/${filename}" ]; then # 1/
			debug_print 4 "Skipping pre-existing include file in target dir: $filename"
			continue
		fi # 1/

		debug_print 4 "Copy source include file: $filename"
		[ -f "${service_functions_target_dir}/${filename}" ] && debug_print 3 "Pre-existing file exists in target dir with same filename, and will be overwritten: $filename"

		if [ -f "${functions_service_source_dir}/manufacturer/${mobo_manufacturer}/${filename}" ] && [ -r "${functions_service_source_dir}/manufacturer/${mobo_manufacturer}/${filename}" ]; then # 1/
			run_command cp -f -v "${functions_service_source_dir}/manufacturer/${mobo_manufacturer}/${filename}" "${service_functions_target_dir}/${filename}"
		else # 1/
			if [ -n "$functions_service_source_dir" ] && [ -f "${functions_service_source_dir}/${filename}" ] && [ -r "${functions_service_source_dir}/${filename}" ]; then # 2/
				run_command cp -f -v "${functions_service_source_dir}/${filename}" "$service_functions_target_dir"
			else # 2/
				run_command cp -f -v "${functions_common_source_dir}/${filename}" "$service_functions_target_dir"
			fi # 2/
		fi # 1/

	done < <(sort -u "$service_runtime_manifest_filename" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames, .sh lines only

	############################################################################
	# Replace Embedded .init Filename References in Service Program Target Files
	############################################################################

	# define Service Launcher init file path when not pre-existing
	if [ -z "$service_launcher_init_filename" ]; then # 1/
		if [ -n "$builder_program_version" ]; then # 2/
			service_launcher_init_filename="${service_launcher_target_dir}/${service_name}_${builder_program_version}.init"
			service_runtime_init_filename="${service_runtime_target_dir}/${service_name}_${builder_program_version}.init"
		else # 2/ program version not defined
			service_launcher_init_filename="${service_launcher_target_dir}/${service_name}_$(date "+%s").init"
			service_runtime_init_filename="${service_runtime_target_dir}/${service_name}_$(date "+%s").init"
		fi # 2/
	fi # 1/

	##
	# Modify hard-coded pointers in Service Launcher and Runtime programs after they
	# have been copied into target directories.
	#
	# These paths are unknown until after source file templates have been copied
	# to target directories, and the Launcher .init file has been created so its
	# path is known.
	##

	debug_print 3 "Modify .init file pointers in Service Launcher"

	# hard-code Service Launcher declarations filename path into Service Launcher executable in target directory
	debug_print 4 "Modify Service Launcher program to load global variable declarations file on start-up"
	sed -i 's%^\s*#\?\s*service_launcher_declarations_filename=".*%service_launcher_declarations_filename="'"$service_launcher_declarations_target_filename"'"%' "$service_launcher_target_filename"

	# hard-code Service Runtime declarations filename path into Service Runtime executable in target directory
	debug_print 4 "Modify Service Runtime program to load global variable declarations file on start-up"
	sed -i 's%^\s*#\?\s*service_runtime_declarations_filename=".*%service_runtime_declarations_filename="'"$service_runtime_declarations_target_filename"'"%' "$service_runtime_target_filename"

	# hard-code Service Launcher initialization filename path into Service Launcher executable in target directory
	debug_print 4 "Modify Service Launcher program to load correct initialization (.init) file on start-up"
	sed -i 's%^\s*#\?\s*init_filename=".*%init_filename="'"$service_launcher_init_filename"'"%' "$service_launcher_target_filename"

	# hard-code Service Runtime initialization filename path into Service Runtime executable in target directory
	debug_print 4 "Modify Service Runtime program to load correct initialization (.init) file on start-up"
	sed -i 's%^\s*#\?\s*init_filename=".*%init_filename="'"$service_runtime_init_filename"'"%' "$service_runtime_target_filename"

	#################################################################
	# Copy Service Failure Notification Handler Program to Target Dir
	#################################################################

	if [ "$enable_failure_notification_service" = true ]; then # 1/
		if [ -n "$service_failure_handler_target_filename" ]; then # 2/

			# copy Service Launcher program executable to its target location
			debug_print 3 "Copy Service Launcher program executable file to its target destination: $service_failure_handler_target_filename"
			run_command cp -f -v "$failure_handler_script_filename" "$service_failure_handler_target_filename"

			if [ ! -f "$service_failure_handler_target_filename" ]; then # 3/
				debug_print 3 warn "Creation of Service Failure Notification Handler program script failed for an unknown reason"
				debug_print 4 warn "Disabling Failure Notification Handler service"
				enable_failure_notification_service=false
			fi # 3/
		else # 2/
			debug_print 3 caution "Failure Notification Handler program file location expected, but not defined"
		fi # 2/
	fi # 1/

	###################################################################
	##
	## Set Target Dir & File Ownership and Permissions for Service User
	##
	###################################################################

	##
	# Ensure Service username will be capable of traversing parent directories and
	# accessing their files as required.
	##

	debug_print 3 "Validate Service user target file and directory level permissions"

	##
	# Set program directory ownership to Service username when Service username is not root.
	# Then set directory permissions to allow Service user sufficient file access while
	# restricting access to others.
	##

	debug_print 3 "Set ownership of target directories to Service user '$service_username'" # n/a when service user = root

	run_command chown -R "$service_username":"$(id -gn "$service_username")" "$service_launcher_target_dir"
	run_command chown -R "$service_username":"$(id -gn "$service_username")" "$service_runtime_target_dir"
	run_command chown -R "$service_username":"$(id -gn "$service_username")" "$service_functions_target_dir"

	##
	# Set appropriate directory access permissions, relative to Service username.
	#
	# When any required directory is missing or Service user cannot be assigned
	# sufficient access to it, then bail with critical error message.
	##

	# Service user needs traverse (access) + read/write rights to various dirs
	! set_target_permissions "$target_dir" PERM_TRAVERSE true && bail_noop "Failed to allow Service user sufficient file access for target files parent directory: $target_dir"
	! set_target_permissions "$service_launcher_target_dir" PERM_READ_TRAVERSE true && bail_noop "Failed to set Service Launcher directory permissions required by Service User: ${service_launcher_target_dir}/"
	! set_target_permissions "$service_runtime_target_dir" PERM_ALL true && bail_noop "Failed to set Service Runtime directory permissions required by Service User: ${service_runtime_target_dir}/"
	! set_target_permissions "$service_functions_target_dir" PERM_READ_TRAVERSE true && bail_noop "Failed to set Service include files directory permissions required by Service User: $service_functions_target_dir"

	# Service user needs execute + read access to executable files
	! set_target_permissions "$service_launcher_target_filename" PERM_READ_TRAVERSE true && bail_noop "Failed to set Service user minimum permissions for Service Launcher executable: $service_launcher_target_filename"
	! set_target_permissions "$service_runtime_target_filename" PERM_READ_TRAVERSE true && bail_noop "Failed to set Service user minimum permissions for Service Runtime executable: $service_runtime_target_filename"

	##
	# 1. Assign read-only permission to all files in Service target dirs for all users.
	# 2. Assign read + execute permissions to required executable files for Service user only.
	# 3. Confirm Service user will be able to run the executables.
	#
	# NOTE: .init files have not been created yet (as these do require write access by Service user).
	# Likewise, these steps do not impact log files and directories, which also require Service user
	# write-level access, and are handled elsewhere.
	##

	# set all files in Service dirs to traverse + read only for all users
	run_command find "$service_functions_target_dir" -type f -exec chmod 555 {} +
	run_command find "$service_launcher_target_dir" -type f -exec chmod 555 {} +
	run_command find "$service_runtime_target_dir" -type f -exec chmod 555 {} +
}
