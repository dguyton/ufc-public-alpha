#!/bin/bash

##
# shellcheck source=/dev/null
# shellcheck disable=SC2034  # Don't warn about unused variables
# shellcheck disable=SC2154  # Don't warn about undefined variables
# shellcheck disable=SC2317  # Don't warn about unreachable commands
##

##
# Universal Fan Controller (UFC)
# Builder program version 2.0
#
# Builder and Service programs are version specific and must match.
#
# DO NOT REMOVE LINE BELOW
# program_version="2.0"
##

##
# Program Overview
#
# This program is the PID fan controller Service Launcher.
#
# There are two "Service" program components: the Launcher and the Runtime modules.
# The Launcher sets up the runtime environment, and the Runtime script is an infinite loop that
# is the actual fan controller workhorse.
#
# The Service Launcher requires parameters - such as user preferences - passed to it via the
# "Builder" program.
#
# The Service program is the actual PID fan controller workhorse. The Builder is an orchestrator.
##

#################################################

# this program is a CPU and chassis fan control script written in BaSH
# tested operating system: Ubuntu 16/18/20/22/24
# tested hardware environment: SuperMicro X9DRi-F | Supermicro 835 3U chassis | dual Xeon E5-2680 v2 | 2x Noctua NH-D9DX i4 3U cpu fans | 5x stock case fans

########################
# What This Program Does
########################
# 1. When CPU temperatures rise, adjusts the speed of CPU fans.
# 2. When disk temperatures rise, adjusts the speed of case fans.
# 3. Proactively monitors for signs of unresponsive fans, and when this occurs cold restart the BMC, and try again to control the fan speed.
# 4. If shared cpu/disk cooling is specified, and cpu temperature is high, then use the case fans to provide additional cooling.

#################
# Version History
#################
#
# The following changes by David Guyton
#
# 2024-Nov-04 New version 2.0 of modular program framework
#
#################

##########
# Pre-Init
##########

# required pre-defined global variables needed before declarations file is loaded
declare init_filename
declare program_name
declare service_launcher_declarations_filename

##
# Set placeholder program name global variable in case an exit condition
# occurs prior to loading .init file. Even though the Runtiem global variable
# declarations file will overwrite this declaration when imported, the content
# of the variable will not be overwritten, though it may be when the .init file
# is loaded. This is fine, as the only purpose of also declaring it here is to
# prevent traps triggered prior to the .init file being loaded from entering
# syslog records without a reference to this program.
##

program_name="Universal Fan Controller (UFC)" # may be modified by .init file

##
# Lines below will be modified by Builder in-vitro to substitute
# correct filenames and un-comment the lines.
##

## DO NOT REMOVE LINE BELOW
# service_launcher_declarations_filename="{service_program_target_dir}/declarations_service_launcher.sh"

## DO NOT REMOVE LINE BELOW
# init_filename="{service_program_target_dir}/{service_name}_launcher.init"

###########################
# Format Exit Code Messages
###########################

##
# Human-readable error messages pushed to the user when a controlled program
# exit occurs. This information may help the user to diagnose potential
# problems with the Service Launcher program or their system hardware.
##

declare -a exit_code

exit_code[1]="global variable declarations filename undefined, missing, invalid, or user lacks permission to read it"
exit_code[2]="Service Launcher init file location not defined"
exit_code[3]="Service Launcher init file location is invalid"
exit_code[4]="file import command failed when loading Service Launcher declarations file"
exit_code[5]="file import command failed when loading Service Launcher initialization file"
exit_code[6]="Service Runtime directory is invalid: $service_runtime_dir"
exit_code[7]="Service include files directory is invalid: $service_functions_dir"
exit_code[8]="no source code (.sh) files found in Service include files dir: $service_functions_dir"
exit_code[9]="missing Service Runtime program executable"
exit_code[10]="Service Launcher include file manifest is missing or unknown"
exit_code[11]="Service Runtime include file manifest is missing or unknown"
exit_code[12]="one or more Service Launcher include files failed to load correctly"
exit_code[13]="one or more Service Runtime include files are missing"

# systemd notification messages
declare -a notify_on_exit

notify_on_exit[1]="failed to load Launcher global variable declarations file"
notify_on_exit[2]="Launcher init file not found"
notify_on_exit[3]="failed to identify Launcher init file"
notify_on_exit[4]="failed to import Service Launcher declarations file"
notify_on_exit[5]="failed to import Service Launcher initialization file"
notify_on_exit[6]="failed to identify Runtime directory"
notify_on_exit[7]="include files directory not found"
notify_on_exit[8]="missing required include files"
notify_on_exit[9]="Service Runtime executable file not available"
notify_on_exit[10]="one or more Service Launcher include files not found"
notify_on_exit[11]="one or more Service Runtime include files not found"
notify_on_exit[12]="one or more include files failed to load correctly"
notify_on_exit[13]="failed to validate all Service Runtime include files"

########################################
# Establish Minimal Required Subroutines
########################################

##
# These functions must be included directly in the Service Launcher so that
# they are available natively, prior to importing include files. Because the
# Launcher runs for such a brief period on system startup, these need to be
# loaded up front in order to maximize error communication when something
# goes wrong with the Launcher.
##

# keep systemd informed
function notify_systemd_status ()
{
	# bail when no message or command unknown
	[ -z "$1" ] && return 1
	! command -v systemd-notify &>/dev/null && return 1

	# send systemd notification message
	systemd-notify --status="$1"
}

# sys-logging decision maker
function send_to_syslog ()
{
	[ -z "$1" ] && return 1 # bail when message is empty

	# post info in system log when possible, depending on user prefs
	if [ -z "$log_to_syslog" ] || { [ -n "$log_to_syslog" ] && [ "$log_to_syslog" = true ]; }; then # 1/
		if command -v system_logger &>/dev/null; then # 2/
			if system_logger "$1"; then # 3/
				return 0 # success
			else # 3/
				return 1 # something went wrong with system_logger subroutine
			fi # 3/
		else # 2/
			if command -v logger &>/dev/null; then # 3/
				logger -t "$program_name" "Launcher: $1"
				return 0
			fi # 3/
		fi # 2/
	fi # 1/

	# no message or no syslog program is available
	return 1
}

##
# Trap forced exits
#
# This function is called when the program is abruptly halted via a system signal.
# For example, an interrupt.
#
# This this type of exit may not trigger the Failure Notification Handler, there
# is a trap setup to capture common signals, which then triggers this script to
# attempt alerting the user and reporting some related information to them.
##

function trap_door_on_signal ()
{
	local message

	message="exit on SIG trap : PID=$$"

	if command -v bail_noop &>/dev/null; then # 1/ call exit sub when loaded
		bail_noop "$message"
		exit
	else # 1/ otherwise syslog it
		send_to_syslog "$message"
	fi # 1/

 	# stop here when email addr or sendmail not available
	if [ -z "$email" ] || ! command -v sendmail &>/dev/null; then # 1/
		exit
	fi # 1/

	# send email to user
	{
		printf "%s\n" "To: $email"
		printf "%s\n" "Subject: UFC Service Failure Notification [SIG trap]"
		printf "%s\n" "Content-Type: text/plain; charset=UTF-8"
		printf "\n" # separate headers from the body per sendmail requirements
		printf "$program_name system Service Launcher on %s was stopped abruptly\n" "$(hostname)"
		printf "due to a non-planned system event (SIGnal trap trigger), causing the program to exit.\n\n"
		printf "%s\n\n" "${message^}"
		[ -n "$log_filename" ] && printf "More information may be available in the UFC Service program log found here:\n%s\n" "$log_filename"
	} | sendmail -t 2>&1 | send_to_syslog "SIG trap door email notification sent" || send_to_syslog "failed to send SIG trap door email notification"

	exit
}

##
# Clean-up on standard exits.
#
# This function is called when the program hits an Exit command for any reason.
##

function trap_door_on_exit ()
{
	local message
	local response

	response="$1"
	response="$(printf "%.0f" "${response//[!0-9]/}")" # numeric only; defaults to 0

	message="exit code "

	# embed error code and human-readable error message if exists
	if (( response > 0 )); then # 1/
		message+="$response"
		[ -n "${exit_code[$response]}" ] && message+=" : ${exit_code[$response]}"

		[ -n "${notify_on_exit[$response]}" ] && notify_systemd_status "Error: ${notify_on_exit[$response]}"
	else # 1/
		message+="unknown"
	fi # 1/

	# call exit sub when loaded
	command -v bail_noop >&/dev/null && bail_noop "$message"

	# post info in system log when possible
	send_to_syslog "$message"

	# send email to user
	if [ -n "$email" ] && command -v sendmail &>/dev/null; then # 1/
		{
			printf "%s\n" "To: $email"
			printf "%s\n" "Subject: UFC Service Failure Notification"
			printf "%s\n" "Content-Type: text/plain; charset=UTF-8"
			printf "\n" # separate headers from the body per sendmail requirements
			printf "$program_name system Service Launcher on %s detected a failure condition and exited\n\n" "$(hostname)"
			printf "%s\n\n" "${message^}"
			[ -n "$log_filename" ] && printf "Check UFC Service program log for details: %s\n" "$log_filename"
		} | sendmail -t 2>&1 | send_to_syslog "EXIT trap door email notification sent" || send_to_syslog "failed to send EXIT trap door email notification"
	fi # 1/

	exit
}

##
# Verify file or directory exists and determine which it is, if either.
#
# File system object ($1) is required and must be an existing object.
#
# Object type ($2) is an optional parameter. When specified, confirm whether or not
# the target object is the same type of object as that specified ($2). When it is,
# resolve exit code to successful. When it is not, resolve exit code to failure.
#
# Regardless of whether or not a specific object type is specified ($2), the
# following rules apply to determining 'success' based on object type:
#
# 1. When object type = directory
#	- specified directory exists
# 2. When object type = file
#	- specified file exists
#	- specified file can be read by current user
#
# The function fails when above criteria are not met or object is not the expected
# object type (when specified) or object type is neither a file nor a directory.
##

function validate_file_system_object ()
{
	local actual_object_type
	local debug_available
	local expected_object_type
	local file_system_object

	command -v debug_print &>/dev/null && debug_available=true

	if [ -z "$1" ]; then # 1/
		if [ "$debug_available" = true ]; then # 2/
			debug_print 4 "Undefined file system object variable name '\$1'"
		else # 2/
			printf "Undefined file system object variable name '\$1'\n"
		fi # 2/

		return 1 # fail if no object provided
	fi # 1/

	# object name must be a direct, full file system path
	file_system_object="$1"

	##
	# Note expected object type (file or directory) when specified.
	# When not specified, whichever is auto-detected will be presumed
	# to be the correct/expected type.
	##

	[ -n "$2" ] &&	expected_object_type="$2"

	[ "$debug_available" = true ] && debug_print 4 "Validate existence and type of file system object: $file_system_object"

	##
	# Determine whether or not the target file system object exists or not, and determine what
	# type of object it is.
	##

	if [ -e "$file_system_object" ]; then # 1/ file system object exists
		if [ -d "$file_system_object" ]; then # 2/
			actual_object_type="directory"
		else # 2/
			if [ -f "$file_system_object" ]; then # 3/
				actual_object_type="file"
			else # 3/
				if [ "$debug_available" = true ]; then # 4/
					debug_print 3 warn "Named file system object is not a file or directory (incompatible object type)" true
				else # 4/
					printf "Named file system object is not a file or directory (incompatible object type)\n"
				fi # 4/

				return 1 # do not continue
			fi # 3/
		fi # 2/
	else # 1/ file system object does not exist
		if [ "$debug_available" = true ]; then # 2/
			debug_print 3 warn "Named file system object does not exist" true
		else # 2/
			printf "Named file system object does not exist\n"
		fi # 2/

		return 1 # do not continue
	fi # 1/

	##
	# Compare actual object type to expected object type, when relevant
	##

	if [ -n "$expected_object_type" ] && [ "$actual_object_type" != "$expected_object_type" ]; then # 1/
		notify_systemd_status "error: file system object type mis-match"

		if [ "$debug_available" = true ]; then # 2/
			debug_print 3 warn "Named file system object is not specified type '${expected_object_type}', but is type '${actual_object_type}'" true
		else # 2/
			send_to_syslog "error: file system object not a $expected_object_type"
		fi # 2/

		return 1
	fi # 1/

	##
	# Actual and expected object types match
	##

	# further scrutinize files for readability by current user
	if [ "$actual_object_type" = "file" ]; then # 1/
		if [ ! -r "$file_system_object" ]; then # 2/ confirm ability of current user to read file
			notify_systemd_status "error: file cannot be read by current user"

			if [ "$debug_available" = true ]; then # 3/
				debug_print 3 warn "File exists, but cannot be read"
			else # 3/
				send_to_syslog "file exists, but cannot be read"
			fi # 3/

			return 1 # fail
		fi # 2/
	fi # 1/

	[ "$debug_available" = true ] && debug_print 4 "Validated file system object: $file_system_object ($actual_object_type)"
}

##
# Failure Notification Handler (FNH) daemon log filename variable refresh.
#
# Include program log file path when appropriate.
#
# Dynamically enables or disables the program log file path link in the
# failure email generated by the FNH script, which is triggered by
# the Failure Notification Handler daemon. Depending on whether or not a
# program log file is currently active determines how this subroutine
# adjusts the related FNH daemon variable.
##

function refresh_failure_handler_daemon ()
{
	# skip when FNH service not utilized
	[ "$enable_failure_notification_service" != true ] && return 0

	[ -z "$failure_handler_daemon_service_filename" ] && return 1

	##
	# The log_filename pointer may or may not be commented out.
	# And while the file should be formatted consistently, the
	# commands below allow for the possibility its lines may
	# or may not contain leading white space. Whether or not
	# the line is remmed out is irrelevant and will not affect
	# the logic below.
	##

	# dynamically set log file echo behavior on or off
	if [ -n "$log_filename" ] && [ "$log_file_active" = true ]; then # / assign current $log_filename value
		sed -i 's%^\s*#\?\s*Environment="log_filename=.*%Environment="log_filename='"$log_filename"'"%I' "$failure_handler_daemon_service_filename"
	else # 1/ disable copying alert to program log when log file does not exist or should not be applied
		sed -i 's%^\s*#\?\s*Environment="log_filename=.*%# Environment="log_filename="%I' "$failure_handler_daemon_service_filename"
	fi # 1/
}

##
# Enable Failure Notification Handler (FNH) daemon
#
# Re-enable FNH daemon service functionality after it
# was suspended as part of normal program operations.
#
# 1. Enables FNH daemon service functionality
# 2. Does nothing when Service user email not specified
# 3. Enable email alerts on Service program failure
##

function enable_failure_handler_daemon ()
{
	# skip when FNH service not utilized
	[ "$enable_failure_notification_service" != true ] && return 0

	##
	# Reinstate Service user email address in FNH daemon service file.
	#
	# This adjusts the environmental variables passed through
	# to the Failure Notification Handler program script, when
	# it is called by the triggering of the FNH daemon service.
	##

	# re-enable email alerts
	if [ -n "$email" ] && [ -n "$failure_handler_daemon_service_filename" ]; then # 1/
		sed -i 's%^\s*#\?\s*Environment="email=.*%Environment="email='"$email"'%I' "$failure_handler_daemon_service_filename"
	fi # 1/

	# refresh program log pointer
	if refresh_failure_handler_daemon; then # 1/
		return 0
	else # 1/
		return 1
	fi # 1/
}

###########
# Set Traps
###########

# trap signals and interrupts
trap trap_door_on_signal SIGTERM SIGABRT INT

# trap intentional program exits
trap 'trap_door_on_exit $?' EXIT

##########################################
# Import Global Variable Declarations File
##########################################

##
# These variables need to be treated globally. In order to ensure this is the case,
# they are explicitly declared here. Forcing their declaration here ensures there
# are no mishaps related to the order of operation in which variables are declared,
# since the script may take different paths depending on user preferences defined
# in config file, and automated system discovery processes.
##

# fail gracefully when global variable declartions file cannot be loaded
! validate_file_system_object "$service_launcher_declarations_filename" "file" && exit 1

############################
# Import Initialization File
############################

##
# Load initialization file created by Builder program.
#
# Its content governs vital aspects of the Service program's operation,
# sets certain default variables, and some previously calculated values.
##

# fail gracefully when init file does not exist
[ -z "$init_filename" ] && exit 2

# fail gracefully when init file cannot be loaded
! validate_file_system_object "$init_filename" "file" && exit 3

################################################
# Notify systemd Service Launcher is Starting Up
################################################

##
# This alters the state if someone were to query the related service
# daemon status of the Service Launcher's systemd daemon that
# launches this program.
##

notify_systemd_status "Active: Launcher Service is starting"

##
# Once systemd receives the READY=1 message via systemd notification API,
# it will mark the service daemon related to the Service Launcher as
# "started" and will handle it according to its configuration (i.e.,
# checking dependencies, starting other services that depend on it, etc.)
##

# indicate related service daemon has finished its initialization and is fully operational
command -v systemd-notify &>/dev/null && systemd-notify --ready

#################################
# Load Declaration and Init Files
#################################

# load global variable declarations
! source "$service_launcher_declarations_filename" && exit 4

# load init file parameters
! source "$init_filename" && exit 5

# explicitly force off program debug logging
log_file_active=false

# validate sys logging and debug settings after loading init file
if ! send_to_syslog "imported Service Launcher init file: $init_filename"; then # 1/ system logging not available
	log_to_syslog=false
fi # 1/

#####################################
# Enable Failure Notification Handler
#####################################

# enable Failure Notification Handler (FNH) daemon
enable_failure_handler_daemon

#########################################################################
# Confirm Required File System Objects Are Defined in Init File and Exist
#########################################################################

# determine Service Launcher source code directory
if command -v realpath &>/dev/null; then # 1/
	service_launcher_dir="$(dirname -- "$(realpath "${BASH_SOURCE[0]}")")"
else # 1/
	service_launcher_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
fi # 1/

# parent dir of Service Launcher dir
target_dir="$(dirname "$service_launcher_dir")"

# confirm Service Runtime top level dir exists
! validate_file_system_object "$service_runtime_dir" "directory" && exit 6

# confirm Service include files dir exists
! validate_file_system_object "$service_functions_dir" "directory" && exit 7

# confirm include files library exist dir exists where expected
[ "$(find "${service_functions_dir}" -name '*.sh' -type f | wc -l)" -eq 0 ] && exit 8

# confirm runtime executable exists
! validate_file_system_object "$service_runtime_filename" "file" && exit 9

#################################
# Validate Include File Manifests
#################################

##
# Sanity check the include file manifests for both this program (Service Launcher)
# and the Service Runtime program. This is performed here to validate that this
# program can operate correctly, and to prevent launching the Runtime program if
# any include files it requires are missing.
#
# Locate and import Launcher and Runtime include file manifests (.info files).
#
# Service include files may be used by the Launcher and/or Runtime Service
# programs. The Launcher and Runtime programs have separate file manifests,
# which facilitate validating that each include file required by the Launcher
# or Runtime program respectively is available.
#
# Manifest files are not required, but are preferred as it helps to ensure all
# required include files are present and can be imported, before launching the
# Runtime program that will require these files. However, if either manifest is
# missing or cannot be loaded, the process of launching the RUntiem program will
# not be aborted.
##

notify_systemd_status "Active: processing required files"

#####################################
# Verify File Manifests Can Be Loaded
#####################################

##
# Validate file manifests.
#
# There are different include file manifests for the Launcher vs. Runtime Service programs.
# The two programs share the include files in the Service program functions sub-directory,
# but each program requires a different sub-set of those include files. Their respective
# include file manifests identify which Service function files each requires.
##

[ "$log_to_syslog" = true ] && send_to_syslog "validate Service Launcher include file manifest: $service_launcher_manifest_filename"

##
# Validate Service Launcher include file manifest.
# If validation fails, exit gracefully.
##

! validate_file_system_object "$service_launcher_manifest_filename" "file" && exit 10

##
# Also cross-check include file manifest for the Service Runtime program.
#
# The Service Runtime program does not perform its own manifest check. It is more efficient
# to perform this validation prior to launching the Runtime program, allowing the Runtime
# footprint to remain as small and efficient as possible.
##

[ "$log_to_syslog" = true ] && send_to_syslog "validate Service Runtime include file manifest: $service_runtime_manifest_filename"

##
# Validate Service Runtime include file manifest.
# If validation fails, exit gracefully.
##

! validate_file_system_object "$service_runtime_manifest_filename" "file" && exit 11

###############################
# Import Launcher Include Files
###############################

notify_systemd_status "Active: importing required include files"

# load include files mentioned in Service Launcher manifest
[ "$log_to_syslog" = true ] && send_to_syslog "load Service Launcher include files"

##
# Verify include files appear to be imported successfully.
# Bail when any expected include file cannot be imported.
##

while read -r filename; do # 1/ import each filename from manifest

	{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue

	debug_print 4 "\tload include file... $filename"

	# trap errors
	! source "${service_functions_dir}/${filename}" &>/dev/null && exit 12

done < <(sort -u "$service_launcher_manifest_filename" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames, .sh lines only

##################################
# Validate Runtime Program Version
##################################

# check $service_runtime_filename version versus $service_program_version
if version="$(parse_file_version "$service_runtime_filename")"; then # 1/
	if [ "$version" != "$service_program_version" ]; then # 2/
		bail_noop "Service Runtime program file version does not match Service Launcher: $service_runtime_filename"
	fi # 2/
else # 1/
	bail_noop "Failed to verify Service Runtime program file version matches Service Launcher due to a program error"
fi # 1/

##############################################################
# Cross-Check Runtime Include File Manifest vs. File Inventory
##############################################################

##
# Parse each filename in Runtime manifest.
#
# Confirm presence of all include files required by Runtime program.
##

# abort when any files in the manifest are missing
while read -r filename; do # 1/

	{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue # skip headers and empty lines

	debug_print 4 "\t... %s\n" "$filename"

	! validate_file_system_object "${service_functions_dir}/${filename}" "file" && exit 13

done < <(sort -u "$builder_manifest" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames, .sh lines only

###################################################################################
# Validate Program Log Settings | Create Launcher Program Log | Create Runtime Logs
###################################################################################

##
# The following directories are expected. If any are missing, logging is aborted.
# 1. top-level Service logging (parent) directory
# 2. Service Launcher program log dir
# 3. Service Runtime program log dir
#
# Additionally, a Service Runtime JSON log sub-dir may be expected, however this
# dir can be re-created if missing.
#
# service_log_dir will not have been set by the Builder when no form of Service
# program logging was indicated via user config file at the time Builder was run.
##

##
# Service user needs traverse + read + write rights to every Service log directory
# in order to be able to scan for, locate, create, and remove files in these
# directories. For example, in order to clean-up and remove old log files, the
# Service user must have all of these file system rights.
##

# default to no existing program log for Service Runtime (i.e. use syslog instead)
runtime_log_file_active=false

notify_systemd_status "Active: configuring log files"
debug_print 1 "Configure Service program logging"

##
# Even if program logging is not requested, JSON logging might be.
# Top level service log directory is required for either scenario.
##

####################################
# Start Service Launcher Program Log
####################################

##
# Launcher needs no special logging parameters because it runs just once.
# Service Launcher program logging is either used or not used.
#
# NOTE: Prior to the existence of a log file, debug_print program log entries
# are sent to syslog.
##

if [ -n "$service_log_dir" ]; then # 1/ validate top level parent dir of Service log dirs when any form of logging is desired
	if (( debug_level > 0 )); then # 2/ Service and Runtime program logs requested?
		if set_target_permissions "$service_log_dir" PERM_TRAVERSE; then # 3/
			if [ -z "$service_launcher_log_dir" ]; then # 4/
				service_launcher_log_dir="${service_log_dir}/launcher"
				debug_print 4 "Set default Service Launcher program log directory location to default"
			fi # 4/

			debug_print 3 "Probe Service Launcher program log directory: ${service_launcher_log_dir}/"

			if validate_file_system_object "$service_launcher_log_dir" "directory"; then # 4/
				if set_target_permissions "$service_launcher_log_dir" PERM_WRITE_TRAVERSE; then # 5/
					log_filename="${service_launcher_log_dir}/${service_name}_launcher_"
					[ -n "$service_program_version" ] && log_filename="v${service_program_version}_"

					log_filename+="$(build_date_time_string).log"

					debug_print 3 "Create new Service Launcher program log: $log_filename"

					if ! create_log_file "log_filename"; then # 6/ log file creation failed
						debug_print 2 warn "Service Launcher program log creation failed"
						unset log_filename
						log_file_active=false
					fi # 6/
				fi # 5/
			fi # 4/
		else # 3/ log dir not valid
			debug_print "Service Launcher program log directory inaccessible or does not exist"
			log_file_active=false

			# should be empty by default, but make sure
			unset log_filename
		fi # 3/

		if [ -n "$log_filename" ]; then # 3/
			log_file_active=true

			# refresh Failure Notification Handler program log flag
			refresh_failure_handler_daemon

			# log header
			{
				printf "Service Launcher program log\n"
				printf "version: %s\n\n" "$service_program_version"
				printf "Builder and Service programs are version specific and must match.\n\n"
				printf "This log file: %s" "$log_filename"
				printf "\n----------------------------------------------------------------"
				printf "\n----------------------------- Init -----------------------------"
				printf "\n----------------------------------------------------------------"
			}  >> "$log_filename"

			# force create syslog record
			send_to_syslog "Service Launcher program log file created successfully: $log_filename"

			debug_print 1 "Start Service Launcher program log"

			##
			# Clean-up old Launcher program log files
			##

			# purge old log Files
			debug_print 3 "Purge expired Service Launcher program log files"

			if set_target_permissions "$service_launcher_log_dir" PERM_ALL; then # 4/ need all perms to find and remove old files
				debug_print 4 "Remove expired Service Launcher program log files from Launcher program log directory"
				{ [ -n "$log_age_max" ] && [ "$log_age_max" -gt 0 ]; } && find "$service_launcher_log_dir" -maxdepth 1 -name '*.log' -type f -mtime +$((log_age_max)) -delete
			else # 4/
				debug_print 3 caution "User lacks necessary directory access permissions to remove obsolete Service Launcher program logs from ${service_launcher_log_dir}/"
			fi # 4/

			########################################
			# Append Exit Code Legend to Program Log
			########################################

			##
			# Compile error code legend.
			#
			# Map program exit codes to human-readable explanations,
			# and insert the corresponding legend into the program
			# log.
			##

			print_exit_code_legend

		else # 3/ Service Launcher program log file creation failed
			debug_print 2 warn "Failed to create Service Launcher program log for an unknown reason"
			unset log_filename
			unset service_launcher_log_dir
			log_file_active=false
		fi # 3/ end service launcher program log file creation

		####################################
		# Create Service Runtime Program Log
		####################################

		##
		# Create and prime new Service Runtime program log file
		##

		if [ -z "$service_runtime_log_dir" ]; then # 3/
			service_runtime_log_dir="${service_log_dir}/runtime"
			debug_print 4 "Set Service Runtime program log file directory to default: $service_runtime_log_dir"
		fi # 3/

		debug_print 2 "Probe Service Runtime log directory: ${service_runtime_log_dir}/"

		if [ -n "$service_program_version" ]; then # 3/
			service_runtime_log_filename="${service_runtime_log_dir}/${service_name}_runtime_v${service_program_version}_$(build_date_time_string).log"
		else # 3/ program version unknown or invalid
			service_runtime_log_filename="${service_runtime_log_dir}/${service_name}_runtime_$(build_date_time_string).log"
		fi # 3/

		debug_print 3 "Start new Service Runtime program log: $service_runtime_log_filename"

		if set_target_permissions "$service_runtime_log_dir" PERM_WRITE_TRAVERSE; then # 3/
			if create_log_file "service_runtime_log_filename"; then # 4/ success

				##
				# Pro-actively begin first Runtime log file to allow
				# debug messages to be recorded during Runtime initialization
				# and first run loop to execute, including logging.
				##

				# log header
				{
					printf "Service Runtime program log\n"
					printf "version: %s\n\n" "$service_program_version"
					printf "This log file: %s" "$service_runtime_log_filename"
					printf "\n----------------------------------------------------------------"
					printf "\n--------------- Service Runtime Program Log File ---------------"
					printf "\n----------------------------------------------------------------"
				}  >> "$service_runtime_log_filename"

				# force create syslog record
				send_to_syslog "Service Runtime program log file created successfully: $service_runtime_log_filename"
				debug_print 1 "Created new Service Runtime program log"

				##
				# Clean-up old Service Runtime program log files
				##

				if set_target_permissions "$service_runtime_log_dir" PERM_ALL; then # 5/ purge old Service Runtime log files
					debug_print 4 "Purge expired Service Runtime program log files"
					{ [ -n "$log_age_max" ] && [ "$log_age_max" -gt 0 ]; } && find "$service_runtime_log_dir" -maxdepth 1 -name '*.log' -type f -mtime +$((log_age_max)) -delete
				else # 5/
					debug_print 3 caution "User lacks necessary directory access permissions to remove obsolete Service Runtime program logs from ${service_runtime_log_dir}/"
				fi # 5/
			else # 4/
				debug_print 2 warn "Runtime program log creation failed"
				unset service_runtime_log_filename
				runtime_log_file_active=false
			fi # 4/
		else # 3/ something went wrong with Runtime program log creation
			debug_print 2 warn "User lacks necessary file system permissions to Runtime log file directory"
			unset service_runtime_log_filename
			unset service_runtime_log_dir
			runtime_log_file_active=false
			log_json_export=false
		fi # 3/
	fi # 2/

	##############################################
	# Validate Service JSON Metadata Log Directory
	##############################################

	##
	# Establish JSON log directory and validate JSON logging parameters.
	#
	# JSON logs - when used - record snapshots of various metadata.
	# JSON logs are periodic. They take a snapshot at given intervals.
	#
	# This means they are not constantly collecting and recording data,
	# as are the program logs. JSON logs provide time-based slices of
	# data to record various states of the system at the moment the log
	# was recorded.
	##

	##
	# Normal operating logs and JSON metadata logs are stored in dedicated
	# log directories. JSON metadata logs are stored in a sub-directory of
	# the Runtime log folder, and are created on-the-fly during Service
	# program runtime operations.
	#
	# It is possible to have JSON metadata logging without Service Runtime
	# or Service Launcher program logging.
	##

	if [ "$log_json_export" = true ]; then # 2/
		if [ -n "$service_runtime_log_dir" ]; then # 3/
			service_json_log_dir="${service_runtime_log_dir}/json"

			debug_print 3 "Probe Service Runtime metadata JSON directory: ${service_json_log_dir}/"

			if ! set_target_permissions "$service_json_log_dir" PERM_ALL; then # 4/
				debug_print 2 warn "Current user lacks sufficient permissions to \$service_json_log_dir"
				unset service_json_log_dir
			fi # 4/

			service_json_log_test_filename="${service_json_log_dir}/test_file"

			if ! create_log_file "service_json_log_test_filename"; then # 4/
				debug_print 3 warn "Failed to create JSON test file for an unknown reason"
				unset service_json_log_test_filename
			fi # 4/

			if [ -n "$service_json_log_test_filename" ]; then # 4/
				debug_print 4 "Remove dummy test file: $service_json_log_test_filename"

				if ! run_command rm "$service_json_log_test_filename" || validate_file_system_object "$service_json_log_test_filename" file; then # 5/
					debug_print 4 warn "Failed to remove dummy test file for an unknown reason: $service_json_log_test_filename"
					unset service_json_log_dir
				fi # 5/
			else # 4/
				unset service_json_log_dir
			fi # 4/
		else # 3/
			debug_print 3 warn "Cannot implement JSON metadata logging because Service Runtime log directory is missing or not accessible"
		fi # 3/

		if [ -z "$service_json_log_dir" ]; then # 3/
			log_json_export=false
			debug_print 2 caution "Service Runtime JSON metadata logging is DISABLED"
		fi # 3/
	fi # 2/

	if [ -n "$service_json_log_dir" ]; then # 2/ after successful validatation above, manage dir permissions

		# restrict all users to traverse + read at directory level
		! set_target_permissions "$service_json_log_dir" 555 true && debug_print 2 caution "Failed to restrict access to Service Runtime metadata JSON directory: $service_json_log_dir"

		# then modify dir permissions to allow Service program user ability to write files to the dir
		if ! set_target_permissions "$service_json_log_dir" PERM_ALL true; then # 3/ # service program user needs all rights
			debug_print 3 warn "Failed to allow Service user write rights to JSON metadata program log directory"
			debug_print 2 warn "Service Runtime JSON metadata logging disabled"
			unset service_json_log_dir
		fi # 3/
	fi # 2/
else # 1/
	unset log_filename
	unset service_log_dir
	unset service_runtime_log_filename

	log_file_active=false
	runtime_log_file_active=false
	log_json_export=false

	send_to_syslog "Service Launcher program debug log DISABLED"
	debug_print 2 "JSON logging DISABLED"
fi # 1/

# disable Runtime metadata logging when its log dir does not exist
[ -z "$service_runtime_log_dir" ] && log_json_export=false

{ [ "$log_file_active" != true ] && [ "$runtime_log_file_active" != "true" ]; } && debug_level=0

###########################################################

# initialize controller

###########################################################

notify_systemd_status "Active: initializing controller"

################################
# Validate External Dependencies
################################

##
# The hardware analysis portion of the Builder cannot proceed
# when dependent programs are unavailable.
##

if ! command -v "$ipmitool" &>/dev/null; then # 1/ may be command shortcut or file pathname
	send_to_syslog "program aborted due to missing IPMI tool dependency: $ipmitool"
	bail_noop "ipmitool (IPMI) is not available, but is required. Aborting program."
fi # 1/

##
# Ensure Postfix program exists if email alerts are requested.
##

if [ "$email_alerts" = true ]; then # 1/
	if ! command -v postfix &>/dev/null || ! command -v sendmail &>/dev/null; then # 2/ disable email alerts when neither postfix nor sendmail are installed
		send_to_syslog "disabled email alerts because {postfix} program not installed"
		debug_print 2 "Email alerts disabled because {postfix} program not installed"
		email_alerts=false # disable email alerts
		unset email # destination email address
	else # 2/ postfix is installed
		if [ -z "$email" ]; then # 3/
			debug_print 1 warn "Disabled email alerts: destination (\"To:\") email address not specified"
			email_alerts=false
		fi # 3/
	fi # 2/
else # 1/
	debug_print 3 "Email alerts not requested"
fi # 1/

##
# Validate disk temperature reading tool is present.
#
# Default is smartctl. If not present, hddtemp will be chosen next.
# If neither exists, device temps will be unknown and device fans
# will not be acknowledged.
##

if [ "$device_temp_reader" = "smartctl" ] || [ -z "$device_temp_reader" ]; then # 1/ prefer S.M.A.R.T. disk utility
	if command -v smartctl &>/dev/null; then # 2/
		[ -z "$device_temp_reader" ] && device_temp_reader="smartctl" # known to work with SSD and NVMe
	else # 2/
		debug_print 2 warn "smartctl disk temperature reader not available"
		debug_print 2 "Attempt to utilize 'hddtemp'"
		device_temp_reader="hddtemp" # try alternative tool
	fi # 2/
fi # 1/

if [ "$device_temp_reader" = "hddtemp" ]; then # 1/ works with SSDs as well
	if ! command -v hddtemp &>/dev/null; then # 2/
		debug_print 4 warn "hddtemp disk temperature reader not available"
		unset device_temp_reader # disable Device temp reading capabilities
	fi # 2/
fi # 1/

##
# Note: when no device temperature reader is available, all fans will automatically
# be diverted to focus cooling on the CPU(s) only.
##

[ -z "$device_temp_reader" ] && debug_print 1 critical "Disk temperature monitoring program not specified or not available"

#####################################
# Confirm Required Fan Trackers Exist
#####################################

# confirm all expected fan duty category binary trackers exist
notify_systemd_status "Active: confirm presence of required fan trackers"

[ ${#fan_duty_category[@]} -eq 0 ] && bail_noop "Fan duty cooling types not defined in Builder config"

for key in "${fan_duty_category[@]}"; do # 1/ process each fan cooling type (e.g., cpu, device)
	! declare -p "${key}_fan_header_binary" &>/dev/null && bail_noop "Missing fan header binary for fan duty cooling category: '${key}' (\${key}_fan_header_binary)"

	# fan header binary must not be empty
	[ -z "${key}_fan_header_binary" ]; } && bail_noop "Fan duty cooling type fan header binary not defined: '${key}' (\${key}_fan_header_binary)"

	# if an active fan header binary exists, it should not be empty
	{ declare -p "${key}_fan_header_active_binary" &>/dev/null ] && [ -z "${key}_fan_header_active_binary" ]; } && bail_noop "Active fan header binary missing or undefined for fan duty cooling category: '${key}' (\${key}_fan_header_active_binary)"

	if [ "$fan_control_method" = "zone" ]; then # 1/
		{ declare -p "${key}_fan_zone_binary" &>/dev/null ] && [ -z "${key}_fan_zone_binary" ]; } && bail_noop "Fan zone binary missing or undefined for fan duty cooling category: '${key}' (\${key}_fan_zone_binary)"
		{ declare -p "${key}_fan_zone_active_binary" &>/dev/null ] && [ -z "${key}_fan_zone_active_binary" ]; } && bail_noop "Active fan zone binary missing or undefined for fan duty cooling category: '${key}' (\${key}_fan_zone_active_binary)"
	fi # 1/
done # 1/

########################
# Inventory Disk Devices
########################

notify_systemd_status "Active: inventory data storage devices"

debug_print 1 "----------------------------------------------------------------"
debug_print 1 "---------------- Inventory Data Storage Devices ----------------"
debug_print 1 "----------------------------------------------------------------"

##
# Seed previous average disk temp before main loop starts.
#
# NOTE: Device list compiled by Builder program ( $device_list )is imported
# into the Launcher as $device_list_old (previous device list). This allows
# the Launcher to compare the expected list of current disk devices with the
# device list created when the Builder was run.
##

poll_device_list

# warn when current device list does not match original list of disk devices
{ [ -n "$device_list_old" ] && [ "$device_list" != "$device_list_old" ]; } && debug_print 2 caution "Current list of disk devices does not match original list compiled by Builder"

################################
# Inventory Existing Fan Headers
################################

##
# This process creates a master list of all fan headers
# detected via IPMI. It identifies and assigns a unique
# ID number to each fan header name.
#
# This list of fan header IDs is authoritative, meaning
# it will act as the de-facto schema of fan numbering
# to fan name table from here-on, including usage by the
# Service program.
##

notify_systemd_status "Active: inventory fan headers"

##
# 1. Check for discrepancies between expected vs. detected fan headers.
# 2. Probe fan headers for activity and compare to expected active fan headers.
##

debug_print 1 "Validate expected fan activity during start-up and initialization"

# identify each physically present fan header and determine its current state
debug_print 2 "Perform start-up physical fan header validation"

#####################################################
# Initial Fan Inventory Validation and Activity Sweep
#####################################################

##
# Collect all fan metadata for all fans for the first time,
# regardless of state. Verbose mode forces updating non-active
# fan headers and increases log verbosity.
##

<<>>

--> confirm we have fan headers and groups/zones
	--> we need to validate what builder told us would exist
	--> this is NOT looking for active fans (yet), only existing

--> we need a similar process to calibrate_fan_zones, but not the same as builder needs
	--> needs/differences:
		--> 1. go thru each fan header
		--> 2. confirm it is tagged in fan_header_binary
		--> 3. check its category 
	fan_category="${fan_header_category[$fan_id]}" # prefix of fan group/zone binary to manipulate
		--> 4. confirm it is tagged in corresponding fan header binary {fan_category}_fan_header_binary
		--> 5. check which fan group/zone it belongs to
	zone_id="${fan_header_zone[$fan_id]}"
		--> 6. confirm its fan zone is tagged in fan_zone_binary and {fan_category}_fan_zone_binary
		--> 7. confirm it is tagged in corresponding fan zone binary

--> sanity check on expected fan headers and fan groups/zones
	--> needs to be a separate sub from builder, but likely based on builder needs
	--> launcher only
	--> use imported binaries as a benchmark
		--> if anything reported by them to exist or its status (active or not) is amiss, report it
		--> if a fan is expected inactive but is active, thats ok
		--> if a fan is expected to be active, but is not, flag as suspicious and hand it off to runtime

# force status and speed update of all fan headers
get_fan_info all verbose true

# validate observed fans vs. indicated fans (via .init file created by Builder)
validate_fan_inventory

##
# Validate cpu fans exist (at least one).
# Re-assign fans if necessary so that we have at least one cpu cooling.
##

validate_cpu_fan_headers

##		
# Ensure at least one active fan is dedicated to CPU cooling duty.
# Reassign all fans to CPU cooling duty when this is not the case.
#
# Only takes action when there are no fans allocated for CPU cooling duty.
# Does NOT check whether fans are active.
##

# calibrate all fan zones with fans physically present (without regard to their status)
calibrate_fan_zones

# ensure excluded fans are not associated with any fan zone
cleanup_excluded_fans

# validate which fan headers are active
calibrate_active_fan_headers

# final confirmation at least one cpu fan is active
enforce_cpu_cooling_priority

# calibrate all fan zones with active fan headers (active fan zones)
calibrate_active_fan_zones

----------------------------------------------

<<>>

--> 6. email overall passing state to user before we launch runtime

<<>>

----------------------------------------------

# compare current BMC fan speed thresholds to those set by the Builder (expected values)
validate_current_bmc_fan_thresholds

# verify which fan headers and zones are active
initialize_active_fan_headers

###########################
# Enable Manual Fan Control
###########################

##
# Ensure manual fan control is established.
#
# Some motherboards do not require any special commands
# to implement this condition, in which case no actions
# are performed.
##

enable_manual_fan_control

####################
##
## Begin Fan Control
##
####################

notify_systemd_status "Active: configuring fan controls"

debug_print 1 "Service Launcher created by $program_name Builder version $service_program_version"
debug_print 1 "Builder filename: $service_program_version"
debug_print 1 "---------------------------------------------------------------------------------------"
debug_print 1 "Start $program_name Service Launcher"

check_time="$(current_time)" # current epoch time in seconds

##
# Set starting speed of CPU fans
##

cpu_fan_duty=$((cpu_fan_duty_start))

set_fan_duty_cycle "cpu" $((cpu_fan_duty_start)) true

convert_fan_duty_to_fan_level "cpu_fan_level" "cpu" # human-readable fan level low/medium/high

debug_print 2 "Starting CPU fan zone duty level: $cpu_fan_level"
debug_print 2 "Starting CPU fan zone duty cycle: ${cpu_fan_duty}%"

##
# Set starting speed of Device fans (when present)
##

# when an independent disk device fan zone exists, set its starting fan speed
if [ "$fan_control_method" = "zone" ] && ! binary_is_empty "$device_fan_zone_active_binary"; then # 1/ independent disk cooling fan zone(s) exist
	device_fan_duty=$((device_fan_duty_start))

	set_fan_duty_cycle "device" $((device_fan_duty_start)) true

	convert_fan_duty_to_fan_level "device_fan_level" "device" # low/medium/high/maximum

	debug_print 2 "Starting Disk Device (case) fan zone duty level: $device_fan_level"
	debug_print 2 "Starting Disk Device (case) fan zone duty cycle: ${device_fan_duty}%"
fi # 1/

# seed starting PID factored fan duty cycles
device_fan_duty_pid="$device_fan_duty"
device_fan_duty_pid_last="$device_fan_duty_pid"

sleep $((fan_speed_delay)) # wait a bit for fans to adjust

# refresh active fan header speeds after their duty cycles were updated
get_fan_info all quiet false

###############################################
## Calculate Service Runtime Logging Parameters
###############################################

##
# Calculate Runtime program log start times as close to current real time
# as possible, in order to time the log start times as close as possible
# the Service Runtime initialization.
#
# When program log starts are to be aligned with the hour
# ($log_hourly_alignment = true), then calculate the epoch time (in seconds)
# of the top of the next hour conforming to the sequence of hourly intervals.
#
# This calculation takes advantage of the fact BaSH does not natively
# handle floating point numbers or fractions, and rounds down division
# results based on it dropping the remainder when processing simple
# algabraic equations. In this case, the process results in a figure
# calculated by first determining the current hour, and then determining
# the next iteration of hours from Epoch based on the provided hourly
# log interval ($log_hourly_interval).
#
# This result may then be calcuated by 3,600 (number of seconds in one
# hour) to derive the equivalent Epoch time stamp in the future that
# represents the next hourly timestamp target, which is then applied
# as $next_log_time, which becomes the actual timer/trigger to begin
# the next Runtime program log. Future logs are then timed based solely on
# the hourly interval now that the pattern has been established.
##

# configure next program log offset calculation based on timing preference
if [ "$log_hourly_alignment" = true ]; then # 1/ align periodic program log to top of next interval hour

	# align Runtime program log start interval with next epoch hour interval
	next_log_hour=$(( ((( check_time / 3600 ) + log_hourly_interval - 1 ) / log_hourly_interval ) * log_hourly_interval ))

	# convert hour number into seconds (hour target * 3600 seconds per hour)
	next_log_time=$(( next_log_hour * 3600 )) # next date/timestamp when a Runtime program log will be created

	debug_print 4 "Service Runtime program logs will be aligned with local time hour: $(date +%H -d "$next_log_hour")"
else # 1/ calculate next log time based on simple offset from current time

	##
	# When there is no requirement to align the start of program log files
	# with the beginning of the hour, then start the next log at the requested
	# number of hours interval from the current time.
	#
	# In other words, new program log start times are offset from the timestamp
	# when this program was started, and not based on a top of the hour interval.
	##

	# cause Service Runtime program to generate program log file immediately
	next_log_time=$(( check_time ))
	debug_print 4 "Service Runtime program logs will be aligned with start of Service Runtime program"
fi # 1/

##
# JSON metadata log files
#
# JSON metadata log files are also periodic, but for the
# most part are governed by a different set of parameters.
#
# Hourly time alignment is an exception in the sense it is
# governed by the same variable ($log_hourly_alignment) as
# are program log files.
#
# Just as with program log files, when hourly alignment = true,
# the starting time of the first JSON metadata log file is
# aligned with the next top-of-the-hour interval.
##

# start JSON logging at the same time as the next program log is created
[ "$log_json_export" = true ] && json_next_log_time="$next_log_time"

debug_print 4 "Program logs will be staggered every $log_hourly_interval hour(s)"
[ "$log_hourly_alignment" = true ] && debug_print 4 "Service Runtime program log start time aligned to hourly interval"
debug_print 4 "Approximate next program log file start time: $(date -d @$next_log_time)" # convert next epoch log time to human-readable date/timestamp

notify_systemd_status "Active: configuring Service Runtime program parameters"

####################
# Runtime Wait Timer
####################

##
# Set Runtime wait timer
#
# The 'wait timer' is an intentional delay added to the Runtime script
# which pauses the Runtime process between its infinite loop cycles
# utilizing the built-in 'sleep' command.
#
# The purpose of the Wait Timer is to ensure each timer has an opportunity to be
# executed during its desired interval, provided no other timer supercedes it.
#
# To accomplish this, the wait timer should be set as follows:
#
# 1. The smallest common divisor of all timer values, for all related timers,
# when the SCD is greater than 1.
# 2. When the SCD is = 1, then use the smallest of all compared timer values.
#
# The wait timer prevents the Service Runtime program from making redundant
# and redundant calculations while waiting for a gating timer to expire.
# The sleep command is utilized because it allows the operating system to
# free up server resources temporarily when the delay between functions of
# the Runtime script are broad enough.
#
# If $wait_timer is not set, the Runtime service will not pause between
# loop cycles. This will caused increased CPU utilization and potentially
# increased CPU and/or device polling, but will be more responsive.
#
# The following timers are compared to find the smallest of their common
# divisors:
#	--> fan_speed_delay
#	--> suspicious_fan_validation_delay
#	--> cpu_temp_polling_interval
#	--> device_temp_polling_interval
#	--> all_fan_validation_delay
#
# If the shortest wait timer common denominator is less than 3 seconds,
# it is disabled automatically.
##

# calculate smallest common divisor
wait_timer=$(scd "$fan_speed_delay" "$suspicious_fan_validation_delay" "$cpu_temp_polling_interval" "$device_temp_polling_interval" "$all_fan_validation_delay")

# disable Runtime wait timer when shortest timer < 2 seconds
(( wait_timer < 2 )) && wait_timer=2

##########################
# Create Runtime Init File
##########################

[ -z "$service_runtime_init_filename" ] && bail_with_fans_optimal "Undefined Service Runtime initialization filename (\$service_runtime_init_filename)"

# attempt to force write permission for current user to allow init file deletion
if set_target_permissions "$service_runtime_dir" PERM_ALL; then # 1/
	if set_target_permissions "$service_runtime_init_filename" PERM_WRITE_ONLY; then # 2/
		rm -f "$service_runtime_init_filename" &>> "$log_filename" # delete pre-existing runtime init file
	else # 2/
		debug_print 3 warn "Current user lacks file system permissions to remove pre-existing Service Runtime initialization file"
	fi # 2/
else # 1/
	debug_print 3 warn "Current user lacks sufficient permissions to parent directory of pre-existing Service Runtime initialization file"
fi # 1/

# bail when failed again (pre-existing file is still there)
validate_file_system_object "$service_runtime_init_filename" "file" && bail_with_fans_optimal "Failed to remove pre-existing Service Runtime initialization file"

# create new init file
! create_init_file "$service_runtime_init_filename" && bail_noop "Failed to create new Service Runtime .init file"

# update runtime init file after creation
update_runtime_init_file

# update systemd status
notify_systemd_status "Active: finishing up"

# force close Launcher program log summary
print_log_summary

##
# Inform user via email the script has started, but keep the message brief
#
# message format: core message | true (be verbose) | true = yes (summarize current system status)
##

send_email_alert "$(build_date_time_string): Starting $daemon_runtime_service_name runtime daemon service (main loop)" true

##
# Dis-associate log file pointer from FNH daemon on exit.
#
# This keeps the FNH daemon active, but prevents it from pointing
# to the Launcher log file after the Launcher has finished. Thus,
# if the Runtime program fails before it initializes its log file,
# then the FNH process will still trigger, but without a log file
# reference. Either way, the user will be informed when a program
# failure occurs.
##

log_file_active=false
refresh_failure_handler_daemon
exit 0
