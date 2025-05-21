##
# Create and validate Service program daemons, but do not activate them yet.
#
# This subroutine creates new systemd daemon .service files for each required
# daemon service: Service Launcher, Service Runtime, and Failure Notification
# Handler by setting up a shared systemd service directory, their respective
# systemd daemon .service files, configuring the .service files, and
# ensuring appropriate file system permissions are set to support the needs
# of the Service program user.
#
# New daemon services are created from standardized templates.
# Only the daemon .service files are created. Validation is also performed.
#
# The actual program files should have been copied beforehand by the Service
# file copying subroutine. If any program files pointed to by these daemon
# services are missing, the program will abort.
##

function create_service_daemons ()
{
	# skip when pre-existing fan controller and its daemon will be re-used
	[ "$recycle_service_daemons" = true ] && return 0

	#############################################
	# Validate systemd Service (Target) Directory
	#############################################

	##
	# Validate daemon service (.service) directory.
	#
	# In order to setup a new implementation of the daemon service files,
	# there must be a known, common directory to install both Service program
	# daemon .service files: one for the Launcher, and one for the RUntime
	# program.
	#
	# If there was a pre-existing installation which was disqualified for
	# recycling, that prior installation may provide a suitable roadmap
	# for determining where to install the daemon service files.
	#
	# When a pre-utilized location exists, it will be applied for re-use
	# (of the same location, not the same files) when no daemon service
	# location was specified in the user-defined configuration file for
	# the Builder program. In other words, the previously utilized location
	# will act as a backup location for a fresh implementation when no
	# other location is explicitly defined in the config file.
	##

	##
	# Prefer declared systemd daemon service directory location over pre-existing
	# dir over incumbent dir (if exists).
	#
	# systemd daemon service directory is determined through the following prioritizied filters:
	# 1. $daemon_service_dir_default : defined in Builder config file and is a valid directory
	# 2. $daemon_service_dir         : when not null (i.e., previously validated)
	# 3. /etc/systemd/system         : system default
	##

	debug_print 1 "Create new service daemons"

	if [ -n "$daemon_service_dir_default" ]; then # 1/ dir specified in config

		# drop trailing forward slash when there is one
		trim_trailing_slash "daemon_service_dir_default"

		##
		# Check if daemon service dir exists or needs to be created
		#
		# Expect when declared directory path is existing that it should contain at least
		# one other .service file. If it does not, still accept the directory as valid and
		# continue, but warn user thee declared directory name is suspicious (void of any
		# .service files).
		##

		if [ -n "$daemon_service_dir_default" ]; then # 2/ passed first phase validation check
			debug_print 3 "Daemon .service file directory specified by user in Builder .config file: $daemon_service_dir_default"

			if ! validate_file_system_object "$daemon_service_dir_default" "directory"; then # 3/ dir does not exist and must be created

				# attempt to create new directory
				if ! run_command mkdir -p "$daemon_service_dir_default" || ! validate_file_system_object "$daemon_service_dir_default" "directory"; then # 4/ dir creation failed
					debug_print 3 warn "Failed to create preferred daemon service sub-directory for an unknown reason"
					unset daemon_service_dir_default
				fi # 4/
			fi # 3/
		fi # 2/

		##
		# After passing validation check and confirmed dir exists,
		# probe adequacy of its file system permissions relative
		# to Service user.
		##

		if [ -n "$daemon_service_dir_default" ]; then # 2/ check dir permissions relative to Service user

			# attempt to set permissions for all users to traverse + read
			if set_target_permissions "$daemon_service_dir_default" 555; then # 3/ success
				debug_print 2 caution "Failed to set default daemon service directory permissions for non-Service users"
			fi # 3/

			# check dir permissions relative to Service user
			if ! set_target_permissions "$daemon_service_dir_default" PERM_ALL true; then # 3/
				if ! set_target_permissions "$daemon_service_dir_default" PERM_READ_TRAVERSE true; then # 4/ minimum required permissions level for Service user
					debug_print 3 warn "Failed to set sufficient permissions for Service user to preferred daemon service directory"
					unset daemon_service_dir_default
				else # 4/ minimal permissions means use of FNH is not an option
					if [ "$enable_failure_notification_service" = true ]; then # 5/ only warn when FNH is requested via config, otherwise there is no point in the warning
						enable_failure_notification_service=false # not possible without Service user ability to edit Failure Notification Handler .service file on-the-fly
						debug_print 3 caution "Preferred daemon service directory will be utilized, though it precludes use of Failure Notification Handler (FNH) service"
						debug_print 4 "Service user lacks sufficient permissions access level to allow use of FNH daemon service"
					fi # 5/
				fi # 4/
			fi # 3/
		fi # 2/
	fi # 1/

	##
	# When daemon service dir not specified in Builder config or its use failed
	# tests above, consider alternative solutions.
	##

	if [ -z "$daemon_service_dir_default" ]; then # 1/ no dir specified in config file or it was invalidated above
		if [ -n "$daemon_service_dir" ]; then # 2/ location detected from previous implementation

			# drop trailing forward slash if there is one
			trim_trailing_slash "daemon_service_dir"

			if [ -n "$daemon_service_dir" ]; then # 3/ not root dir
				if ! validate_file_system_object "$daemon_service_dir" "directory"; then # 4/ if it got removed then attempt to re-create it
					debug_print 3 "Re-create previously used daemon .service file directory: ${daemon_service_dir}/"

					if run_command mkdir -p "$daemon_service_dir" && validate_file_system_object "$daemon_service_dir" "directory"; then # 5/ creation successful
						if ! set_target_permissions "$daemon_service_dir" 555; then # 6/ set default permissions for all users to read only
							debug_print 2 caution "Failed to set default daemon service directory permissions for non-Service users"
						fi # 6/
					else # 5/ dir creation failed
						debug_print 3 warn "Failed to re-create daemon service sub-directory for an unknown reason"
						unset daemon_service_dir
					fi # 5/
				else # 4/ still exists
					debug_print 3 "Examine pre-determined and previously validated daemon .service directory: ${daemon_service_dir}/"
				fi # 4/

				debug_print 3 "Set daemon service directory permissions to allow full access by Service username"

				if ! set_target_permissions "$daemon_service_dir" PERM_ALL true; then # 4/ try lower permissions level that excludes use of FNH service
					if ! set_target_permissions "$daemon_service_dir" PERM_READ_TRAVERSE true; then # 5/ drop incumbent dir
						debug_print 3 warn "Failed to set sufficient permissions for Service user to incumbent daemon Service directory"
						unset daemon_service_dir # trigger continued dir evaluation processes below
					else # 5/ read + execute possible, but not ability to overwrite, which disqualifies use of FNH
						if [ "$enable_failure_notification_service" = true ]; then # 6/
							enable_failure_notification_service=false # not possible without Service user ability to edit Failure Notification Handler .service file on-the-fly
							debug_print 4 caution "Pre-existing daemon service directory will be utilized, however it precludes use of Failure Notification Handler service"
						fi # 6/
					fi # 5/
				fi # 4/
			fi # 3/
		fi # 2/
	else # 1/
		daemon_service_dir="$daemon_service_dir_default" # set pre-existing dir specified in config file as de-facto systemd daemon service directory
	fi # 1/

	# try default system dir as last resort
	if [ -z "$daemon_service_dir" ]; then # 1/ preferred directory disqualified above, and/or not specified, and/or never existed
		daemon_service_dir="/etc/systemd/system" # system baseline default
		debug_print 3 "Probe default daemon .service file directory path: ${daemon_service_dir}/"

		if ! set_target_permissions "$daemon_service_dir" PERM_ALL true; then # 2/
			if ! set_target_permissions "$daemon_service_dir" PERM_READ_TRAVERSE true; then # 3/
				debug_print 3 warn "Failed to set sufficient permissions for Service user to default daemon Service directory"
				bail_with_fans_optimal "Daemon .service file directory not specified in config file, and incumbent location was not found or is undefined"
			else # 3/ read + execute possible, but not ability to overwrite, disqualifying use of FNH
				if [ "$enable_failure_notification_service" = true ]; then # 4/
					enable_failure_notification_service=false # not possible without Service user ability to edit Failure Notification Handler .service file on-the-fly
					debug_print 4 caution "Pre-existing daemon service directory will be utilized, however its use precludes use of Failure Notification Handler service"
				fi # 4/
			fi # 3/
		fi # 2/
	else # 1/ sweep non-system default dir and advise user via program log if systemd dir currently empty
		[ -z "$(find "$daemon_service_dir" -type f -o -type l -iname '*.service' -print -quit)" ] && debug_print 2 caution "systemd service unit directory path is devoid of any other .service files"
	fi # 1/

	##
	# Validate parent-of-parent directory-level permissions
	##

	# Service needs traverse right to parent dir of top-level daemon dir
	! set_target_permissions "$(dirname "$daemon_service_dir")" PERM_TRAVERSE true && bail_with_fans_optimal "Service user lacks sufficient permissions to directories above daemon .service top-level directory"

	###############################################
	# Confirm Program Executable Target Files Exist
	###############################################

	##
	# Confirm presence of both Service executables prior to creating
	# corresponding daemon .service files.
	#
	# Both Service Launcher and Service Runtime program executable files
	# must be known and exist as expected or the daemon service setup
	# process cannot continue.
	##

	{ [ -z "$service_launcher_target_filename" ] || [ ! -f "$service_launcher_target_filename" ]; } && bail_noop "Cannot continue because Service Launcher executable file does not exist"
	{ [ -z "$service_runtime_target_filename" ] || [ ! -f "$service_runtime_target_filename" ]; } && bail_noop "Cannot continue because Service Runtime executable file does not exist"

	############################
	# Create New Daemon Services
	############################

	##
	# Create a new systemd daemon service unit file linked to the service program.
	# A template is copied from the working directory to the directory where
	# systemd expects to find service unit files. The target file is then modified
	# to point to the service program file, located in the service program directory.
	##

	##
	# Check if identical named systemd service unit file is pre-existing.
	# When found, the old/pre-existing file must be removed before the new
	# file with the same service file may be established. The service with
	# the same name should have been stopped in a previous step, above;
	# if [ -n "$log_filename" ], stopping it does not remove the conflicting service. This
	# step seeks to handle the removal of the old/incumbent service unit.
	##

	##
	# Ensure daemon service template file is present in working directory.
	#
	# The daemon service template is copied to the server's systemd service
	# unit folder. The file is then customized to point to the Service program.
	##

	debug_print 2 "Create new '$service_name' daemon services"

	################################################################
	# Copy Service Launcher Daemon Template to Daemon Service Folder
	################################################################

	##
	# Presumptions
	# --> not recycling pre-existing installation
	# --> old files in target location have been deleted before this subroutine runs
	# --> pre-existing daemon service directories may remain, and this is ok
	##

	##
	# Expectation is old filename targets will not still be pointed to. If they are,
	# this is because pre-existing files were not deleted via the old service file
	# removal subroutine, which is called prior to this sub.
	#
	# When this circumstance is true, warn user pre-existing files are still present.
	# Old filenames will be ignored and the program will attempt to utilize new
	# target filenames based using a naming algorithm. If the new target filenames
	# are in use, an alternate naming method will be used that should provide a unique
	# filename. If that fails, abort.
	#
	# If the calculated target filename is pre-existing as any file system object type,
	# the program will not attempt to remove it and will abort.
	#
	# These failsafe mechanisms exist to prevent accidental deletion of non-related
	# daemon service files and/or when the current user lacks sufficient file system
	# access to failitate setting up or resetting the program configuration properly.
	##

	debug_print 4 "Process new Service Launcher daemon service file"

	# check for pre-existing file that could not be removed previously
	if [ -n "$launcher_daemon_service_filename" ]; then # 1/ pre-existing file removal subroutine failed to remove old daemon .service file
		debug_print 3 warn "Failed to remove pre-existing matching Service Launcher daemon .service file system object"
		debug_print 4 bold "Ignore conflicting file system object and calculate new target filename"
	fi # 1/

	if [ "$launcher_daemon_service_filename" = "${daemon_service_dir}/${launcher_daemon_service_name}.service" ]; then # 1/ calculated filename would be the same as pre-existing
		debug_print 2 caution "Cannot create expected new filename because it would match pre-existing filename that previously could not be removed"
		debug_print 3 "Apply alternate method utilizing current date/time string"

		# assign new target filename per file naming algorithm
		launcher_daemon_service_filename="${daemon_service_dir}/${launcher_daemon_service_name}_$(build_date_time_string).service"

	else # 1/ assign new target filename using preferred naming convention
		launcher_daemon_service_filename="${daemon_service_dir}/${launcher_daemon_service_name}.service"
	fi # 1/

	##
	# Failure to remove old Launcher daemon .service file is a stopper.
	#
	# When a file system object with the new target filename is detected as
	# already in use, it means if there was a previous implementation, either
	# the current user does not have the permission rights to remove it, or
	# there is a non-related file system object that should not be removed,
	# as it likely pertains to some other process or program (i.e. it is not
	# related to the fan controller Services).
	#
	# This process is intended to act as a failsafe mechanism to prevent
	# accidentally deleting files not related to this program or the Service
	# programs it creates.
	##

	[ -e "$launcher_daemon_service_filename" ] && bail_with_fans_optimal "Cannot continue because revised target filename already in use by file system: $launcher_daemon_service_filename"

	debug_print 4 "Service Launcher .service daemon target filename: $launcher_daemon_service_filename"

	################################################################
	# Copy Service Launcher Daemon Template to Daemon Service Folder
	################################################################

	##
	# Copy Service Launcher daemon .service source template to target location
	#
	# The templates in this subroutine were previously vetted
	# by the inventory_service_program_files subroutine.
	##

	debug_print 3 "Copy Service Launcher systemd .service file template as $launcher_daemon_service_filename"

	# trap file copy/create failure
	if ! run_command cp -f "$launcher_daemon_service_template" "$launcher_daemon_service_filename" || ! validate_file_system_object "$launcher_daemon_service_filename" "file"; then # 1/
		bail_with_fans_optimal "Failed to create Service Launcher daemon .service for an unknown reason"
	fi # 1/

	# ensure current user is capable of modifying daemon service file
	if ! set_target_permissions "$launcher_daemon_service_filename" PERM_ALL; then # 1/
		debug_print 4 "Discard new file"
		! run_command rm -f "$launcher_daemon_service_filename" && debug_print 4 warn "Failed to remove new file: $launcher_daemon_service_filename"
		bail_with_fans_optimal "Cannot customize Launcher daemon service file due to target file permission constraints"
	fi # 1/

	debug_print 3 "Service Launcher systemd daemon service: $launcher_daemon_service_name"

	###############################################################
	# Copy Service Runtime Daemon Template to Daemon Service Folder
	###############################################################

	debug_print 4 "Process new Service Runtime daemon service file"

	# check for pre-existing file that could not be removed previously
	if [ -n "$runtime_daemon_service_filename" ]; then # 1/
		if validate_file_system_object "$runtime_daemon_service_filename" "file"; then # 2/ pre-existing daemon .service file not previously removed as expected
			debug_print 3 warn "Failed to remove pre-existing matching Service Runtime daemon .service file system object"
			debug_print 4 bold "Ignore conflicting file system object and re-calculate target filename"
		fi # 2/

		if [ "$runtime_daemon_service_filename" = "${daemon_service_dir}/${runtime_daemon_service_filename}.service" ]; then # 2/ calculated filename would be the same as pre-existing
			debug_print 2 caution "Cannot create expected new filename because it would match pre-existing filename that previously could not be removed"
			debug_print 3 "Apply alternate method utilizing current date/time string"

			# assign new target filename per file naming algorithm
			runtime_daemon_service_filename="${daemon_service_dir}/${runtime_daemon_service_name}_$(build_date_time_string).service"

		else # 2/ assign new target filename using preferred naming convention
			runtime_daemon_service_filename="${daemon_service_dir}/${runtime_daemon_service_name}.service"
		fi # 2/

		# check for pre-existing file system object conflict
		debug_print 4 "Service Runtime .service daemon target filename: $runtime_daemon_service_filename"

		! validate_file_system_object "$runtime_daemon_service_filename" "file" && bail_with_fans_optimal "Cannot continue because revised target filename already in use by file system: $runtime_daemon_service_filename"

		# copy Service Runtime daemon service template to target location
		debug_print 3 "Copy Service Runtime systemd .service file template as $runtime_daemon_service_filename"

		# trap copy/create failure
		if ! run_command cp -f "$runtime_daemon_service_template" "$runtime_daemon_service_filename" || ! validate_file_system_object "$runtime_daemon_service_filename" "file"; then # 2/
			bail_with_fans_optimal "Failed to create Service Runtime daemon .service for an unknown reason: $runtime_daemon_service_filename"
		fi # 2/

		# ensure user is capable of modifying daemon service file
		if ! set_target_permissions "$runtime_daemon_service_filename" PERM_ALL; then # 3/
			debug_print 4 "Discard new files"
			! run_command rm -f "$runtime_daemon_service_filename" && debug_print 4 warn "Failed to remove new file: $runtime_daemon_service_filename"
			! run_command rm -f "$launcher_daemon_service_filename" && debug_print 4 warn "Failed to remove new file: $launcher_daemon_service_filename"
			bail_with_fans_optimal "Cannot customize new Service Runtime daemon service file due to permission constraints of new current user"
		fi # 2/
	fi # 1/

	debug_print 3 "Service Runtime systemd daemon service: $runtime_daemon_service_name"

	############################################################################
	# Copy Failure Notification Handler Daemon Template to Daemon Service Folder
	############################################################################

	if [ "$enable_failure_notification_service" = true ] && [ "$email_alerts" != true ]; then # 1/
			debug_print 2 caution "Failure Notification Handler disabled because email functionality is disabled per config"
			enable_failure_notification_service=false
	fi # 1/

	# disqualify when one or more FNH daemon service file paths are unknown
	if ! validate_file_system_object "failure_handler_daemon_service_filename" "file" || ! validate_file_system_object "service_failure_handler_target_filename" "file"; then # 1/
		enable_failure_notification_service=false
	fi # 1/

	##
	# Setup FNH only when its systemd service name is pre-defined and its program
	# script exists. The FNH process is desired, but not required. Therefore, if it
	# is not available, the Service program daemons may be setup without it.
	##

	if [ "$enable_failure_notification_service" = true ]; then # 1/
		if [ -n "$failure_handler_service_name" ]; then # 2/ FNH daemon service name must be known
			if [ -n "$service_failure_handler_target_filename" ]; then # 3/ target path name of script to be pointed to must be known

				# check for pre-existing file that was not removed previously
				if [ -n "$failure_handler_daemon_service_filename" ] && [ -e "$failure_handler_daemon_service_filename" ]; then # 4/ pre-existing daemon .service file not previously removed as expected
					debug_print 3 warn "Failed to remove pre-existing matching Service Failure Notification Handler daemon .service file system object"
					debug_print 4 bold "Ignore conflicting file system object and re-calculate target filename"
				fi # 4/

				if [ "$failure_handler_daemon_service_filename" = "${daemon_service_dir}/${failure_handler_service_name}.service" ]; then # 4/
					debug_print 2 caution "Cannot use preferred filename because it conflicts with a pre-existing file system object"
					debug_print 3 "Applying alternate method utilizing current date/time string to fabricate unique filename"
					failure_handler_daemon_service_filename="${daemon_service_dir}/${failure_handler_service_name}_$(build_date_time_string).service"
				else # 4/ assign new target filename using preferred naming convention
					failure_handler_daemon_service_filename="${daemon_service_dir}/${failure_handler_service_name}.service"
				fi # 4/

				# check for pre-existing file system object conflict
				if validate_file_system_object "$failure_handler_daemon_service_filename" "file"; then # 4/
					debug_print 3 warn "Cannot utilize FNH daemon because revised daemon target filename is in use: $failure_handler_daemon_service_filename"
					enable_failure_notification_service=false
				else # 4/ happy path
					debug_print 4 "Failure Notification Handler .service daemon target filename: $failure_handler_daemon_service_filename"
					debug_print 3 "Copy Failure Notification Handler systemd daemon .service template as: $failure_handler_daemon_service_filename"

					if validate_file_system_object "$failure_handler_daemon_service_template" "file"; then # 5/ ensure template exists
						if run_command cp -f "$failure_handler_daemon_service_template" "$failure_handler_daemon_service_filename" && validate_file_system_object "$failure_handler_daemon_service_filename" "file"; then # 6/ daemon .service template copy process succeeded
							if ! set_target_permissions "$failure_handler_daemon_service_filename" PERM_ALL true; then # 7/ un-happy path; Service user lacks full permissions to daemon .service file
								debug_print 3 "Service user lacks sufficient permissions to modify Failure Notification Handler (FNH) daemon .service file"
								enable_failure_notification_service=false
							fi # 7/
						else # 6/ template copy process failed
							debug_print 2 warn "Failure Notification Handler daemon .service file creation failed (template copy failed)"
							debug_print 1 critical "Failed to create Failure Notification Handler daemon .service for an unknown reason: $failure_handler_daemon_service_filename"
							enable_failure_notification_service=false
						fi # 6/
					else # 5/
						debug_print 3 warn "Failure Notification Handler program template is missing or undefined"
						enable_failure_notification_service=false
					fi # 5/
				fi # 4/
			else # 3/
				debug_print 3 caution "Failure Notification Handler (FNH) daemon service name defined, but location of its executable is not"
				debug_print 4 warn "Check program logic, as var should not be null: \$service_failure_handler_target_filename" true
				enable_failure_notification_service=false
			fi # 3/
		else # 2/
			debug_print 3 "Failure Notification Handler (FNH) daemon service name not defined"
			enable_failure_notification_service=false
		fi # 2/
	fi # 1/

	# validate Service user ability to execute FNH program file
	if [ "$enable_failure_notification_service" = true ]; then # 1/
		if ! set_target_permissions "$service_failure_handler_target_filename" 444; then # 2/
			debug_print 2 caution "Failed to set FNH SHell script file system permissions for non-Service users to read-only: $service_failure_handler_target_filename"

			if ! set_target_permissions "$service_failure_handler_target_filename" PERM_READ_TRAVERSE true; then # 3/
				debug_print 4 warn "Failed to set FNH SHell script file permissions correctly for Service user: $service_failure_handler_target_filename"
				enable_failure_notification_service=false
			fi # 3/
		fi # 2/
	fi # 1/

	if [ "$enable_failure_notification_service" != true ]; then # 1/ FNH daemon setup failed
		debug_print 1 warn "Failed to create Failure Notification Handler daemon .service for an unknown reason: $failure_handler_daemon_service_filename"
		debug_print 2 caution "Automatic Service failure notification capabilities are disabled"

		unset failure_handler_service_name
		unset failure_handler_daemon_service_filename
		unset failure_handler_daemon_service_template
		unset service_failure_handler_target_filename
	fi # 1/

	################################
	# Customize Daemon Service Files
	################################

	##
	# Search & replace text blobs using 'sed' to customize target .service files.
	# Tweak contents of copied template files with corresponding service program info.
	#
	# Note some of these lines will intentionally cause systemd to look for the paired
	# daemons between the Service Launcher and Runtime programs, respectively. This is
	# failsafe mechanism to ensure both components exist and are valid that systemd is
	# able to handle directly.
	##

	# modify parameters of Service Launcher deamon .service file
	debug_print 4 "Modify dynamic parameters in Service Launcher daemon .service file: $launcher_daemon_service_filename"

	sed -i 's%^\s*#\?\s*program_version=".*%# program_version="'"$builder_program_version"'"%' "$launcher_daemon_service_filename"
	sed -i 's%^\s*#\?\s*Description=.*%Description='"$program_name"' Launcher v'"$service_program_version"'%I' "$launcher_daemon_service_filename"
	sed -i 's%^\s*#\?\s*Wants=.*%Wants='"$runtime_daemon_service_name"'%I' "$launcher_daemon_service_filename"
	sed -i 's%^\s*#\?\s*Before=.*%Before='"$runtime_daemon_service_name"'%I' "$launcher_daemon_service_filename"
	sed -i 's%^\s*#\?\s*OnSuccess=.*%OnSuccess='"$runtime_daemon_service_name"'%I' "$launcher_daemon_service_filename"
	sed -i 's%^\s*#\?\s*ExecStart=.*%ExecStart='"$service_launcher_target_filename"'%I' "$launcher_daemon_service_filename"

	# modify parameters of Service Runtime deamon .service file
	debug_print 4 "Modify dynamic parameters in Service Runtime daemon .service file: $runtime_daemon_service_filename"

	sed -i 's%^\s*#\?\s*program_version=".*%# program_version="'"$builder_program_version"'"%' "$runtime_daemon_service_filename"
	sed -i 's%^\s*#\?\s*Description=.*%Description='"$program_name"' Runtime v'"$service_program_version"'%I' "$runtime_daemon_service_filename"
	sed -i 's%^\s*#\?\s*After=.*%After='"$launcher_daemon_service_name"'%I' "$runtime_daemon_service_filename"
	sed -i 's%^\s*#\?\s*ExecStart=.*%ExecStart='"$service_runtime_target_filename"'%I' "$runtime_daemon_service_filename"

	#####################################################
	# Change File and Directory Ownership to Service User
	#####################################################

	##
	# Generally speaking, all users should have limited access to the daemon
	# service directory and files.
	#
	# However, the Service program user requires all access permissions to both
	# the daemon directory and the Failure Notifications Handler (FNH) daemon
	# service file. The latter is because both the Service Launcher and Runtime
	# programs will modify the FNH daemon service multiple times. This allows
	# the FNH service to be more informative to the end user when a problem
	# arises that causes either Service program to fail.
	##

	if [ "$service_username" != "root" ]; then # 1/ non-root user expected to run daemon .service files
		debug_print 3 "Set daemon service directory and Launcher daemon service file ownership to Service username"
		run_command chown "$service_username":"$(id -gn "$service_username")" "$launcher_daemon_service_filename"
		run_command chown "$service_username":"$(id -gn "$service_username")" "$runtime_daemon_service_filename"
	fi # 1/

	# set Launcher daemon filename permissions to read only for all user types except Service user, who also needs execute right
	! set_target_permissions "$launcher_daemon_service_filename" 444 && debug_print 2 caution "Failed to set Launcher daemon service file system permissions for non-Service users to read-only"

	! set_target_permissions "$launcher_daemon_service_filename" PERM_READ_TRAVERSE true && bail_with_fans_optimal "Failed to set Launcher daemon file permissions correctly for Service user: $launcher_daemon_service_filename"

	# set Runtime daemon filename permissions to read only for all user types except Service user, who also needs execute right
	! set_target_permissions "$runtime_daemon_service_filename" 444 && debug_print 2 caution "Failed to set Runtime daemon service file system permissions for non-Service users to read-only"

	! set_target_permissions "$runtime_daemon_service_filename" PERM_READ_TRAVERSE true && bail_with_fans_optimal "Failed to set Runtime daemon file permissions correctly for Service user: $runtime_daemon_service_filename"

	############################
	# Complete FNH Configuration
	############################

	if [ "$enable_failure_notification_service" = false ] && [ -n "$failure_handler_daemon_service_filename" ]; then # 1/ remove file since it cannot be used
		debug_print 4 "Discard obsolete FNH daemon .service file"
		if ! run_command rm -f "$failure_handler_daemon_service_filename" || validate_file_system_object "$failure_handler_daemon_service_filename" "file"; then # 2/
			debug_print 4 warn "File removal failed for an unknown reason"
		fi # 2/
	fi # 1/

	if [ "$enable_failure_notification_service" = true ]; then # 1/ configure FNH starting implementation
		debug_print 3 "Service Failure Notification Handler systemd daemon service name: $failure_handler_service_name"
		debug_print 4 "Customize Failure Notification Handler daemon .service file: $failure_handler_daemon_service_filename"

		# static parameters; use service names known to systemd, not filename path
		sed -i 's%^\s*#\?\s*program_version=".*%# program_version="'"$builder_program_version"'"%' "$failure_handler_daemon_service_filename"
		sed -i 's%^\s*#\?\s*Description=.*%Description='"$program_name"' Service Failure Notification Handler v'"$service_program_version"'%I' "$failure_handler_daemon_service_filename"
		sed -i 's%^\s*#\?\s*After=.*%After='"$launcher_daemon_service_name"' '"$runtime_daemon_service_name"'%I' "$failure_handler_daemon_service_filename"
		sed -i 's%^\s*#\?\s*ExecStart=.*%ExecStart='"$service_failure_handler_target_filename"'%I' "$failure_handler_daemon_service_filename"

		# enable email address for alerts when Service program failure occurs
		sed -i 's%^\s*#\?\s*Environment="email=.*%Environment="email='"$email"'%I' "$failure_handler_daemon_service_filename"

		# ensure log echo feature is disabled
		sed -i 's%^\s*#\?\s*Environment="log_filename=.*%# Environment="log_filename="%I' "$failure_handler_daemon_service_filename"

		# activate redirects in Launcher and Runtime daemon service files
		debug_print 3 "Modify Service Launcher and Runtime daemon .service files to trigger FNH daemon service on program failure"

		sed -i 's%^\s*#\?\s*OnFailure=.*%OnFailure='"$failure_handler_service_name"'%I' "$launcher_daemon_service_filename"
		sed -i 's%^\s*#\?\s*OnFailure=.*%OnFailure='"$failure_handler_service_name"'%I' "$runtime_daemon_service_filename"

		if [ -n "$service_username" ]; then # 2/ non-root user expected to run daemon .service files
			debug_print 3 "Set daemon service directory and Launcher daemon service file ownership to Service username"

			! run_command chown "$service_username":"$(id -gn "$service_username")" "$failure_handler_daemon_service_filename" && debug_print 4 "'chown' command failed for an unknown reason"

			# set FNH daemon filename permissions to read only for all user types except Service user, who needs full access to allow Launcher and Runtime executables to update it
			! set_target_permissions "$failure_handler_daemon_service_filename" 444 && debug_print 2 caution "Failed to set FNH daemon service file system permissions for non-Service users to read-only"

			! set_target_permissions "$failure_handler_daemon_service_filename" PERM_ALL true && bail_with_fans_optimal "Failed to set FNH daemon file permissions correctly for Service user: $failure_handler_daemon_service_filename"
		fi # 2/
	fi # 1/
}
