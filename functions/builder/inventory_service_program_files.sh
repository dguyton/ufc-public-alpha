##
# Builder and Service programs are paired by the same version number.
# Therefore, the Builder program seeks to identify and locate the most
# suitable partnering Service program, primarily based on program version.
#
# This section compares the version of Service programs found in the same
# directory as (this) Builder program in an effort to identify a paired
# Service program with matching version.
#
# Examines each candidate file for an embedded program version variable.
# If no match is found, try parsing the filename for a version number.
#
# If neither Builder nor Service program files have a determinable
# version number, they are treated as matching.
##

##
# Validates the following file types:
#
# --> 1. Service launcher executable (correct program version)
# --> 2. Global variable declaration include file for Service Launcher program
# --> 3. Service runtime executable (correct program version)
# --> 4. Global variable declaration include file for Service Runtime program
# --> 5. Service related include files
# --> 6. Common (shared) include files
# --> 7. Manifest and specified files required for Service Launcher program
# --> 8. Manifest and specified files required for Service Runtime program
##

# inventory available service program source files to ensure required files exist
function inventory_service_program_files ()
{
	[ "$recycle_service_daemons" != true ] && return # prevent this running when it should not

	debug_print 2 "Verify source files"

	[ -z "$service_source_dir" ] && bail_noop "Undefined Service program source file parent directory (/source_dir/service/)"

	################################################################
	# Validate Version Specific Service Launcher Program Source File
	################################################################

	##
	# Verify version-matched program source file exists.
	# Bail when no version matched Launcher file found in source dir.
	##

	debug_print 3 "Scan for version matched Service Launcher executable in ${service_launcher_source_dir}/"

	if ! service_launcher_source_filename="$(find_best_file_version_match "$service_launcher_source_dir" "launcher" "$builder_program_version")"; then # 1/
		bail_noop "Failed to discover any Service Launcher program candidates in related source files directory"
	fi # 1/

	##
	# When not aborted above, it means selected Launcher filename has program version matching this Builder
	##

	service_program_version="$builder_program_version"

	# when neither file has a version number in source code or filename, still consider them a match
	[ -z "$builder_program_version" ] && debug_print 2 caution "Builder and Service program files do not have version numbers (OK)"

	##
	# Scan for Launcher global variable declarations file.
	# Find best match. Bail when no matching file found.
	##

	debug_print 3 "Scan for version matched variable declarations file in ${service_launcher_source_dir}/"

	if ! service_launcher_declarations_filename="$(find_best_file_version_match "$service_launcher_source_dir" "declarations" "$service_program_version")"; then # 1/
		bail_noop "Failed to discover Service Launcher global variable declarations file"
	fi # 1/

	##############################################
	# Validate Service Runtime Program Source File
	##############################################

	##
	# Verify version-matched runtime program source file exists.
	# Bail when no version matched Runtime program file found in source dir.
	##

	debug_print 3 "Scan for version matched Service Runtime executable in ${service_runtime_source_dir}/"

	if ! service_runtime_source_filename="$(find_best_file_version_match "$service_runtime_source_dir" "runtime" "$service_program_version")"; then # 1/
		bail_noop "Failed to discover any Service Runtime program candidates in related source files directory"
	fi # 1/

	##
	# Scan for related global variable declarations file.
	# Bail when no version matched Runtime global variable declarations file
	# found in source dir.
	##

	debug_print 3 "Scan for version matched variable declarations file: ${service_runtime_source_dir}/"

	if ! service_runtime_declarations_filename="$(find_best_file_version_match "$service_runtime_source_dir" "declarations" "$service_program_version")"; then # 1/
		bail_noop "Failed to discover Service Runtime global variable declarations file"
	fi # 1/

	###################################################################
	# Cross-Check Service Include File Manifests vs. Filename Inventory
	###################################################################

	##
	# There are different include file manifests for the Launcher vs. Runtime Service programs.
	# The two programs share the include files in the Service program functions sub-directory,
	# but each program requires a different sub-set of those include files. Their respective
	# include file manifests identify which Service function files each requires.
	#
	# Manifest files are expected in /source_dir/config/ source code directory. Manifest files
	# contain the list of include filenames in the functions directories which are applicable
	# to the given program executable.
	#
	# If an error is encountered such that a manifest is not found in the source file folders,
	# or a required file mentioned in a manifest is missing, the Builder program will abort.
	#
	# The best file match is identified if more than one relevant manifest file exists.
	##

	# locate Service Launcher include file manifest, and confirm all related include files exist in source dirs

	################################
	# Validate Service Include Files
	################################

	##
	# Determine if manifest files exist for Service Launcher and Service Runtime.
	# Check inventory here and verify all expected files exist.
	##

	debug_print 4 "Confirm Service program include manifests and their mentioned files exist"

	# ensure Service user can access parent directory of include file manifest files
	! set_target_permissions "$(dirname "$manufacturer_include_files_dir")" PERM_TRAVERSE true && bail_noop "Service user cannot access Service program include file manifests"

	if ! service_launcher_manifest_filename="$(validate_service_file_manifest "launcher" "$config_source_dir" "$functions_service_source_dir" "$functions_common_source_dir" "$manufacturer_include_files_dir")"; then # 1/
		bail_noop "Failed to locate Service Launcher include file manifest"
	fi # 1/

	if ! service_runtime_manifest_filename="$(validate_service_file_manifest "runtime" "$config_source_dir" "$functions_service_source_dir" "$functions_common_source_dir" "$manufacturer_include_files_dir")"; then # 1/
		bail_noop "Failed to locate Service Runtime include file manifest"
	fi # 1/

	##
	# Determine whether or not there is a manufacturer-specific include files directory
	# for the current motherboard manufacturer. When there is, files in its directory
	# will be prioritized over those in the Service or Common include files directories.
	##

	manufacturer_include_files_dir="${functions_service_source_dir}/manufacturer/${mobo_manufacturer}"

	if ! validate_file_system_object "$manufacturer_include_files_dir" "directory"; then # 1/
		unset manufacturer_include_files_dir
		debug_print 4 "No manufacturer-specific include files were found"
	fi # 1/

	####################################################
	# Validate Service Program Daemon .service Templates
	####################################################

	##
	# Verify daemon service templates exist in working directory.
	# Presume the first matching daemon template file is correct
	# (there should only be one matching file in the directory)
	# for each daemon service file. If there is more than one,
	# then choose the newest file matching the current Builder
	# program version.
	##

	# validate daemon service files
	debug_print 2 "Validate Service program related daemon .service source files"
	debug_print 3 "Scan for version-matched daemon .service templates in ${daemon_source_dir}/"

	# search for Launcher .service daemon template
	if ! launcher_daemon_service_template="$(find_best_file_version_match "$daemon_source_dir" "launcher" "$builder_program_version" "service")"; then # 1/
		bail_with_fans_optimal "Launcher daemon service template file is missing or incorrectly named"
	fi # 1/

	debug_print 4 "Identified Launcher daemon service template: $launcher_daemon_service_template"

	# search for Runtime .service daemon template
	if ! runtime_daemon_service_template="$(find_best_file_version_match "$daemon_source_dir" "runtime" "$builder_program_version" "service")"; then # 1/
		bail_with_fans_optimal "Runtime daemon service template file is missing or incorrectly named"
	fi # 1/

	debug_print 4 "Identified Runtime daemon service template: $runtime_daemon_service_template"

	##########################################################################
	# Validate Daemon Service Failure Notification Handler Template and Script
	##########################################################################

	##
	# Ascertain best available method for handling daemon service
	# failure events.
	#
	# When email alerts are active (email_alerts=true), the Failure
	# Event Handler notifies the user via email when either the
	# Launcher or Runtime daemons fail. Thus, when either underlying
	# program fails for any reason, this daemon service will trigger
	# an email to the user's email address.
	#
	# The FEH daemon triggers a SHell script which performs the
	# actual notification.
	#
	# NOTE: Failure to tag either the FNH .service file or SHell script
	# templates is not a catastrophic failure, but will prevent this
	# feature from working.
	##

	if [ "$enable_failure_notification_service" = true ]; then # 1/ search for Failure Notification Handler .service daemon template
		if failure_handler_daemon_service_template="$(find_best_file_version_match "$daemon_source_dir" "failure" "$builder_program_version" "service")"; then # 2/
			debug_print 4 "Identified 'Failure Notification Handler' daemon service template: $failure_handler_daemon_service_template"
		else # 2/
			debug_print 3 "Failure notification daemon service template file is missing or incorrectly named"
		fi # 2/

		##
		# The SHell script called by the FHN daemon is static, but
		# it is still best to try and identify the correct file by
		# program version when possible.
		##

		if [ -n "$failure_handler_daemon_service_template" ]; then # 2/ validate shell script (.sh file) to be called by FNH daemon on Service program failure
			if ! failure_handler_script_filename="$(find_best_file_version_match "$daemon_source_dir" "failure" "$builder_program_version")"; then # 3/

				# when no match, grab first suitable matching file
				failure_handler_script_filename=$(find "$daemon_source_dir" -iname '*failure*' -name '*.sh' -type f -printf "%T+ %p\n" | sort -r | cut -d' ' -f2 | head -n 1)

				if [ -z "$failure_handler_script_filename" ]; then # 4/ still no match found
					debug_print 3 "Failure Notification Handler SHell script file could not be located"
					unset failure_handler_daemon_service_template
				fi # 4/
			else # 3/
				debug_print 4 "Failure notification handler script: $failure_handler_script_filename"
			fi # 3/
		else # 2/ cannot create new service file without corresponding template
			unset failure_handler_script_filename
		fi # 2/

		# cannot utilize the FNH if either its .service file or SHell script templates are missing
		if [ -z "$failure_handler_daemon_service_template" ] || [ -z "$failure_handler_script_filename" ]; then # 2/
			debug_print 2 caution "Failure Notification Handler daemon service not available"
			unset failure_handler_service_name # prevent attempts to make use of FNH
			enable_failure_notification_service=false
		fi # 2/
	fi # 1/
}
