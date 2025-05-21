#!/bin/bash
# shellcheck source=/dev/null
# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
# shellcheck disable=SC2034
# shellcheck disable=SC2154

# Universal Fan Controller (UFC)
# Builder program version 2.0

# Builder and Service programs are version specific and must match.

# DO NOT REMOVE LINE BELOW
# program_version="2.0"

##
# Program Overview
#
# This program is the Universal Fan Controller "Builder"
#

# It has the name "Builder" because it builds or constructs various components required for the actual
# Service program modeules to run. The Service program is the actual Universal Fan Controller workhorse and
# consists of the Launcher and Runtime modules. The Launcher sets up the runtime environment, and the
# Runtime script is an infinite loop that is the actual fan controller workhorse.
#
# The Service program is the actual Universal Fan Controller workhorse. The Builder is an orchestrator.
#
# It has the name "Builder" because it builds or constructs various components required for the actual
# Service program to run. The Service program is the actual Universal Fan Controller workhorse. The Builder
# is an orchestrator. It does not perform any fan operations, other than those required to establish
# suitable parameters for the Service runtime program. These include parsing configuration files,
# and validating variables, files, and services required to support the Service program. This includes
# migrating the Service program source file to its specified runtime location and version checking.
##

#################################################

# this program is a CPU and chassis fan control script
# written in BaSH for Ubuntu 16/18/20/22/24
# test environment: SuperMicro X9DRi-F | Supermicro 835 3U chassis | dual Xeon E5-2680 v2 | 2x Noctua NH-D9DX i4 3U cpu fans | 5x stock case fans

########################
# What This Program Does
########################
# 1. When CPU temperatures rises, adjusts the speed of CPU fans.
# 2. When disk temperatures rise, adjusts the speed of case fans.
# 3. Pro-actively monitors for signs of unresponsive fans, and when this occurs cold restart the BMC, and try again to control the fan speed.
# 4. If shared cpu/disk cooling is specified, and cpu temperature is high, then use the case fans to provide additional cooling.

#################
# Version History
#################
#
# The following changes by David Guyton
#
# 2024-09-11 New version 2.0 with independent Builder vs. Service programs
#
# 2024-01-28 New version 2.0 with independent Builder vs. Service programs
#		   New builder program completed. Beginning refactor of Service program.
#
# 2022-10-21 New enhanced version with significant new functionality
# 		1. Refactored to support Supermicro X9 motherboards
# 		2. Refactored to support Ubuntu 16/18/20/22
# 		3. Refactored variable names to make their purpose clearer
# 		4. Prevent a fan-lock condition when the program thinks CPU temperature cannot be read correctly and forces all fans to maximum all of the time.
# 		5. Remove program dependencies that do not provide the proper information in Ubuntu, such as sysctl.
# 		6. Check for program dependencies and fail gracefully when missing.
# 		7. Automate hard drive device identification.
# 		8. Intelligently excludes non-peripheral devices from temperature data collection.
# 		9. Improved support for disk device changes (hot-swapped, failed/removed, added disk devices).
# 		10. Added support for multi-CPU motherboards (up to 4 physical sockets). Though rare, some motherboards allow up to 4 CPUs. Dual CPU boards are relatively common.
# 		11. Prevent program crash when no hard drives exist.
# 		12. Removed obsolete or redundant code
# 		13. Automatic fan speed detection: automatically determine cpu and hd fan speed min/max limits.
# 		14. Automatic fan header detection.
# 		15. Automated fan zone identification.
#		16. Added support for configuration settings defined in separate config file.
#		17. Stubbed for future support of other motherboard manufacturers and models.
#		18. Rapid-start initialization option that stores static information about the server between reboots.
#		19. Most program functions now handled by functions. This makes it easier to follow order-of-operations, make modifications, and perform troubleshooting.
#
#################
#
# The following changes by unknown user
# 2017-01-29 Add header to log file every X hours
# 2017-01-21 Refactored code to bump up CPU fan to help cool HD.  Drop the variabe CPU duty cycle, and just set to High,
#            Added log file option without temps for every HD.
# 2017-01-18 Added log file
#
# The following changes by Kevin Horton
# 2017-01-14 Reworked get_device_list() to exclude SSDs
#            Added function to calculate maximum and average HD temperatures.
#            Replaced original HD fan control scheme with a PID controller, controlling the average HD temp..
#            Added safety override if any HD reaches a specified max temperature.  If so, the PID loop is overridden,
#            and HD fans are set to maximum speed
#            Retain float value of fan duty cycle between loop cycles, so that small duty cycle corrections
#            accumulate and eventually push the duty cycle to the next integer value.
# 2016-10-07 Replaced get_cpu_temp() function with new process which queries the kernel, instead of IPMI.
#            This is faster, more accurate and more compatible, hopefully allowing this to work on X9
#            systems. The original function is still present and is now called get_cpu_temp_ipmi().
#            Because this is a much faster method of reading the temps, and because its actually the max core
#            temp, I found that the previous cpu_temp_override of 60 was too sensitive and caused the override
#            too often. I've bumped it up to 62, which on my system seems good. This means that if a core gets to
#            62C the HD fans will kick in, and this will generally bring temps back down to around 60C... depending
#            on the actual load. Your results will vary, and for best results you should tune controller with
#            mprime testing at various thread levels. Updated the cpu threasholds to 35/45/55 because of the improved
#            responsiveness of the get_cpu_temp function
# 2016-09-26 device_list is now refreshed before checking HD temps so that we start/stop monitoring devices that
#            have been hot inserted/removed.
#            "Drives are warm, going to 75%" log message was missing an 'unless' clause, causing it to print every time
# 2016-09-19 Added cpu_temp_override, to prevent HD fans cycling when CPU fans are sufficient for cooling CPU
# 2016-09-19 Initial Version

###############################
# Required Baseline Global Vars
###############################

declare builder_manifest						# Builder include file manifest
declare builder_program_basename				# builder program basename
declare builder_program_version				# version number of this (Builder) program
declare builder_source_dir					# builder source code and executable directory
declare builder_declarations_filename			# temporary variable to track global variable declartion filenames
declare file_error							# error flag when inventorying include file manifests
declare filename							# temporary variable for filenames
declare functions_common_source_dir			# shared (common) include files dir
declare log_temp_filename					# temporary program log filename
declare program_name						# human-readable name for this program
declare source_file							# temporary pointer for loading include files
declare source_parent_dir					# source code parent directory

declare -a exit_code

exit_code[1]="no global variable declarations file"
exit_code[2]="program configuration directory not found"
exit_code[3]="required daemon service directory is invalid, inaccessible, or does not exist"
exit_code[4]="top-level Service program source directory not found"
exit_code[5]="Service Launcher program source directory not found"
exit_code[6]="Service Runtime program source directory not found"
exit_code[7]="top-level include files directory not found"
exit_code[8]="include files directory does not exist: ${functions_builder_source_dir}/"
exit_code[9]="failed to locate common (shared) include files directory: ${functions_common_source_dir}/"
exit_code[10]="failed to locate Service programs include files directory: ${functions_service_source_dir}/"
exit_code[11]="no include file manifest"
exit_code[12]="include file manifest is empty"
exit_code[13]="failed to validate Builder include file manifest"
exit_code[14]="one or more Builder include files failed to load correctly ('source' command issue)"
exit_code[15]="this program must be run as 'root' user"
exit_code[255]="exit on SIG trap"

###########################################################

# pre-loaded subroutines

###########################################################

##
# Report current date/time in human-readable date/24-hour format.
#
# When an input argument is specified, report the date/time of
# the specified epoch time (in seconds), converted to human-
# readable format.
##

function build_date_time_string ()
{
	local result

	result="$(date "+%Y-%m-%d %T")" # date/time of current epoch time
	printf "%s" "$result"
}

# print call chain from point of failure back to main script
function trace_debug() {

	local datetimestring="$1"
	local pop
	local stack_size="${#FUNCNAME[@]}"

	datetimestring="$1"
	stack_size="${#FUNCNAME[@]}"

	printf "\n===== Debug Trace Start =====\n"

	if (( stack_size == 1 )); then # 1/ trace_debug was called directly from the main script (global context)
		printf "%sLast executed line in main script: %s\n" "${datetimestring:+$datetimestring }" "N/A"
	else # 1/

		##
		# Loop from pop=1 (the immediate caller of trace_debug) to the bottom of the call stack.
		# For pop from 1 to (stack_size - 2), print the function call info.
		# The last element (pop == stack_size - 1) represents the call site in the main script.
		##

		for (( pop = 1; pop < stack_size; pop++ )); do # 1/
			if (( pop < stack_size - 1 )); then # 2/
				printf "%sfunction '%s' called by '%s' at line %s\n" "${datetimestring:+$datetimestring }" "${FUNCNAME[pop]}" "${FUNCNAME[pop+1]}" "${BASH_LINENO[pop]}"
			else # 2/ the bottom frame: print the last executed line in the main script.
				printf "%sLast executed line in main script: %s\n" "${datetimestring:+$datetimestring }" "${BASH_LINENO[pop-1]}"
			fi # 2/
		done # 1/
	fi # 1/

	printf "===== Debug Trace End =====\n\n"
}

##
# debug_print ()
#
# Print something to the (human-readable) server log, provided
# the log message meets or exceeds the designated runtime debug
# level setting.
#
# Possible input combinations:
#
# input: {level} {message}
# input: {level} {message} {trace}
# input: {level} {message} {trace} {terminal-display}
#
# input: {level} {alert} {message}
# input: {level} {alert} {message} {trace}
# input: {level} {alert} {message} {terminal-display}
# input: {level} {alert} {message} {trace} {terminal-display}
##

function debug_print ()
{
	local -l alert				# alert type
	local datetimestring		# current time/date
	local -l display_terminal	# also print to display terminal when true
	local level				# debug level
	local message				# message payload
	local -l trace

	level="$1" # first input must always be debug level associated with the debug message ($2)
	level="$(printf "%.0f" "${level//[!0-9]/}")" # numeric only, defaults to 0 (zero)

	(( level == 0 )) && return 1 # invalid debug level

	# filter var parsing based on number of arguments
	case $# in # 1/

		1) 
			return 1 # too few arguments
			;;

		2)
			# expected input: {level} {message}
			message="$2"
			;;

		3|4|5)
			case "$2" in # 2/
				bold|caution|critical|success|warn|warning)
					# input: {level} {alert} {message}
					# input: {level} {alert} {message} {trace}
					# input: {level} {alert} {message} {terminal-display}
					# input: {level} {alert} {message} {trace} {terminal-display}

					alert="$2"
					message="$3"
					trace="$4"
					display_terminal="$5"
					;;

				*)
					# input: {level} {message} {trace}
					# input: {level} {message} {trace} {terminal-display}

					message="$2"
					trace="$3"
					display_terminal="$4"
					;;
			esac # 2/
			;;
		*)
			# too many arguments
			return 1
			;;
	esac # 1/

	# default trace flag to false when not defined
	trace="${trace:-false}"

	# debug level less than level threshold and debug trace flag not set
	{ (( debug_level < level )) && [ "$trace" != true ]; } && return 0

	[ -z "$message" ] && return 1 # empty message content

	# compile date/time string when practical
	datetimestring="$(build_date_time_string)"

	message=$(
		# alert prefix
		case "$alert" in # 1/
			bold) printf "\e[7m" ;;
			caution) printf "\e[36m%s: " "${alert^^}" ;;
			critical) printf "\e[41m%s: " "${alert^^}" ;;
			success) printf "\e[32m%s: " "${alert^^}" ;;
			warn|warning) printf "\e[30;43mWARNING: " ;;
		esac # 1/

#			caution|critical|success)
#				printf "%s: " "${alert^^}"
#				;;

#			warn|warning)
#				printf "WARNING: "
#				;;
#		esac # 1/

		# body of debug message
		printf "%s\e[0m" "$message"
	)

	# default display-to-terminal flag to false (do not print to terminal)
	display_terminal="${display_terminal:-false}"

	##
	# When the 'display to terminal' flag is set TRUE, the debug message is also output to the
	# terminal screen. This is independent of program file and temporary program log variable
	# logging text, as the terminal output supports ANSI text coloring, while any given viewer
	# of the program log may or may not support this (and thus why this text formatting is
	# excluded from the raw file output version of log messages).
	##

	if [ "$display_terminal" = true ]; then # 1/
		terminal_message=$(
			# prefix
			case "$alert" in # 1/
				bold) printf "\e[7m" ;;
				caution) printf "\e[36m" ;;
				critical) printf "\e[41m" ;;
				success) printf "\e[32m" ;;
				warn|warning) printf "\e[30;43m" ;;
			esac # 1/

			# body
			printf "%s" "$message"

			# terminate color coding
			[ -n "$alert" ] && printf "\e[0m"

			##
			# Append debug trace to end of terminal display text.
			# Note the debug trace is not colorized.
			##

			[ "$trace" = true ] && printf "\n%s" "$(trace_debug "$datetimestring")" # append debug trace info
		)

		# print to display terminal
		printf "%s\n" "$terminal_message" >&2
		[ "$trace" = true ] && printf "\n" >&2 # pad an extra line to visually segment trace info
	fi # 1/

	# append debug trace info to log message destined for file storage
	[ "$trace" = true ] && message+="$(printf "%s\n" "$(trace_debug "$datetimestring")")"

	if [ "$log_file_active" = true ]; then # 1/ append debug message to log file
		if [ -n "$log_filename" ]; then # 2/
			printf "%s %s\n" "$datetimestring" "$message" &>> "$log_filename"
		else # 2/
			if [ -n "$log_temp_filename" ]; then # 3/
				printf "%s %s\n" "$datetimestring" "$message" &>> "$log_temp_filename"
			else # 3/
				printf "%s\n" "$message"
			fi # 3/
		fi # 2/
	fi # 1/
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
# These subroutines must be embedded in the Builder main program because their
# functionality is required during the process of validating functions that need
# to be imported as include files. This is true due to the nature of the Builder
# program architecture and purpose.
##

##########
# Set Trap
##########

# trap unplanned program interruptions
function trap_door ()
{
	local message
	local response

	printf "\nUnexpected exit on SIGnal trap\n\n"

	response="$1"
	response="$(printf "%.0f" "${response//[!0-9]/}")" # numeric only; defaults to 0

	# embed error code and human-readable error message if exists
	if (( response > 0 )); then # 1/
		message="exit code $response"
		[ -n "${exit_code[$response]}" ] && message+=" : ${exit_code[$response]}"
	else # 1/
		message+="unknown"
	fi # 1/

	# call exit sub when loaded
	if command -v bail_noop &>/dev/null; then # 1/
		bail_noop "$message"
	else # 1/
		[ -n "$log_temp_filename" ] && printf "%s\n\n" "$message" >> "$log_temp_filename"
	fi # 1/

	exit 255
}

# trap unexpected program exits
trap 'trap_door $?' SIGTERM SIGABRT INT

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
# The function fails when above criteria are not met or object is not the correct
# object type (when specified) or object type is neither a file nor a directory.
##

##
# Important notes on file and directory permissions in Linux
#
# The current user must have read, write, and execute rights
# set on the parent directory in order to modify or delete a
# file.
#
# The current user must have write rights for the diectory in
# which the target file shall reside, in order to create a new
# file in the target directory.
#
# Without read rights to the directory where the target file
# resides, the user will not be able to confirm the file was
# created. And without directory traverse and write rights,
# the user will not be able to delete the file.
#
# The permission rights of the current user at the file level
# have no bearing on the user's ability to delete an existing
# file in the directory. Only the directory level permissions
# govern a user's ability to remove files in the directory.
##

function validate_file_system_object ()
{
	local actual_object_type
	local expected_object_type
	local file_system_object

	if [ -z "$1" ]; then # 1/
		debug_print 4 "Undefined file system object variable name '\$1'"
		return 1 # fail if no object provided
	fi # 1/

	##
	# Object name must be direct, full file system path.
	##

	file_system_object="$1"

	##
	# Note expected object type (file or directory) when specified.
	# When not specified, whichever is auto-detected will be presumed
	# to be the correct/expected type.
	##

	[ -n "$2" ] &&	expected_object_type="$2"

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
				debug_print 3 warn "Named file system object is not a file or directory (incompatible object type)" true
				return 1 # do not continue
			fi # 3/
		fi # 2/
	else # 1/ file system object does not exist
		return 1 # do not continue
	fi # 1/

	##
	# Compare actual object type to expected object type, when relevant
	##

	if [ -n "$expected_object_type" ] && [ "$actual_object_type" != "$expected_object_type" ]; then # 1/
		debug_print 3 warn "Named file system object is not specified type '${expected_object_type}', but is type '${actual_object_type}'" true
		return 1
	fi # 1/

	##
	# Actual and expected object types match
	##

	# further scrutinize files for readability by current user
	if [ "$actual_object_type" = "file" ]; then # 1/
		if [ ! -r "$file_system_object" ]; then # 2/ confirm ability of current user to read file
			debug_print 3 warn "File exists, but cannot be read: $file_system_object"
			return 1 # fail
		fi # 2/
	fi # 1/

	return 0
}

##
# Within a specified directory, identify newest filename matching current program version.
##

function match_file_version ()
{
	local directory			# directory to scan
	local filename				# filename with matching filename text string, file extension, and embedded program version
	local file_ext				# filename extension
	local target_string			# text string to scan for in filename
	local target_version		# desired program version
	local version				# actual program version

	local -a source_file_list	# array of service program file candidates

	directory="$1"				# directory to scan
	target_string="$2"			# text that must be in filename, such as 'launcher' (case insensitive)
	target_version="$3"			# version string trying to match
	file_ext="$4"				# file extension (default = .sh)

	[ -z "$file_ext" ] && file_ext="sh" # default file extension

	# current user lacks permissions to read and traverse target dir
	command -v set_target_permissions &>/dev/null && ! set_target_permissions "$directory" PERM_READ_TRAVERSE && return 1

	# gather list of filenames in target dir matching target name string, sorted by date/time (newest files first)
	readarray -d '' -t source_file_list < <(find "$directory" -maxdepth 1 -iname '*'"$target_string"'*' -name '*.'"$file_ext" -type f -printf "%T@\t%p\0" | sort -z -r -k1,1 | cut -z -f2-)

	[ "${#source_file_list[@]}" -eq 0 ] && return 1 # failure status

	# compare each file to target version, starting with newest files
	for filename in "${source_file_list[@]}"; do # 1/ find the first commented string match and parse it
		version="$(grep -i -m 1 '^# program_version=' "$filename")"
		version="${version#*\"}" # parse quoted version string
		version="${version%\"}"
		version="${version//[!.0-9]/}" # numbers and decimal points only
		[ "$version" = "$target_version" ] && break # break on first match
	done # 1/

	[ "$version" != "$target_version" ] && return 1 # no matching file found

	printf "%s" "$filename" # return best match filename
	return 0
}

###########################################################

# pre-init

###########################################################

##
# Core name of both Builder and Service programs as they will appear in logs.
#
# This is a temporary value until the Bulider config file is read, at which
# point, it may be overwritten.
##

program_name="Universal Fan Controller (UFC)" # may be modified by .init file
printf "\nRunning %s: Builder\n\n" "$program_name"

##################################
# Define Static Source Directories
##################################

##
# Several presumptions are made regarding file naming conventions:
#
# source filenames use the same basename pattern:
#	{program_name}_{program_type}_v{version number}.{file extension}
#
# The Builder (this program) is responsible for copying the Service program file, and
# daemon service file to the their destination directories.
#
# The Builder consumes the configuration ("config") file information, which consists
# of Builder program runtime parameters and user-declared preferences. The Builder
# creates the initialization (".init") file for the Service Launcher as output in the
# appropriate destination directory.
#
# Source and destination filenames have different basename syntax. Source files use
# filename syntax intended to identify each file's purpose, type, and version.
#
# Destination filename syntax identifies each file's purpose, and the name of the service
# daemon they are associated with. Destination files exclude versioning information.
##

# this program's basename
builder_program_basename="$(basename "$0")"

# builder source code directory (2nd tier)
builder_source_dir="${PWD}"

source_parent_dir="$(dirname "$builder_source_dir")"

[ -z "$source_parent_dir" ] && debug_print 1 caution "Top-level source files directory is root"
[ "$source_parent_dir" = "$builder_source_dir" ] && debug_print 1 caution "Top-level source files directory and Builder files directory are the same"

##################################
# Identify Builder Program Version
##################################

##
# Determine Builder program version from source code (parse itself).
##

# parse running Builder program file, find first commented string match
builder_program_version="$(grep -i -m 1 '# program_version=' "${builder_source_dir}/${builder_program_basename}")"

# parse quoted version string to get version number
builder_program_version="${builder_program_version#*\"}"
builder_program_version="${builder_program_version%\"}"
builder_program_version="${builder_program_version//[!.0-9]/}" # numbers and decimal points only

# builder_program_version not specified or indeterminate
if [ -z "$builder_program_version" ]; then # 1/
	debug_print 1 caution "Could not determine program version of this (Builder) program" false true
	debug_print 1 caution "Missing version info is ok, but creates risk of builder/service program file mis-matches" false true
fi # 1/

#######################
# Evaluate Current User
#######################

##
# IPMI requires root user access
# Other programs may potentially also require root access
# (e.g. lm-sensors, postfix), depending on operating system
# configuration and permissions.
#
# Feel free to remove this check if your system is configured to allow
# non-root users to run these programs.
##

if [ "$USER" = "root" ]; then # 1/ user is de-facto root user or running program in sudo interactive mode
	debug_print 1 "\e[32mCurrent user is root\e[0m\n" false true
	builder_username="root"
else # 1/
	if [ -n "$SUDO_USER" ]; then # 2/ user is elevated to 'root' status temporarily via sudo
		debug_print 1 "Current user not root, but elevated to root via sudo: $SUDO_USER" false true
		builder_username="root"
	else # 2/ user is not root and not elevated to root user status
		debug_print 1 critical "Current user '$USER' is not elevated to root privileges" false true
		debug_print 1 critical "This program must be run as 'root' user (such as via sudo elevation)" false true
		exit 15
	fi # 2/
fi # 1/

################################
# Begin Builder Program Log File
################################

debug_print 1 "Begin debug log reporting\n" false true

# create a temporary log file in current user home directory
log_temp_filename="$HOME/ufc_tmp_debug_log_$$.log"

if touch "$log_temp_filename"; then # 1/
	log_file_active=true
	debug_level=4 # set temporary default to force verbose logging

	# log header
	{
		printf "\n%s program log\n" "$program_name"
		printf "Builder program version: %s" "$builder_program_version"
		printf "\n----------------------------------------------------------------"
		printf "\n----------------------------- Init -----------------------------"
		printf "\n----------------------------------------------------------------\n"
	} &>> "$log_temp_filename"

	debug_print 1 "Created temporary log file: $log_temp_filename" false true
else # 1/
	printf "\e[33mTemporary log file creation failed\e[0m\n"
	unset log_temp_filename
	log_file_active=false
fi # 1/

##########################################
# Import Global Variable Declarations File
##########################################

##
# Locate and import Builder global variable declarations file matching this
# Builder program version. When more than one file matches the same version
# number, load the most recently created file (based on date/timestamp).
#
# Match files based on file contents. Declarations file must match this
# Builder program version.
##

debug_print 1 "Identify Builder variable declarations file"

# must match builder version or abort (though ok if both are null)
if ! builder_declarations_filename="$(match_file_version "$builder_source_dir" declaration "$builder_program_version")"; then # 1/
	debug_print 1 critical "Could not locate global variable declarations file matching this Builder version $builder_program_version"
	exit 1
fi # 1/

debug_print 1 "Import Builder-specific global variable declarations file: $builder_declarations_filename" false true

# load global variable declarations file
source "$builder_declarations_filename"

###############################
# Set Source Directory Pointers
###############################

# 3rd tier Builder support dirs
config_source_dir="${source_parent_dir}/config" # /source_parent_dir/config/
daemon_source_dir="${source_parent_dir}/daemon" # /source_parent_dir/daemon/

# 2nd tier
functions_source_dir="${source_parent_dir}/functions" # include files /source_parent_dir/functions/
service_source_dir="${source_parent_dir}/service" # Service programs /source_parent_dir/service/

# 3rd tier service program dirs
service_launcher_source_dir="${service_source_dir}/launcher" # service launcher program files /source_parent_dir/service/launcher/
service_runtime_source_dir="${service_source_dir}/runtime" # service runtime program files /source_parent_dir/service/runtime/

# 3rd tier include file dirs
functions_builder_source_dir="${functions_source_dir}/builder" # /source_parent_dir/functions/builder/
functions_common_source_dir="${functions_source_dir}/common" # /source_parent_dir/functions/common/
functions_service_source_dir="${functions_source_dir}/service" # /source_parent_dir/functions/service/

###############################
# Validate Required Directories
###############################

##
# Verify the following directories are:
# 1. existing
# 2. accessible to current user
# 3. confirmed to be a directory
##

# verify required configuration directories
! validate_file_system_object "$config_source_dir" directory && exit 2
! validate_file_system_object "$daemon_source_dir" directory && exit 3

# source files parent directory
! validate_file_system_object "$service_source_dir" directory && exit 4

# Service Launcher source files directory
! validate_file_system_object "$service_launcher_source_dir" directory && exit 5

# Service Runtime source files directory
! validate_file_system_object "$service_runtime_source_dir" directory && exit 6

# include files parent directory
! validate_file_system_object "$functions_source_dir" directory && exit 7

# include files directory required by Builder program
! validate_file_system_object "$functions_builder_source_dir" directory && exit 8

# common (shared) include files directory
! validate_file_system_object "$functions_common_source_dir" directory && exit 9

# include files directory required by both Service programs
! validate_file_system_object "$functions_service_source_dir" directory && exit 10

########################################
# Validate Builder Include File Manifest
########################################

##
# Locate and import Builder include file manifest (.info file) matching this
# version of Builder program. Choose most recent file when there is more than
# one match.
##

debug_print 1 "Identify and validate Builder include file manifest" false true

if ! builder_manifest="$(match_file_version "$config_source_dir" builder "$builder_program_version" info)"; then # 1/
	debug_print 1 critical "Failed to locate Builder include file manifest expected in ${config_source_dir}/"
	debug_print 1 critical "Missing include file manifest for Builder" false true
	exit 11
fi # 1/

debug_print 1 "Builder include file manifest: $builder_manifest"
debug_print 1 "Examine inventory of Builder include files prior to importation"

##################################################################
# Cross-Check Builder Include File Manifest vs. Filename Inventory
##################################################################

# count number of include filenames in manifest file, ignoring duplicates
if [ "$(sort -u "$builder_manifest" | grep -c '\.sh$')" -eq 0 ]; then # 1/
	debug_print 1 "Include file manifest is devoid of any include filenames to scan for" false true
	exit 12
fi # 1/

###########################################
# Validate and Import Builder Include Files
###########################################

##
# Parse all include filenames in Builder manifest.
# Ignore duplicate filenames.
#
# For each filename, verify it exists in one of the following locations:
# --> 1. Builder include files directory
# --> 2. Shared (common) include files directory
##

##
# NOTE: At this point, the include files which provide the vast majority of error
# checking and validation have not yet been loaded. Thus, only embedded functions
# can be called at this time, making file and directory permissions and existence
# validations more limited than they are after the include files are loaded. Thus,
# error messages at this stage are somewhat less verbose than preferred, until
# after these steps are complete.
##

debug_print 1 "Scan for presence of filenames mentioned in Builder manifest"

debug_print 3 "Builder include file directory (preferred): ${functions_builder_source_dir}/"
debug_print 3 "Builder include file directory (secondary): ${functions_common_source_dir}/"

debug_print 2 "Verify files in Builder manifest exist:"

##
# Parse each filename in manifest and import it.
#
# 1. Verify file exists and is accessible before importation.
# 2. Prioritize Builder-specific sub-directory first, then Commmon (shared) sub-directory.
# 3. When a matching filename is present in Builder-specific directory, but cannot be loaded,
# 	do not attempt to load the same filename from common directory. Flag it as an error.
##

while read -r filename; do # 1/
	{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue # skip headers and empty lines

	##
	# 1st priority is Builder-specific sub-dir. When file is not found there
	# or cannot be read, try 2nd tier priority, which is Common (shared) sub-dir.
	##

	# 1st priority location is Builder-specific sub-directory
	source_file="${functions_builder_source_dir}/${filename}"

	if validate_file_system_object "$source_file" file; then # 1/
		[ "$log_file_active" = true ] && debug_print 2 "loading... $source_file" >> "$log_temp_filename"

		if ! source "$source_file" &>/dev/null; then # 2/ import file, flag errors
			debug_print 1 critical "FILE FAILED TO LOAD: $source_file" false true
			file_error=true
		fi # 2/
	else # 1/ 2nd priority is common (shared) include files sub-dir
		source_file="${functions_common_source_dir}/${filename}"

		if validate_file_system_object "$source_file" file; then # 2/
			debug_print 2 "loading... $source_file"

			if ! source "$source_file" &>/dev/null; then # 3/
				debug_print 1 critical "FILE FAILED TO LOAD: $source_file" false true
				file_error=true
			fi # 3/
		else # 2/
			debug_print 1 critical "FILE NOT FOUND: $filename"
			file_error=true
		fi # 2/
	fi # 1/
done < <(sort -u "$builder_manifest" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames, .sh lines only

# abort when any files in the manifest are missing
if [ -n "$file_error" ]; then # 1/
	debug_print 1 critical "Failed to validate Builder manifest" false true
	exit 13
fi # 1/

debug_print 1 success "Builder manifest validated successfully" false true

##
# Confirm all functions loaded as expected.
#
# The function names in each include file correspond to the filename.
# For example, include file "my_function.sh" contains the function
# "my_function"
#
# Thus, the manifest file can be parsed again to confirm each function
# has been loaded into memory, before continuing.
##

unset file_error
debug_print 1 "Verify include files loaded correctly..." false true

while read -r filename; do # 1/
	{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue # skip headers and empty lines
	debug_print 2 "validating function '${filename%.*}'"

	# drop file extension to get function name
	if ! command -v "${filename%.*}" &>/dev/null; then # 1/
		debug_print 1 warn "NOT LOADED: ${filename%.*}"
		file_error=true
		break
	fi # 1/
done < <(sort -u "$builder_manifest" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames, .sh lines only

# bail when one or more include files failed to load correctly
if [ "$file_error" = true ]; then # 1/
	debug_print 1 critical "Failed to load one or more required include files"
	exit 14
fi # 1/

debug_print "1" "success" "All include files imported successfully" "false" "true"

####################################
# Validate Critical Hardware Details
####################################

debug_print 1 "Determine manufacturer and motherboard details" false true

# auto-detect motherboard manufacturer and line/model
validate_mobo_model # scan hardware

#########################################################
# Import Manufacturer/Motherboard Specific Configurations
#########################################################

##
# Check if custom .conf files exist for motherboard model and/or manufacturer.
#
# Program version is not checked for manufacturer/model config files. They are
# presumed to be valid if they exist.
#
# These files are loaded prior to the custom Builder configuration file. This
# behavior allows for the opportunity for the Builder config file to override
# any manufacturerer or model-specific settings, while preserving such specific
# settings that may be important for any given motherboard. Either way,
# definitive control over config settings always rests with the user-defined
# Builder configuration file.
##

if [ -n "$mobo_manufacturer" ]; then # 1/
	debug_print 3 "Check for presence of sub-directories containing motherboard and/or model configuration files"

	# check for presence of manufacturer-specific config directory
	manufacturer_config_dir="${config_source_dir}/${mobo_manufacturer}"

	if validate_file_system_object "$manufacturer_config_dir" directory; then # 2/ motherboard manufacturer-specific config directory exists
		if query_target_permissions "$manufacturer_config_dir" PERM_READ_TRAVERSE; then # 3/ dir traverse + read rights

			##
			# Check for presence of manufacturer-specific config file.
			# It is expected to follow a specific file naming convention.
			##

			manufacturer_config_file="${manufacturer_config_dir}/${mobo_manufacturer}.conf"

			debug_print 3 "Check for presence of motherboard $mobo_manufacturer config file: $manufacturer_config_file"

			if validate_file_system_object "$manufacturer_config_file" file; then # 4/ manufacturer-specific config file exists
				if query_target_permissions "$manufacturer_config_file" PERM_READ_ONLY; then # 5/ file read rights
					debug_print 4 "Import motherboard config file" false true

					if source "$manufacturer_config_file" &>/dev/null; then # 6/ file imported successfully
						debug_print 4 "Successfully imported motherboard-specific config file"
					else # 6/
						debug_print 2 warn "Failed to load motherboard-specific config file for an unknown reason"
					fi # 6/
				else # 5/
					debug_print 2 warn "User lacks sufficient file permissions to access motherboard-specific config file"
					unset manufacturer_config_file
				fi # 5/
			else # 4/
				debug_print 3 "Manufacturer-specifc config file not found (OK)"
			fi # 4/

			##
			# Check for presence of model-specific config file.
			# It is expected to follow a specific file naming convention.
			##

			model_config_file="${manufacturer_config_dir}/${mobo_model}.conf"
			debug_print 3 "Check for presence of motherboard model $mobo_model config file: $model_config_file"

			if validate_file_system_object "$model_config_file" file; then # 4/ model-specific config file exists
				if query_target_permissions "$model_config_file" PERM_READ_ONLY; then # 5/ file read rights
					debug_print 4 "Import motherboard model $mobo_model config file" false true

					if source "$model_config_file" &>/dev/null; then # 6/ file imported successfully
						debug_print 4 "Successfully imported motherboard model-specific config file"
					else # 6/
						debug_print 2 warn "Failed to load motherboard model-specific config file for an unknown reason"
					fi # 6/
				else # 5/
					debug_print 2 warn "User lacks sufficient file permissions to access motherboard model-specific config file"
					unset model_config_file
				fi # 5/
			else # 4/
				debug_print 3 "Motherboard model-specifc config file not found (OK)"
			fi # 4/
		else # 3/
			debug_print 3 "Motherboard manufacturer-specific sub-directory exists, but current user lacks sufficient rights to access it"
			unset manufacturer_config_dir
		fi # 3/
	else # 2/
		debug_print 2 caution "Manufacturer-specific configuration sub-directory not found"
		unset manufacturer_config_dir
	fi # 2/
else # 1/
	debug_print 3 "Skipping manufacturer-specific config file imports because motherboard manufacturer is unknown"
fi # 1/

###########################################
# Import Builder Program Configuration File
###########################################

##
# Configuration file must exist, and its filename syntax must conform
# to the same basename as this Builder program.
#
# Config files do not contain embedded version numbers. Their filename
# must align with the Builder program's filename. If the Builder program
# filename includes a version number, so must the config filename.
#
# To determine expected filename for configuration, Service program,
# and daemon service template files, the same directory and basename as
# the builder file (this program) are presumed.
##

debug_print 4 "Parse config filename based on Builder program filename path"

##
# Check for the existence of user-defined configuration file.
#
# The config file must exist, as its content governs various aspects
# of the program's operation. For example, it sets certain default
# variables and may override some calculated or inferred values.
#
# "program version" must be embedded at top of file, and version
# must match the Builder version.
#
# Only the first, most recent matching filename is retained.
#
# Filename syntax: {service name}_builder_{version}.conf
#
# Examples of acceptable filenames:
#	universal-fan-controller_builder.conf
#	universal-fan-controller_builder_v2.0.conf
#	universal-fan-controller_builder_v2.0_config.conf
##

##
# Identify most recent config file version matched to Builder based on
# config file content or filename.
##

debug_print 2 "Scan directory for Builder configuration file: $config_source_dir"

# exit when config file not found or invalid
! config_file="$(find_best_file_version_match "$config_source_dir" "" "$builder_program_version" "conf" 1)" && bail_noop "No version matched configuration (.conf) file found"

# load configuration file
debug_print 3 "Load Builder program configuration file: $config_file" false true

# load it and bail on failure to import
! source "$config_file" &>/dev/null && bail_noop "Failed to import config file '${config_file}' for an unknown reason"

debug_print 3 "Configuration file imported successfully: $config_file"

# parse service name tag
debug_print 4 "Parse fan controller Service Name: $service_name"
service_name="${service_name//[!A-Za-z0-9_-[]]//}" # strip illegal characters
service_name="${service_name//[ ]/-}" # substitute dashes for spaces

##
# Attempt to utilize alternate Service naming convention when parsing user-provided
# name is invalid.
##

if [ -z "$service_name" ]; then # 1/
	debug_print 3 caution "User specified fan controller 'Service Name' undefined or invalid"

	if [ -n "$program_name" ]; then # 2/
		debug_print 4 "Attempt to substitute Program Name as alternative Service Name"
		debug_print 4 "Parse fan controller program name: $program_name"

		service_name="${program_name//[!A-Za-z0-9_-[]]//}" # strip illegal characters
		service_name="${service_name//[ ]/-}" # substitute dashes for spaces
	fi # 2/
fi # 1/

# required variable declarations
[ -z "$program_name" ] && bail_noop "Required configuration file variable declaration is missing: program name (\"\$program_name\")"
[ -z "$service_name" ] && bail_noop "Failed to determine a valid Service Name: invalid or missing from .config file"

#################
# syslogger Check
#################

# check syslogger availability
if [ "$log_to_syslog" = true ]; then # 1/ use explicitly requested
	if ! command -v logger &>/dev/null; then # 2/ command exists
		log_to_syslog=false # force off
		debug_print 2 warn "syslog reporting not available"
	fi # 2/
else # 1/
	log_to_syslog=false
fi # 1/

# note in program log either way
if [ "$log_to_syslog" = true ]; then # 1/
	debug_print 1 "syslog updates enabled" false true
else # 1/
	debug_print 1 "syslog updates disabled" false true
fi # 1/

#######################
# Identify Service User
#######################

##
# When the username expected to be running the Service programs is not
# specified in the config file, examine how this Builder program is
# being run, and interpolate projected Service program username when
# the available evidence supports a likely candidate.
##

debug_print 2 "Identify Service program user"

if [ -z "$service_username" ]; then # 1/ set default to current user
	debug_print 1 caution "Service program operational username not specified and will be inferred as Builder user" false true
	debug_print 1 "Inferred Service program operational username is user '$builder_username'" false true
	service_username="$builder_username"
else # 1/ username to run Service programs specified in config file
	debug_print 1 caution "Service programs are expected to be operated by username: $service_username" false true
fi # 1/

debug_print 4 "Update .config file if this behavior is not as expected"

################################
# Begin Builder Program Log File
################################

##
# Switch to permanent log file
#
# Builder program log files are always created in a sub-directory
# of the directory the Builder program is run from.
#
# 1. Create builder program log file in program file directory.
# 2. Use version number in filename if there is one.
##

debug_print 2 "Setup permanent Builder program log, when required"

# parse debug level from config file
debug_level="$(printf "%.0f" "${debug_level//[!0-9]/}")" # numeric only; defaults to 0

if [ "$debug_level" -gt 0 ]; then # 1/
	if [ -n "$builder_program_version" ]; then # 2/ compile builder program log filename
		log_filename="${source_parent_dir}/log/${service_name%*_builder*}_builder_v${builder_program_version}.log"
	else # 2/ program version unknown or invalid
		log_filename="${source_parent_dir}/log/${service_name%*_builder*}_builder.log"
	fi # 2/

	##
	# Create more permanent Builder program log file.
	#
	# Rather than simply renaming the existing, temporary file, a new file is created.
	# Afterwards, the contents of the temporary file are copied into the new log file.
	# The reason for this method is it safeguards the existing, initial log file info.
	# If anything goes wrong during the permanent log file creation process, the temp
	# log file will still exist, aiding in potential troubleshooting.
	##

	if create_log_file "log_filename"; then # 2/ log file created
		log_file_active=true

		##
		# At this point, we have either a validated Builder program log filename
		# or an invalid log filename, or a decision to not have a program log.
		#
		# When no program logging will occur, dump log cache to display before
		# continuing.
		#
		# When program logging is green-lighted, take the stored pre-logging
		# content and dump it into the log file. Also preface the beginning of
		# the log file with related metadata.
		#
		# The temporary log file is only removed after the permanent log file
		# is created and validated.
		##

		if [ -n "$log_temp_filename" ]; then # 3/
			cat "$log_temp_filename" >> "$log_filename" # append temporary log to permanent log file

			debug_print 1 success "Full program log file created"

			if validate_file_system_object "$log_filename" file; then # 4/ confirm all is well
 				debug_print 1 "Temporary log file contents copied to full program log file: $log_filename"
				debug_print 1 caution "Delete temporary log file: $log_temp_filename"

				# remove temporary log file
				rm -f "$log_temp_filename"

				if validate_file_system_object "$log_temp_filename" file; then # 5/
					debug_print 1 warn "Something went wrong with removal of temporary log file"
					debug_print 4 warn "No further attempt will be made to remmove temporary log file: $log_temp_filename"
				fi # 5/

				unset log_temp_filename # no longer needed after export
			fi # 4/
		fi # 3/
	else # 2/ permanent log file creation failed
		debug_print 1 warn "Failed to create proper Builder program log file: $log_filename" false true

		if [ -n "$log_temp_filename" ]; then # 3/
			debug_print 2 "Temporary log file will be retained: $log_temp_filename"
			unset log_filename
		fi # 3/

		debug_print 3 caution "Disable program logging and reset debug level to 0 (no further logging)"
		debug_level=0
	fi # 2/
else # 1/ stop logging when user does not desire formal program logging, but do not delete temp log file
	debug_print 1 warn "Failed to create full debug program log for an unknown reason"
	unset log_temp_filename # no longer needed after export into log file
	log_file_active=false
fi # 1/

printf "\nPlease wait while hardware is analyzed...\n"

#############################
# Validate BMC Command Schema
#############################

# ensure the BMC command schema makes sense before continuing
validate_bmc_command_schema

############################
# Confirm BMC Command Schema
############################

##
# BMC (Baseboard Management Controller) data model must be known.
#
# This value determines the format of various IPMI commands,
# which are in turn based on the BMC chip embedded on the server
# motherboard. If this value is unknown, specific raw IPMI commands
# are not possible, as the IPMI raw syntax varies by BMC chip and
# specific implementations of various parameters which are determined
# by motherboard manufacturers. These command parameter also
# sometimes vary by motherboard generation, group, or model.
#
# Subroutines calling raw IPMI commands cannot be utilized unless this
# value is defined and matches a supported schema.
##

if [ -n "$bmc_command_schema" ]; then # 1/
	debug_print 2 "BMC schema version: $bmc_command_schema"
else # 1/ board not supported
	debug_print 2 warn "Detected motherboard ($mobo_manufacturer) and/or model ($mobo_model) not supported" false true
	bail_noop "Motherboard could not be identified or does not support independent fan control" false
fi # 1/

#################################
# Trap Non-Supported Motherboards
#################################

[ -z "$mobo_manufacturer" ] && bail_noop "Motherboard manufacturer '$mobo_manufacturer' NOT supported at this time"

#######################################
# Global BMC Command Schema Adjustments
#######################################

##
# Load post-processing file, if any.
#
# Post-processing files are manufacturer specific, model agnostic,
# broad-based limitations that need to be applied after all config
# files have been loaded, because the post-processing features need
# to wait to be amended after the normal configuration process.
#
# Post-processing files are .sh (BaSH program) files.
#
# These parameters do not typically line up neatly based on
# manufacturer or model.
##

debug_print 2 "Scan for post-processing configuration files"

if [ -n "$manufacturer_config_dir" ]; then # 1/
	if validate_file_system_object "$manufacturer_config_dir" directory; then # 2/
		config_post_process="${manufacturer_config_dir}/${mobo_manufacturer}.sh"

		if validate_file_system_object "$config_post_process" file; then # 3/
			debug_print 3 "Import $mobo_manufacturer post-processing file: $config_post_process"
			source "$config_post_process"
		else # 3/
			debug_print 3 "No post-processing required"
		fi # 3/
	fi # 2/
fi # 1/

################################
# Validate External Dependencies
################################

##
# The hardware analysis portion of the Builder cannot proceed
# when dependent programs are unavailable.
##

# verify IPMI management tool exists
[ -z "$ipmitool" ] && ipmitool="ipmitool" # default IPMI tool to ipmitool

if ! command -v "$ipmitool" &>/dev/null; then # 1/ may be command shortcut or file pathname
	command -v system_logger &>/dev/null && system_logger "program aborted due to missing IPMI tool dependency: $ipmitool"
	bail_noop "ipmitool (IPMI) required, but not available" false
fi # 1/

##
# Ensure Postfix program exists if email alerts are requested.
##

if [ "$email_alerts" = true ]; then # 1/
	if [ -n "$email" ]; then # 2/
		if ! validate_email; then # 3/
			debug_print "Provided e-mail address is invalid: $email"
			unset email
			email_alerts=false
		fi # 3/
	else # 2/
		debug_print 1 warn "Disabled email alerts: destination (\"To:\") email address not specified"
		email_alerts=false
	fi # 2/
else # 1/
	if [ -n "$email" ]; then # 2/
		debug_print 1 warn "Email address specified, but email alerts configuration setting is disabled"
		debug_print 2 warn "Email alerts are disabled"
	fi # 2/
fi # 1/

if [ "$email_alerts" = true ]; then # 1/
	if ! command -v postfix &>/dev/null && ! command -v sendmail &>/dev/null; then # 2/ verify both postfix and its sendmail variant are installed
		command -v system_logger &>/dev/null && system_logger "disabled email alerts because {postfix} program not installed"
		debug_print 2 "Email alerts disabled because {postfix} program not installed"
		email_alerts=false # disable email alerts
		unset email # destination email address
	fi # 2/
else # 1/
	debug_print 3 "Email alerts not requested"
	email_alerts=false
fi # 1/

##
# Validate disk temperature reading tool
#
# Default is smartctl. If not present, hddtemp will be chosen next.
# If neither exists, device fans will not be acknowledged.
##

if command -v smartctl &>/dev/null; then # 1/ prefer S.M.A.R.T. disk utility
	device_temp_reader="smartctl" # known to work with SSD and NVMe
else # 1/
	if command -v hddtemp &>/dev/null; then # 2/ works with SSDs as well
		device_temp_reader="hddtemp"
	else # 2/ no compatible drive temperature reader is available
		unset device_temp_reader
		debug_print 1 critical "Disk temperature monitoring program not found" false true
	fi # 2/
fi # 1/

###################################################
# Sanity Check Variables after Configuration Import
###################################################

debug_print 3 "Validate various Service program operating parameters"

##
# Default maximum number of fan headers/fan zones when not specified in config or zone file
##

fan_header_binary_length="$(printf "%.0f" "${fan_header_binary_length//[!0-9]/}")"
[ "$fan_header_binary_length" -lt 1 ] && fan_header_binary_length=16

fan_zone_binary_length="$(printf "%.0f" "${fan_zone_binary_length//[!0-9]/}")"
[ "$fan_zone_binary_length" -lt 1 ] && fan_zone_binary_length=8

##
# Assert number of physical CPUs
##

numcpu="$(lscpu | grep -i 'socket(s)' | awk '{print $(2)}')" # query number of physical cpus from operating system
numcpu="${numcpu//[!0-9]/}"

# check for garbage in lscpu data
if [ "$numcpu" -eq 0 ]; then # 1/ numcpu extracted from operating system is invalid
	debug_print 1 warn "Number of CPUs could not be inferred correctly from operating system. Defaulting to 1 physical CPU"
	numcpu=1 # default to 1 cpu if something went wrong with detection
else # 1/
	debug_print 2 "Detected $numcpu CPU(s)"
fi # 1/

# ensure average CPU temp look-back array has a reasonable number of data points
cpu_temp_rolling_average_limit=$(( numcpu * 4 ))

##
# Set default device polling interval (in seconds)
##

# interval between device inventory polls by Service Runtime program
device_polling_interval="$(printf "%.0f" "${device_polling_interval//[!0-9]/}")"

# when not null or zero in config file (do not monitor), set frequency no faster than every 5 minutes
if [ "$device_polling_interval" -lt 1 ]; then # 1/
	unset device_polling_interval
else # 1/
	[ "$device_polling_interval" -lt 300 ] && device_polling_interval=300
fi # 1/

############
# Fan Timers
############

# validate built-in delay between various fan related validation checks
fan_speed_delay="$(printf "%.0f" "${fan_speed_delay//[!0-9]/}")" # numeric only

if [ "$fan_speed_delay" -lt 15 ]; then # 1/
	fan_speed_delay=15
	debug_print 4 caution "Fan speed delay timer set too low and was changed to $fan_speed_delay seconds"
fi # 1/

# validate delay (in seconds) between multiple sysctl (systemd) commands
daemon_init_delay="$(printf "%.0f" "${daemon_init_delay//[!0-9]/}")"

if [ "$daemon_init_delay" -lt 2 ]; then # 1/ minimum/default delay 2 seconds
	daemon_init_delay=2
	debug_print 4 caution "Daemon initialization delay timer set too low and was changed to $daemon_init_delay seconds"
fi # 1/

#################################
# Normalize Fan Validation Timers
#################################

##
# There are three (3) independent fan validation timers.
# Each is associated with a different type of fan validation
# process.
#
# These timers control the frequency of the following checks:
# 1. CPU fan speed integrity
# 2. Disk device fan speed integrity
# 3. All fan header speed and status integrity
#
# Of these, the CPU fans are validated most frequently, since
# CPU cooling is the highest priority. In this test, the CPU
# fan speeds are compared versus their expected speeds. The
# disk device fans are secondary priority in terms of validating
# their actual physical speed against their expected speed.
# And finally, the tertiary priority is of examining the current
# state of all fan headers relative to their expected state.
#
# The timers below manage the frequency of when these tests are
# conducted by the Service Runtime program.
#
# CPU only fan tests are the most frequent. Disk device fans are
# next most in frequency, and validating all fan headers for status
# occurs based on a 3rd frequency.
#
# The following rules are applied when computing the final values
# of these timing offsets:
#
# 1. Base fan polling delay is defined by user in config file, in seconds.
# 2. CPU fan polling frequency = base timer.
# 3. Disk device fan polling frequency must be >= 2x CPU frequency.
# 4. All fan header polling frequency = product of CPU x disk device frequency.
# 5. Suspicious fan check frequency = 3x disk device frequency.
# 6. CPU and disk device timers are rounded to nearest prime number equal to
# or greater than their default value.
#
# These rules ensure there are no overlapping requests for different tests
# during the same time interval during the Service Runtime main program loop.
##

# cpu fan validation delay, in seconds
cpu_fan_validation_delay="$(printf "%.0f" "${fan_validation_delay//[!0-9]/}")"
[ "$cpu_fan_validation_delay" -lt 2 ] && cpu_fan_validation_delay=2 # minimum delay = 2 seconds

# disk device fan validation timer must be >= 2x cpu timer
device_fan_validation_delay=$(( cpu_fan_validation_delay * 2 ))

# must be prime number
cpu_fan_validation_delay=$(find_next_prime $cpu_fan_validation_delay)
device_fan_validation_delay=$(find_next_prime $device_fan_validation_delay)

# ensure device fan delay > cpu fan delay
(( device_fan_validation_delay <= cpu_fan_validation_delay )) && device_fan_validation_delay=$(find_next_prime $((cpu_fan_validation_delay + 1)))

# calculate universal (all fan) state sweep timer
all_fan_validation_delay=$(( cpu_fan_validation_delay * device_fan_validation_delay ))

# calculate suspicious fan validation timer as 3x device fan timer, then round up to next highest prime number
suspicious_fan_validation_delay=$(( device_fan_validation_delay * 3 ))
suspicious_fan_validation_delay=$(find_next_prime $suspicious_fan_validation_delay)

##########################
# Temperature Check Timers
##########################

# delay in seconds between CPU temperature readings; set default when not defined in config file
cpu_temp_polling_interval="$(printf "%.0f" "${cpu_temp_polling_interval//[!0-9]/}")"
[ "$cpu_temp_polling_interval" -eq 0 ] && cpu_temp_polling_interval=2

# device temperature polling interval, in seconds; set default when not defined in config file
device_temp_polling_interval="$(printf "%.0f" "${device_temp_polling_interval//[!0-9]/}")"
[ "$device_temp_polling_interval" -eq 0 ] && device_temp_polling_interval=30

# adjust the timers when cpu timer is longer
if [ "$device_temp_polling_interval" -lt "$cpu_temp_polling_interval" ]; then # 1/
	cpu_temp_polling_interval=$(find_next_prime $device_temp_polling_interval)
	device_temp_polling_interval=$(find_next_prime $(( cpu_temp_polling_interval + 1 )))
fi # 1/

##
# Automatic CPU fan speed control
#
# Some motherboards allow automatic fan speed control for
# specific fans or groups of fans. When this is possible,
# it may be desirable to allow the BIOS or fan controller
# to set CPU cooling fan speeds automatically.
#
# If cpu_fan_control is not true, it is presumed CPU fans
# will be controlled automatically by the server.
#
# Default setting is to presume CPU fans should be controlled
# by this fan controller program.
##

[ -z "$cpu_fan_control" ] && cpu_fan_control=true # set default when empty
[ "$cpu_fan_control" != true ] && cpu_fan_control=false # normalize non-true nomenclature

############################
# CPU Temperature Thresholds
############################

# override temperature at which point device cooling fans are re-purposed to help cool CPU(s); default = 0 (disable)
cpu_temp_override="$(printf "%.0f" "${cpu_temp_override//[!0-9]/}")"

# temperature ranges mapped to duty cycles
cpu_temp_low="$(printf "%.0f" "${cpu_temp_low//[!0-9]/}")"
cpu_temp_med="$(printf "%.0f" "${cpu_temp_med//[!0-9]/}")"
cpu_temp_high="$(printf "%.0f" "${cpu_temp_high//[!0-9]/}")"

####################################
# Disk Device Temperature Thresholds
####################################

##
# Max allowed device temp must be higher than target device temp.
# If they are too close together, sudden triggering of BMC panic mode may occur.
#
# These values may be specified in the config file and/or .conf files.
##

# target disk device average temperature
device_avg_temp_target="$(printf "%.0f" "${device_avg_temp_target//[!0-9]/}")"

if [ "$device_avg_temp_target" -gt 0 ]; then # 1/
	debug_print 3 "Target disk temperature specified in configuration: $device_avg_temp_target degrees Celsius"
else # 1/
	debug_print 2 warn "Target disk temperature not specified in configuration"
fi # 1/

# target disk device maximum temperature threshold
device_max_allowed_temp="$(printf "%.0f" "${device_max_allowed_temp//[!0-9]/}")"

if [ "$device_max_allowed_temp" -gt 0 ]; then # 1/ max disk temp triggers panic mode
	debug_print 3 "Critical disk temp threshold specified in configuration: $device_max_allowed_temp degrees Celsius"

	if [ "$device_avg_temp_target" -gt "$device_max_allowed_temp" ]; then # 2/
		debug_print 1 warn "Maximum allowed disk temp (device_max_allowed_temp) must be higher than average disk temp target (device_avg_temp_target)"
		debug_print 2 caution "Increasing device_max_allowed_temp +10 degrees above average disk temp target ($device_avg_temp_target)"
		device_max_allowed_temp=$(( device_avg_temp_target + 10 )) # +10 is arbitrary
	fi # 2/
else # 1/
	debug_print 2 warn "Maximum disk temperature threshold not specified in configuration"
fi # 1/

# disk device temperature check delay, in seconds
device_temp_polling_interval="$(printf "%.0f" "${device_temp_polling_interval//[!0-9]/}")"

if [ "$device_temp_polling_interval" -eq 0 ]; then # 1/
	debug_print 3 caution "Disk device temperature check delay not specified in configuration"
	device_temp_polling_interval=60 # default
	debug_print 4 "Default value will be used: $device_temp_polling_interval"
else # 1/
	if [ "$device_temp_polling_interval" -lt 60 ]; then # 2/
		device_temp_polling_interval=60
		debug_print 3 warn "Disk device temperature check delay specified in configuration is below minimum"
		debug_print 4 "Default value will be used: $device_temp_polling_interval"
	fi # 2/
fi # 1/

##
# Validate IPMI sensor field pointers
#
# Values default to 0 when look-up value is invalid.
#
#
# IPMI Sensor Cheat-sheet
#
# fan sensors: ipmi_sensor_column_fan[metadata]
#
#	ipmi_sensor_column_fan[name]		= fan name
#	ipmi_sensor_column_fan[speed]		= current fan speed in RPM
#	ipmi_sensor_column_fan[status] 	= current fan state
#	ipmi_sensor_column_fan[lnr]
#	ipmi_sensor_column_fan[lcr]
#	ipmi_sensor_column_fan[lnc]
#	ipmi_sensor_column_fan[unc]
#	ipmi_sensor_column_fan[ucr]
#	ipmi_sensor_column_fan[unr]
#	ipmi_sensor_column_fan[hysteresis]	--> optional and not currently utilized by this program:
#
# CPU sensors: ipmi_sensor_column_name_cpu[metadata]
#
#	ipmi_sensor_column_cpu[id] = cpu id or number
#	ipmi_sensor_column_cpu[temp] = current cpu temperature
#
# more cpu sensors: ipmi_sdr_column_cpu[metadata]
# 	ipmi_sdr_column_cpu[id]
# 	ipmi_sdr_column_cpu[temp]
#
# lm-sensors: ipmi_sensor_column_cpu_temp[metadata]
#
#	ipmi_sensor_column_cpu_temp[core_id]		= cpu core number
#	ipmi_sensor_column_cpu_temp[core_temp]		= cpu core temperature
#	ipmi_sensor_column_cpu_temp[physical]		= aggregate physical cpu temperature
#	ipmi_sensor_column_cpu_temp[high]			= mannufacturer's high cpu temperature limit
#	ipmi_sensor_column_cpu_temp[critical]		= mannufacturer's critical cpu temperature limit
##

debug_print 4 "Validate IPMI related sensor field offsets"

for key in "${!ipmi_sensor_column_fan[@]}"; do # 1/
	ipmi_sensor_column_fan[$key]="$(printf "%.0f" "${ipmi_sensor_column_fan[$key]//[!0-9]/}")"
	[ "${ipmi_sensor_column_fan[$key]}" -eq 0 ] && unset "ipmi_sensor_column_fan[$key]" # ignore null or = 0
done # 1/

for key in "${!ipmi_sensor_column_cpu[@]}"; do # 1/
	ipmi_sensor_column_cpu[$key]="$(printf "%.0f" "${ipmi_sensor_column_cpu[$key]//[!0-9]/}")"
	[ "${ipmi_sensor_column_cpu[$key]}" -eq 0 ] && unset "ipmi_sensor_column_cpu[$key]"
done # 1/

for key in "${!ipmi_sdr_column_cpu[@]}"; do # 1/
	ipmi_sdr_column_cpu[$key]="$(printf "%.0f" "${ipmi_sdr_column_cpu[$key]//[!0-9]/}")"
	[ "${ipmi_sdr_column_cpu[$key]}" -eq 0 ] && unset "ipmi_sdr_column_cpu[$key]"
done # 1/

for key in "${!ipmi_sensor_column_cpu_temp[@]}"; do # 1/
	ipmi_sensor_column_cpu_temp[$key]="$(printf "%.0f" "${ipmi_sensor_column_cpu_temp[$key]//[!0-9]/}")"
	[ "${ipmi_sensor_column_cpu_temp[$key]}" -eq 0 ] && unset "ipmi_sensor_column_cpu_temp[$key]"
done # 1/

##
# Abort program when insufficient sensor references exist
##

[ "${#ipmi_sensor_column_fan[@]}" -lt 9 ] && bail_noop "One or more IPMI fan sensor column references not defined in .config or .conf files"
[ "${#ipmi_sensor_column_cpu[@]}" -lt 2 ] && bail_noop "One or more IPMI CPU sensor column references not defined in .config or .conf files"
[ "${#ipmi_sdr_column_cpu[@]}" -lt 2 ] && bail_noop "One or more IPMI sdr CPU column references not defined in .config or .conf files"

##
# lm-sensors support is optional, but offers more granular CPU
# temperature monitoring when available.
#
# When its parameters are not fully defined, it will not be used
# and the Service program will default to IPMI sensors only.
##

if [ "${#ipmi_sensor_column_cpu_temp[@]}" -gt 0 ]; then # 1/
	if [ "${#ipmi_sensor_column_cpu_temp[@]}" -lt 5 ]; then # 2/
		debug_print 2 warn "lm-sensors capabilities not available and will not be attempted by Service program"
		debug_print 3 warn "One or more lm-sensors CPU column references not defined in .config or .conf files"
	fi # 2/
fi # 1/

##
# Validate fan control method
##

case "$fan_control_method" in # 1/
	direct|group|universal|zone)
		debug_print 4 "IPMI write fan control method is \"$fan_control_method\""
	;;

	*)
		debug_print 1 warn "Fan control method missing or not recognized"

		[ -n "$manufacturer_config_file" ] && debug_print 4 bold "Check motherboard manufacturer level .conf file: $manufacturer_config_file"
		[ -n "$model_config_file" ] && debug_print 4 bold "Check motherboard model level .conf file: $model_config_file"
		bail_noop "IPMI write fan control method must be specified, but is not. Check config and relevant zone files"
	;;
esac # 1/

###############
# PID Constants
###############

[ -z "$pid_Kp" ] && pid_Kp=0
[ -z "$pid_Ki" ] && pid_Ki=1
[ -z "$pid_Kd" ] && pid_Kd=0

###############################################
# Scan for Pre-Existing Service Program Daemons
###############################################

##
# Assign systemd daemon service default filenames.
#
# Assign default values when not specified in config file.
##

debug_print 4 "Assign default values for Service program daemon service names, when not specified in config file"

[ -z "$launcher_daemon_service_name_default" ] && launcher_daemon_service_name_default="${service_name}_launcher"
[ -z "$runtime_daemon_service_name_default" ] && runtime_daemon_service_name_default="${service_name}_runtime"
[ -z "$failure_handler_service_name_default" ] && failure_handler_service_name_default="${service_name}_fnh"

############################################################
# Analyze Possibility of Recycling Pre-Existing Installation
############################################################

##
# Set $recycle_service_daemons = null, false, or true
#
# null = no pre-existing installation to recycle
# false = there is a pre-existing install, but do not recycle it, do remove old files
# true = there is a pre-existing install, do recycle it, do not remove old files
##

# initial presumption is there is are no pre-existing service deamons
unset recycle_service_daemons

if detect_service_daemons; then # 1/
	if ! set_recycle_daemons_mode; then # 2/ recycle_service_daemons = false
		debug_print 4 "Recycling pre-existing implementation not possible"
	fi # 2/

	##################################################
	# Remove Obsolete Daemon and Service Program Files
	##################################################

	##
	# Remove pre-existing service program and daemon files when they exist and program
	# mode is not set to recycle pre-existing installation.
	#
	# When incumbent service files are recycled, only the Service Launcher init file is
	# removed.
	##

	remove_old_service_files # only runs when $recycle_service_daemons != null
fi # 1/

# ensure Service daemon service names are set correctly
if [ -z "$launcher_daemon_service_name" ]; then # 1/ not recycling
	launcher_daemon_service_name="$launcher_daemon_service_name_default"
	debug_print 2 "Set Service Launcher daemon name to default value: $launcher_daemon_service_name"
fi # 1/

if [ -z "$runtime_daemon_service_name" ]; then # 1/ not recycling
	runtime_daemon_service_name="$runtime_daemon_service_name_default"
	debug_print 2 "Set Service Runtime daemon name to default value: $runtime_daemon_service_name"
fi # 1/

if [ "$enable_failure_notification_service" = true ]; then # 1/
	if [ -n "$email" ]; then # 2/
		if [ -z "$failure_handler_service_name" ]; then # 3/
			failure_handler_service_name="$failure_handler_service_name_default"
			debug_print 2 "Set Failure Notification Handler daemon name to default value: $failure_handler_service_name"
		fi # 3/
	else # 2/
		enable_failure_notification_service=false
		debug_print 3 "Ignored Failure Notification Handler daemon service activation request because Service user email address is not defined"
	fi # 2/
else # 1/
	unset failure_handler_service_name
fi # 1/

#############################################
# Validate Service Program Target Directories
#############################################

##
# Set target directory locations
#
# 1. Top level target parent directory
# 2. Service Launcher program files dir
# 3. Service Runtime program files dir
# 4. Service include files dir
##

# top-level dir declared in Builder config file
if [ -n "$target_dir" ]; then # 1/
	debug_print 4 "Top level parent of Service directory declared in config file"

	# trim any trailing slash (/) and disqualify dir if is root dir
	if ! trim_trailing_slash "$target_dir"; then # 2/
		debug_print 2 warn "An error occurred while attempting to parse pre-defined top level parent of Service directory: $target_dir"
		debug_print 4 "Discard top level directory parent of Service directory declared in config file"
		unset target_dir
	fi # 2/
else # 1/
	debug_print 3 caution "Top level parent of Service directory not declared in config file"
fi # 1/

##
# When target_dir is missing from config file or specified, but invalid, attempt to deduce prior location
##

# assign top-level parent target directory location
if [ -z "$target_dir" ]; then # 2/ not recycling pre-existing implementation and target dir not defined in config file
	[ -z "$target_dir_old" ] && bail_noop "Alternate path for top level Service directory could not be deduced"

	debug_print 3 "Utilize pre-existing Service programs shared top level parent directory as alternate target: $target_dir_old"
	target_dir="$target_dir_old"
fi # 1/

debug_print 2 "Top level Service programs directory: $target_dir"

# set default locations for Service program files
[ -z "$service_launcher_target_dir" ] && service_launcher_target_dir="${target_dir}/launcher"
[ -z "$service_runtime_target_dir" ] && service_runtime_target_dir="${target_dir}/runtime"
[ -z "$service_functions_target_dir" ] && service_functions_target_dir="${target_dir}/functions"

###########################################################
# Validate and/or Create Service Program Target Directories
###########################################################

##
# Parent of top-level target dir (parent of parent)
##

# Service user needs travers + read rights for top-level grand-parent target dir (parent of parent dir)
if ! set_target_permissions "$(dirname "$target_dir")" PERM_READ_TRAVERSE true; then # 1/ Service user needs sufficient permissions as well
	debug_print 3 warn "Both traverse and write access permissions are required to parent dir of target directory for Service user"
	bail_noop "Insufficient access permissions for Service user to parent directory of top-level target directory"
fi # 1/

##
# Top-level target dir (parent of required dirs)
##

if ! validate_file_system_object "$target_dir" directory; then # 1/ top level target dir needs to be created
	debug_print 3 "Create target directory (does not exist): $target_dir"

	# current user needs travers + write rights for top-level grand-parent target dir (parent of parent dir)
	if ! set_target_permissions "$(dirname "$target_dir")" PERM_WRITE_TRAVERSE; then # 2/ need permission to traverse and write from parent of parent dir
		debug_print 3 warn "Both traverse and write access permissions are required to parent dir of target directory for current user"
		bail_noop "Insufficient access permissions for current user to parent directory of top-level target directory"
	fi # 2/

	# create new target dir after ensuring sufficient rights to parent dir of top-level target dir
	! run_command mkdir -p -v "$target_dir" && bail_noop "Top level target directory creation failed" # mkdir command failed
fi # 1/

# validate permissions of current user to top-level parent target dir (trap edge case)
if ! set_target_permissions "$target_dir" PERM_WRITE_TRAVERSE; then # 1/ need permission to traverse and write in order to setup target dirs for Service program user
	debug_print 3 warn "Both traverse and write access permissions are required to parent dir of target directory"
	bail_noop "Creation of top-level Service program target directory failed: insufficient access permissions to its parent directory"
fi # 1/

# validate permissions of current user to top-level parent target dir
if ! set_target_permissions "$target_dir" PERM_READ_TRAVERSE true; then # 1/ need permission to traverse and write in order to setup target dirs for Service program user
	debug_print 3 warn "Both traverse and write access permissions are required by Service user to parent dir of target directory"
	bail_noop "Service user has insufficient top-level Service program target directory access permissions"
fi # 1/

##
# 2nd tier dirs (top-level dirs by program function)
##

# Launcher program dir (create new dir if necessary)
if ! validate_file_system_object "$service_launcher_target_dir" directory; then # 1/ top level target dir needs to be created
	debug_print 3 "Create Service Launcher program directory (does not exist): $service_launcher_target_dir"
	! run_command mkdir -p -v "$service_launcher_target_dir" && bail_noop "Creation of Service Launcher target directory failed"
	! set_target_permissions "$service_launcher_target_dir" PERM_READ_TRAVERSE true && bail_noop "Service user has insufficient directory access permissions to Service Launcher program directory"

fi # 1/

# Runtime program dir (create new dir if necessary)
if ! validate_file_system_object "$service_runtime_target_dir" directory; then # 1/ top level target dir needs to be created
	debug_print 3 "Create Service Runtime program directory (does not exist): $service_runtime_target_dir"
	! run_command mkdir -p -v "$service_runtime_target_dir" && bail_noop "Creation of Service Runtime target directory failed"
	! set_target_permissions "$service_runtime_target_dir" PERM_ALL true && bail_noop "Service user has insufficient directory access permissions to Service Runtime program directory"
fi # 1/

# Service include files dir (create new dir if necessary)
if ! validate_file_system_object "$service_functions_target_dir" directory; then # 1/ top level target dir needs to be created
	debug_print 3 "Create Service include files directory (does not exist): $service_functions_target_dir"
	! run_command mkdir -p -v "$service_functions_target_dir" && bail_noop "Creation of Service include files target directory failed"
	! set_target_permissions "$service_functions_target_dir" PERM_READ_TRAVERSE true && bail_noop "Service user has insufficient directory access permissions to Service include files directory"
fi # 1/

##
# Set default target Service executable program filenames when not deduced from previous install
##

if [ -z "$service_launcher_target_filename" ]; then # 1/
	service_launcher_target_filename="${service_launcher_target_dir}/${builder_program_basename%*_builder*}_service_launcher.sh"
fi # 1/

if [ -z "$service_runtime_target_filename" ]; then # 1/
	service_runtime_target_filename="${service_runtime_target_dir}/${builder_program_basename%*_builder*}_service_runtime.sh"
fi # 1/

if [ -z "$service_failure_handler_target_filename" ]; then # 1/
	service_failure_handler_target_filename="${target_dir}/${builder_program_basename%*_builder*}_failure_handler.sh"
fi # 1/

##############################################
# Validate Service Program Logging Directories
##############################################

##
# Service program log files are numerous and stored in dedicated log directories.
# The parent log directory path should be defined in the Builder configuration
# file. If not, a default location will be derived if any sort of logging is
# requested.
#
# When Service program log directory is not pre-defined, then if debug logging
# is requested or JSON meteadata logging is requested, assign a default log
# directory name.
#
# When neither debug logging nor JSON metadata logging are requested, disable
# logging capabilities.
#
# These parameters are passed through to the Service Launcher via its .init file.
##

if [ "$debug_level" -gt 0 ] || [ "$log_json_export" = true ]; then # 1/ program logging is requested
	if [ -n "$service_log_dir" ]; then # 2/ Service Log Directory name specified in Builder config file
		trim_trailing_slash "service_log_dir"
		[ -z "$service_log_dir" ] && debug_print 2 warn "Service log directory specified in Builder config cannot be root (\$service_log_dir)"
	fi # 2/

	##
	# Reset $service_log_dir when not specified in Builder config file or invalidated above
	##

	if [ -z "$service_log_dir" ]; then # 2/ set default when service log parent dir not defined in config file or is invalid
		service_log_dir="${target_dir}/log/${service_name}"
		debug_print 2 "Assigning default location to parent directory of Service program logs: ${service_log_dir}/"

		# create log dir
		if run_command mkdir -p -v "$service_log_dir"; then # 3/
			debug_print 2 "Created new Service program log directory: $service_log_dir"
		else # 3/ dir path not specified correctly
			debug_print 2 warn "\$service_log_dir directory structure specified in Builder config is invalid or its creation failed"
			unset service_log_dir
		fi # 3/
	fi # 2/

	##
	# Establish Service user file system access permissions to Service log dir
	##

	if [ -n "$service_log_dir" ]; then # 2/ service log exists
		if set_target_permissions "$service_log_dir" 555; then # 3/ limit all user access to read and traverse only
			if set_target_permissions "$service_log_dir" PERM_ALL; then # 4/ current user needs full access
				if set_target_permissions "$service_log_dir" PERM_ALL true; then # 5/ Service user needs full access

					# probe with test file before continuing
					service_log_test_file="${service_log_dir}/test_file.log"

					if create_log_file "service_log_test_file" true; then # 6/ successfully validated log file creation ability
						debug_print 4 "Remove dummy test log file: $service_log_test_file"

						if ! run_command rm -f "$service_log_test_file" || validate_file_system_object "$service_log_test_file" file; then # 7/ something wrong with file system permissions
							debug_print 4 warn "Failed to remove test log file for an unknown reason"
							unset service_log_dir
						fi # 7/
					fi # 6/
				else # 5/ something went wrong (trap edge case)
					debug_print 3 warn "Service user could not be granted sufficient access permissions to Service log directory"
					unset service_log_dir
				fi # 5/
			else # 4/ dir path is root
				debug_print 3 warn "Failed to assign sufficient access rights for current user to Service program log directory"
				unset service_log_dir
			fi # 4/
		else # 3/
			debug_print 4 warn "Failed to set desired file system access to Service log directory for non-current or Service program users"
		fi # 3/
	fi # 2/
else # 1/ do not use
	unset service_log_dir
fi # 1/

# disable all Service program logging when not feasible
if [ -z "$service_log_dir" ]; then # 1/
	debug_print 3 caution "Service program and metadata logging are disabled"
	debug_level=0
	log_json_export=false
fi # 1/

[ "$debug_level" -eq 0 ] && debug_print 4 "Service program logging declined or disabled"
[ "$log_json_export" != true ] && debug_print 4 "Service program JSON metadata logging capability declined or disabled"

######################
# Log Aging Parameters
######################

##
# Service program debug logs are deleted after maximum age limit in days.
#
# Max age is the maximum program log file age expressed in days. Files older
# than this number are automatically deleted.
#
# Default maximum age of program logs is 14 days.
##

# strip any character not integer or decimal, then round to nearest integer
log_age_max="$(printf "%.0f" "${log_age_max//[!.0-9]/}")"

[ "$log_age_max" -eq 0 ] && log_age_max=14 # default max program log age to 14 days
debug_print 4 "Service program maximum log age: $log_age_max days"

##
# Service program logs are rotated at regular intervals, expressed as number of hours.
#
# Every x hours, the current Service program log is closed and a new log file is started.
#
# There is no maximum (though 24 is recommended, and the default). Must be integer/whole
# number.
##

# number of hours between service program log full metadata updates
log_hourly_interval="$(printf "%.0f" "${log_hourly_interval//[!0-9]/}")"
[ "$log_hourly_interval" -lt 1 ] && log_hourly_interval=12 # program log duration in hours; default = every 12 hours
[ -n "$log_filename" ] && debug_print 4 "Service program log file reset interval: $log_hourly_interval hours"

##
# Service program log creation time stamps can be aligned with the beginning of the hour.
#
# When the flag = true, Service program logs begin and end on the hour per local time.
#
# This feature does not affect JSON file time stamps.
##

# align service file log timestamps on the hour when true
[ "$log_hourly_alignment" != true ] && log_hourly_alignment=false

{ [ -n "$log_filename" ] && [ "$log_hourly_alignment" = true ]; } && debug_print 4 "Service program log start time alighned with hourly interval"

##
# Metadata logging intervals
#
# Optional. Metadata is logged separately from the program logs, and
# is stored in JSON format.
#
# JSON logs have their own interval and max age
#
# JSON logs are created at periodic intervals,
# expressed as seconds. So, that every X seconds,
# a new system snapshot is recorded.
#
# These logs are very verbose, and it is recommended to keep their
# rotation interval to under 1 hour per log file. The default is
# 10 minutes.
#
# Interval times must be expressed in seconds between file rotations.
#
# Max age is the maximum JSON log file age expressed in days. Files
# older than this number are automatically deleted.
#
# Note: When the program logging variable $log_hourly_alignment = true,
# JSON logs intervals will be aligned based on the hour. The JSON
# interval ($log_json_interval) must be a factor or multiple of 1 hour
# (36000 seconds). If it is not, the hourly interval setting will be ignored.
##

log_json_interval="$(printf "%.0f" "${log_json_interval//[!0-9]/}")"
(( log_json_interval < 1 )) && log_json_interval=600 # JSON program log duration in seconds; default = every 10 minutes

# maximum age in days of JSON logs
log_json_age_max="$(printf "%.0f" "${log_json_age_max//[!0-9]/}")"
(( log_json_age_max < 1 )) && log_json_age_max=$((log_age_max)) # when JSON max log age is undefined, align it with max age limit of program logs

if [ "$log_json_export" = true ]; then # 1/ track granular metadata in separate JSON formatted data log
	debug_print 4 "JSON log duration (in seconds): $log_json_interval"
	debug_print 4 "Maximum JSON log age (in days): $log_json_age_max"
fi # 1/

#######################################
# Validate Service Program Source Files
#######################################

##
# Validate required Service program files, but only when pre-existing implementation
# does not exist or is not tagged for re-use.
##

[ "$recycle_service_daemons" != true ] && inventory_service_program_files

##############################
# Validate Fan Duty Categories
##############################

# discard empty fan duty category placeholders
debug_print 4 "Discard empty \$fan_duty_category[] array elements"

for key in "${!fan_duty_category[@]}"; do # 1/
	[ -z "${fan_duty_category[$key]}" ] && unset "fan_duty_category[$key]"
done # 1/

##
# $fan_duty_category[] array values are required to meet the following criteria:
#	- 1. Must start with lowercase letter
#	- 2. May include lowercase letters, numbers, and dashes (-)
#	- 3. No spaces or other punctuation
##

debug_print 3 "Scrub all \$fan_duty_category[] array elements to ensure they meet eligibility requirements"

for key in "${!fan_duty_category[@]}"; do # 1/ remove bad array entries
	if printf "${fan_duty_category[$key]}" | grep -vqE '^[a-z][a-z0-9-]*$'; then # 1/
		debug_print 3 caution "Removed invalid reference value from $fan_duty_category[] array: "${fan_duty_category[$key]}""
		unset fan_duty_category[$key]
	fi # 1/
done # 1/

###########################################
# Ensure Required Fan Duty Categories Exist
###########################################

[ "${#fan_duty_category[@]}" -eq 0 ] && debug_print 1 warn "No fan duty categories defined (required in Builder config files)"

# cpu fan duty category type is required
if ! grep -i -w -F -q "cpu" <<< "${fan_duty_category[*]}"; then # 1/ not found in array
	fan_duty_category+=("cpu") # create it
	debug_print 3 caution "CPU fan duty category created because its declaration was not found in any Builder configuration file"
fi # 1/

# when there is only one fan category force cpu fans only (it must be cpu)
if [ "${#fan_duty_category[@]}" -eq 1 ]; then # 1/ only cpu fans
	only_cpu_fans=true
	debug_print 2 caution "CPU is the only fan duty category cooling type"
	debug_print 3 "This means all fan headers will be treated as having CPU fan cooling duty by default"
fi # 1/

##
# 'exclude' (exclusionary) fan header binary is required. This binary string acta as a placeholder
# to keep track of fans that have been excluded from use for any reason.
#
# There also needs to be an "exclude" fan duty category. Although it is a special fan duty category
# of sorts, this allows algorithms related to fan duty categories to function more efficiently (by
# recognizing 'exclude' as a valid fan duty category type).
##

# 'exclude' fan duty category type is required
if ! grep -i -w -F -q "exclude" <<< "${fan_duty_category[*]}"; then # 1/ not found in array
	debug_print 4 caution "Added missing 'exclude' fan duty category type to required array 'fan_duty_category[]'"
	fan_duty_category+=("exclude")
fi # 1/

##################################
# Create Top-Level Binary Trackers
##################################

debug_print 2 "Initialize binary tracking variables"

# create uber fan header and zone binary strings
if ! fan_header_binary="$(flush_binary "$fan_header_binary_length")" || [ "${#fan_header_binary}" -eq 0 ]; then # 1/
	bail_noop "Failed to create binary tracker 'fan_header_binary'"
fi # 1/

if ! fan_header_active_binary="$(flush_binary "$fan_header_binary_length")" || [ "${#fan_header_active_binary}" -eq 0 ]; then # 1/
	bail_noop "Failed to create binary tracker 'fan_header_active_binary'"
fi # 1/

if ! fan_zone_binary="$(flush_binary "$fan_zone_binary_length")" || [ "${#fan_zone_binary}" -eq 0 ]; then # 1/
	bail_noop "Failed to create binary tracker 'fan_zone_binary'"
fi # 1/

if ! fan_zone_active_binary="$(flush_binary "$fan_zone_binary_length")" || [ "${#fan_zone_active_binary}" -eq 0 ]; then # 1/
	bail_noop "Failed to create binary tracker 'fan_zone_active_binary'"
fi # 1/

###################################
# Create Duty-Level Binary Trackers
###################################

##
# The section below dynamically create the global variables necessary
# to manage the binary tracker strings for every valid fan duty category,
# as defined by the '$fan_duty_category[]' array from the Builder config
# file.
#
# Utilizing this code here allows the builder to create all the global
# variables it needs for this purpose, by pivoting off just one variable
# declared in the Builder config file. This means users do not need to
# edit the Builder global declarations file in addition to the Builder
# config file, in order to create new binary trackers.
#
# Similar logic is applied when constructing the .init files for the
# Service Launcher and Runtime programs.
#
# All the way around, this makes the process of creating new fan duty
# categories and their associated binary trackers a simpler process.
##

<<>> 

--> below apparently wont work
--> might have to overhaul the whole binaries concept to use associative arrays instead of global strings
	--> would allow better flexibility

--> maybe something like:
	--> fan_zone_binary[cpu]=
	--> fan_zone_binary[disk]=
	--> fan_zone_binary[exclude]=

--> would require re-thinking how the zone and header binaries are managed
--> also what would the master binary names become? would they be needed?


Explanation:

Declare the variable: declare "${duty_type}_fan_header_binary" creates the variable name dynamically.

Assign the value: eval "${duty_type}_fan_header_binary=$(flush_binary "$fan_header_binary_length")" assigns the result of flush_binary to the dynamically generated variable.

Check if the variable is empty: The check if [ -z "${!duty_type}_fan_header_binary" ] ensures that we dereference the dynamically named variable and check its value.

<<>>

declare -A fan_header_binaries

# Assign the value using an associative array
fan_header_binaries["${duty_type}_fan_header_binary"]=$(flush_binary "$fan_header_binary_length")

# Check if the value exists and is non-empty
if [ -z "${fan_header_binaries["${duty_type}_fan_header_binary"]}" ]; then
    bail_noop "Failed to create binary tracker '${duty_type}_fan_header_binary'"
fi

<<>>


# create type-specific fan header and fan zone binary strings
for key in "${!fan_duty_category[@]}"; do # 1/
	duty_type="${fan_duty_category[$key]}"

	if declare -p "${duty_type}_fan_header_binary" &>/dev/null; then # 1/ already declared (duplicate)
		unset fan_duty_category[$key] # remove duplicate fan duty category index
		continue
	fi # 1/

	declare "${duty_type}_fan_header_binary=$(flush_binary "$fan_header_binary_length")"

	if [ -z "${!duty_type}_fan_header_binary" ]; then # 1/
		bail_noop "Failed to create binary tracker '${duty_type}_fan_header_binary'"
	fi # 1/

	# only create additional binary types when duty type is not for exclusionary purposes
	if [ "$duty_type" != "exclude" ]; then # 1/
		if ! declare "${duty_type}_fan_header_active_binary=$(flush_binary "$fan_header_binary_length")"; then # 2/
			bail_noop "Failed to create binary tracker '${duty_type}_fan_header_active_binary'"
		fi # 2/

		# duty category fan zone trackers are only relevant when fan control method is zoned
		if ! declare "${duty_type}_fan_zone_binary=$(flush_binary "$fan_zone_binary_length")"; then # 2/
			bail_noop "Failed to create binary tracker '${duty_type}_fan_zone_binary'"
		fi # 2/

		# create type-specific fan zone binary strings
		if ! declare "${duty_type}_fan_zone_active_binary=$(flush_binary "$fan_zone_binary_length")"; then # 2/
			bail_noop "Failed to create binary tracker '${duty_type}_fan_zone_active_binary'"
		fi # 2/
	fi # 1/
done # 1/

# failsafe traps
[ -z "fan_header_binary[cpu]" ] && bail_noop "Failed to create required exclusionary binary tracker 'exclude_fan_header_binary'"
[ -z "fan_header_binary[exclude]" ] && bail_noop "Failed to create required exclusionary binary tracker 'exclude_fan_header_binary'"

############################
# Seed Disk Device Inventory
############################

debug_print 1 "-----------------------------------------------------------------"
debug_print 1 "-------------------- Begin Hardware Analysis --------------------"
debug_print 1 "-----------------------------------------------------------------"

##
# Seed previous average disk temp before main loop starts.
# Otherwise, the last temp value will be null because at
# this point, there is no last temp. This step eliminates
# that problem to prevent any potential odd behavior when
# the script first runs.
##

##
# Get list and number of hard drives.
#
# Get list of all hard drives. Non-disk devices and SSDs are excluded (ignored).
# $device_list is global so that changes in drive list can be detected.
##

# initial disk device list query
debug_print 1 "Seed initial disk device list"

if [ "$include_ssd" = true ]; then # 1/
	device_list="$(lsblk --scsi | grep disk | cut -c 1-3)" # new line delimited list stored as string
else # 1/
	include_ssd=false
	device_list="$(lsblk --scsi | grep disk | grep -iv 'solid.state' | cut -c 1-3)" # exclude SSDs
fi # 1/

device_count=$(printf "%s" "$device_list" | wc -l) # count number of disk devices (global variable)

<<>>

--> note in the docs this is an area that may warrant modification when modifying the list of fan duty categories away from the defaults


if (( device_count < 1 )); then # 1/
	only_cpu_fans=true
	debug_print 1 "No disk devices detected. All fan headers will be considered CPU cooling fans"
else # 1/
	debug_print 1 "Detected $device_count disk device(s)"
	[ "$only_cpu_fans" = true ] && debug_print 1 caution "One or more disk devices were found, yet program configuration calls for all fans dedicated to CPU cooling only"
fi # 1/

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

# create an inventory of all fan headers regardless of state
inventory_fan_headers

##
# Collect all fan metadata for all fans for the first time, regardless of state.
# Convert raw fan states to simplified states.
##

# grab current data for all fan headers
get_fan_info all verbose true

###################
# Define Fan Groups
###################

##
# Sets up msater fan zone binary, but does not set up category level
# fan zone binaries (this is handled later).
#
# 1. Parse fan schemas defined in config file.
# 2. Group fans by cooling function.
# 3. Define fan zones when fan control method = zoned.
# 4. Identify active vs. non-active fan headers.
# 5. Exclude non-conforming fan types (e.g. PSU fans).
# 6. Set fan_zone_binary ordinals aligned with fan group schemas
##

# organize fan headers into logical groups based on assigned cooling responsibility
inventory_fan_schemas

###################################
# CPU/Device Fan Control Validation
###################################

##		
# Prioritize CPU cooling
#
# 1. Ensure at least one fan header is dedicated to CPU cooling duty.
# 2. When this is not true, reassign all fans to CPU cooling duty.
# 3. When fan control method is zoned, also confirm at least one fan zone
# is assigned to CPU cooling duty.
#
# Note: does NOT check whether dedicated CPU fans are active. This is
# checked during stage 8, below.
##

validate_cpu_fan_headers

###################################
# CPU/Device Fan Control Validation
###################################

##
# Parse fan header level metadata and group each fan header into a fan zone.
#
# Set category-level fan zone binary ordinals based on fan header metadata (zone relationships).
##

# inventory fan duty category fan zones
inventory_category_fan_zones

# ensure excluded fans are not associated with any fan zone
cleanup_excluded_fans

##
# Here onward, fan header activity must be established, regardless of fan
# control method. When fan control method = universal it is still
# necessary to verify at least one fan header is active.
##

##
# Calibrate and report active fan headers and zones
#
# Note excluded fan check is bypassed when fan control method = universal
# because fans are not excluded for this fan control method as segmenting
# fan headers in such a manner is irrelevant.
#
# Also confirm at least one CPU fan header/zone is active. If not, force
# all fan headers/fan zones to CPU fan duty.
##

calibrate_active_fan_headers

##
# Final check to ensure fan cooling prioritizes CPUs above all else and
# there is at least one active CPU fan header (and zone, if applicable).
##

enforce_cpu_cooling_priority

# calibrate all active fan zones
calibrate_active_fan_zones

<<>>

--> with suspicious fan checks, we do need to ask these questions when a fan gets disqualified

--> how do we know if anything changed?

--> 1. are there any fan headers we expected to be active but are not active?
--> 2. are there any fan headers we expected to be inactive but which are now active?
--> 3. if answer to 1 and 2 is no for both, then there are no further checks needed as the system is as expected and pre-configured

--> 4. if answer to 1 or 2 is yes then we need to bail and tell user to re-run the builder because something changed with the fan environment

<<>>

--> follow-on procedures

--> 1. must have at least one active fan header for CPU cooling
--> 2. note in log which fan headers and groups/zones are active
--> 3. do not share active fan header info with Launcher

<<>>

##
# When zoned fan control method is in use, the fan zones should also be
# re-calibrated after this process completes in case fan zones need to
# be adjusted.
##

###############################
# BMC Fan Environmental Factors
###############################

##
# Due to oddities with some motherboard manufacturers, an opportunity
# is needed here to deal with specific tweaks after all configuration
# settings are loaded.
##

##############################
# Set BMC Fan Speed Thresholds
##############################

##
# Set initial values for BMC fan speed threshold trackers.
# All active fans. Based on current values stored in BMC.
##

# populate related arrays with incumbent BMC thresholds
debug_print 3 "Load fan speed thresholds from BMC for all fan headers"

load_bmc_fan_thresholds

##
# Although rare, some server manufacturers recommend limiting maximum fan speeds.
# This is typically due to the type of fans and/or server chassis. For example,
# small form factors with undersized, very high speed fans.
#
# The absolute maximum fan duty cycle of any fan may also be restricted by the user
# via the config file and/or .conf files for whatever reason (e.g. noise).
#
# Conflicting value limits must be resolved here, such as when the declared maximum
# fan duty limit of any fan is below the minimum fan duty limit declared for CPU fans.
#
# Other levers and switches available in the config and/or zone files influence how
# BMC fan thresholds are handled, those they are typically not implemented unless the
# config file enables automatic BMC fan adjustments.
##

# when true, configure BMC lower and upper fan speed thresholds automatically
[ "$auto_bmc_fan_thresholds" != true ] && auto_bmc_fan_thresholds=false

# fan hysteresis increment specified in config or zone file
bmc_threshold_interval="$(printf "%.0f" "${bmc_threshold_interval//[!0-9]/}")" # fan hysteresis; integers only, default = 0
[ "$bmc_threshold_interval" -eq 0 ] && debug_print 2 "Fan hysteresis interval not declared in .config or .conf files"

##
# Determine whether to set BMC upper fan speed thresholds near observed
# max fan speeds ("strict" mode) or max possible speeds BMC can read
# ("loose" mode) when fan speed thresholds should be determined automatically.
##

if [ "$auto_bmc_fan_thresholds" = true ]; then # 1/
	[ "$bmc_threshold_buffer_mode" != "strict" ] && bmc_threshold_buffer_mode="loose"
	debug_print 4 "BMC threshold buffer mode is ${bmc_threshold_buffer_mode^^}"
else # 1/
	debug_print 2 warn "Automatic BMC upper/lower thresholds detection disabled"
fi # 1/

###########################
# Fan Duty Cycle Validation
###########################

# maximum PWM allowed for any fan, normally specified in .conf file
fan_duty_limit="$(printf "%.0f" "${fan_duty_limit//[!0-9]/}")"

# board specific hardware or firmware fan speed limit
[ "$fan_duty_limit" -lt 1 ] && fan_duty_limit=100 # default max is 100% PWM
[ "$fan_duty_limit" -lt 100 ] && debug_print 3 caution "Maximum duty cycle of any fan restricted by fan duty limit ($fan_duty_limit%)"

##################################
# CPU Temperature Detection Method
##################################

##
# Verify ability to read CPU temperature sensors.
#
# --> 1. mode must be 'cpu' or 'core'
# 		--> cpu: use raw reported cpu physical temperatures
# 		--> core: cpu core temps are averaged to derive each cpu temp
# --> 2. core mode is only possible with lm-sensors
# --> 3. cpu mode is possible with either lm-sensors or ipmitool
# --> 4. cpu mode is the default
#
# This decision point impacts data collection and averaging algorithms.
#
# Even when $cpu_fan_control = false, CPU temperatures are monitored.
#
# When lm-sensors program is installed, it will be used to monitor CPU temperatures.
# When it is not available, IPMItool will be used as a secondary method.
# lm-sensors is preferred because it reports CPU temps at the core level, while
# IPMI reports only aggregate data points for each physical cpu.
#
# Note: lm-sensors is significantly quicker than ipmitool at temperature polling.
# 	--> sensors run in cpu mode is ~10x faster than ipmi cpu temp query
#	--> sensors run in cpu mode is ~7.5x faster than sensors run in core mode
#	--> sensors run in core mode is ~25% faster than ipmi
##

# default to raw cpu temp monitoring when preference not specified
if [ "$cpu_temp_method" = "core" ]; then # 1/
    debug_print 2 "CPU temperature monitoring method: core (highest core temperature)"
else # 1/
    debug_print 2 "CPU temperature monitoring method: cpu (aggregate core temperatures)"
fi # 1/

# utilize sensors program for cpu temp monitoring, when it is installed
if command -v sensors &>/dev/null; then # 1/ lm-sensors installed?
	debug_print 4 "lm-sensors program is available and will be used"
	cpu_temp_sensor="sensors" # get cpu temperature utility
else # 1/ when lm-sensors not installed, use ipmitool
	debug_print 3 "lm-sensors program not available. CPU temps will be monitored via IPMI"
	cpu_temp_sensor="ipmitool" # default cpu temp reader

	[ "$cpu_temp_method" != "cpu" ] && debug_print 2 warn "CPU temperature monitoring method changed to \"cpu\" method (reported aggregate)"
	cpu_temp_method="cpu" # force default (raw) mode of cpu temp monitoring

	[ "$auto_detect_cpu_critical_temp" = true ] && debug_print 3 warn "Automatic CPU -CRITICAL- temperature threshold disabled because <lm-sensors> program is not installed"
	auto_detect_cpu_critical_temp=false

	[ "$auto_detect_cpu_high_temp" = true ] && debug_print 3 warn "Automatic CPU -HIGH- temperature threshold disabled because <lm-sensors> program is not installed"
	auto_detect_cpu_high_temp=false
fi # 1/

debug_print 4 "Validated CPU temperature monitoring method: $cpu_temp_method"
debug_print 4 "Validated CPU temperature monitoring tool: $([ "$cpu_temp_sensor" = "sensors" ] && printf "lm-sensors" || printf "%s" "$cpu_temp_sensor")"

# validate automatic temperature detection settings
auto_detect_cpu_temp_thresholds

######################################
# Disable Pre-existing Daemon Services
######################################

##
# When the pre-existing Runtime service program daemon may be running it
# must be stopped prior to probing server hardware. Otherwise, a race
# condition will occur where the Builder and existing Service daemon
# are both competing for control over the fan speeds and settings.
##

if [ "$recycle_service_daemons" = true ]; then # 1/
	stop_service_daemon "$failure_handler_service_name" "$failure_handler_daemon_service_state"
	stop_service_daemon "$runtime_daemon_service_name" "$runtime_daemon_service_state"
fi # 1/

##################################################
# Align BMC Fan Mode and Collect Base Fan Metadata
##################################################

##
# Note: It becomes more difficult to exit gracefully from this point on
# if and when a program anomaly is encountered.
##

debug_print 2 "Auto-detect fan characteristics"

########################################################################
# Calculate Fan Speed Hystereses and Minimum BMC Fan Boundary Separation
########################################################################

##
# Calculate minimum BMC fan speed threshold interval between fan speed boundaries.
# Verify BMC fan interval when declared in configuration.
# Automatically detect fan hystereses when not declared.
# Automatic fan thresholds cannot be set if fan speed interval is unknown.
##

# validate BMC fan interval or infer it from fan metadata when unknown
validate_bmc_fan_interval

##############################
# Sanitize Fan Duty Thresholds
##############################

##
# First pass at synchronizing fan duty thresholds.
#
# Sanitize user input fan duty arrays from config file prior to processing.
#
# Synchronize all fan duty arrays. Identify and remove incomplete keys.
# Clean/Sanitize every value such that it is a rounded integer.
##

##
# When a key (fan duty type) is defined in one fan duty array, it must exist in all of them. If not,
# it is removed from whichever array it was found. This ensures the preservation of consistent handling of
# fan duties for the given array key type.
##

if ! sync_and_sanitize_arrays fan_duty_low fan_duty_med fan_duty_high fan_duty_min fan_duty_max fan_duty_start; then # 1/
	debug_print 1 warn "One or more fan_duty_ array keys could not be synchronized and were removed"
	debug_print 2 "Synchronized fan duty threshold arrays have been sanitized"
else # 1/
	debug_print 4 "Fan duty threshold arrays have been synchronized and sanitized"
fi # 1/

##
# Restrict min/max fan duty levels
##

# cap minimum fan duty levels
for key in "${!fan_duty_min[@]}"; do # 1/
	if [ "${fan_duty_min[$key]}" -gt "$fan_duty_limit" ]; then # 1/ max duty cycle of any fan cannot be less than min duty cycle
		debug_print 2 warn "Minimum '$key' fan duty cycle (${fan_duty_min[$key]}%) reduced to maximum fan duty limit ($fan_duty_limit%) for all fans"
		debug_print 4 "Min '$key' fan duty limit reduced from ${fan_duty_min[$key]}% to $fan_duty_limit%"
		fan_duty_min["$key"]="$fan_duty_limit"
	fi # 1/
done # 1/

# cap maximum fan duty levels
for key in "${!fan_duty_max[@]}"; do # 1/
	if [ "${fan_duty_max[$key]}" -gt "$fan_duty_limit" ]; then # 1/ max duty cycle of any fan cannot be less than min duty cycle
		debug_print 2 warn "Maximum '$key' fan duty cycle (${fan_duty_max[$key]}%) reduced to maximum fan duty limit ($fan_duty_limit%) for all fans"
		debug_print 4 "Max '$key' fan duty limit reduced from ${fan_duty_max[$key]}% to $fan_duty_limit%"
		fan_duty_max["$key"]="$fan_duty_limit"
	fi # 1/
done # 1/

###########################
# Enable Manual Fan Control
###########################

##
# Necessary pre-cursor to executing IPMI raw command for some motherboards.
#
# For example, most Supermicro boards have BIOS fan control mode that must
# be set to 'FULL' fan speed mode prior to attempting to set fan speeds
# manually. This disables BIOS control over fans and allows control via IPMI.
##

enable_manual_fan_control

################################
# Auto-Detect Maximum Fan Speeds
################################

##
# Record maximum fan speeds and speed limits for all fans in both fan zones.
# Calculate speed limits for fans in all fan categories.
#
# Set RPM limit vars fan speed limits by fan category.
##

collect_max_fan_speeds

#####################################################################
# Validate Upper BMC Fan Settings and Write New Fan Thresholds to BMC
#####################################################################

##
# Automatic upper BMC fan thresholds cannot be set until after all maximum fan speeds are known.
#
# BMC uppermost fan speed threshold must be at least 4x fan hysteresis above highest fan speed
# to allow a 1x fan hysteresis variation in fan speed reporting by the BMC when fans are
# running at maximum speed, without tripping any upper BMC fan thresholds. The goal is to
# prevent triggering BMC fan panic mode inadvertently.
#
# Write new fan speed boundaries to BMC.
# When there are separate cpu and disk device fan zones, verify BMC fan threshold changes did not cause BMC to initiate
# fan panic mode. This will happen if there is an anomaly in the new BMC fan settings.
# If BMC panic mode was tripped accidentally, revert the Upper BMC threshold values back to what they were before.
# Lower BMC value changes should be a non-issue, because they have been set to their lowest possible values.
# If lower BMC thresholds get tripped, it is because one or more fans are dead or dying.
# Regardless, if a low speed threshold is breached and trips BMC panic mode, do not try and stop it.
##

validate_upper_bmc_fan_thresholds

########################################
# Auto-Detect Non-CPU Minimum Fan Duties
########################################

##
# True minimum speeds can be accurately determined only for fans not assigned to CPU cooling duty.
# The process is too risky and unpredictable to attempt with fans assigned to CPU cooling duty.
#
# Namely, if CPU cooling fans are forced to a very low speed, there is a possibility of damaging
# the CPU(s). Therefore, such a strategy is to be avoided. Due to this risk, an alternative method
# is utilized to estimate CPU fan minimum speeds.
##

##
# Absolute minimum PWM duty cycle for fans assigned to non-CPU cooling duties may have a hard lower
# limit of 0%, 1%, or a pre-designated minimum fan speed (motherboard dependency).
#
# When minimum fan speed is not specified, a default of 1% is presumed. The reason for this
# is not all BMCs support 0 as a valid value when assigning a fan speed directly via IPMI.
# In fact, some BMC implementations will interpret '0' as a command to automate fan speeds
# and/or control them via the BIOS. The minimum fan duty cycle can be overridden via the
# Builder configuration file and/or motherboard-specific config files.
#
# Minimum fan duty cycle must equate to rpm >= highest lower bmc threshold + fan hysteresis.
# Highest minimum duty cycle of all device fans becomes the min duty cycle for all device fans.
#
# Note this section runs after the automatic setting of lower BMC thresholds, when requested
# per the configuration settings. This ensures by the time this section is run that the lower
# BMC thresholds may be used as benchmarks, regardless of whether automatic BMC settings are
# implemented or not.
##

<<>>

--> 1. sanity checks on values before and after real world tests

debug_print 3 "Peripheral (non-CPU) pre-validation fan duty maximum duty cycle: ${device_fan_duty_max}%"

--> 2. fan duty array keys must match fan category array except for exclude
--> 3. do real-world tests of fan speeds

#
validate_device_min_fan_speeds

--> 4. sanity checks on values after real world tests

# validate duty cycle value ordering
device_fan_duty_cycle_sanity_check

# stress test non-CPU fans to ascertain real-world min fan duty levels
validate_device_min_fan_speeds

debug_print 3 "Peripheral (device or case) post-validation fan duty minimum duty cycle: ${device_fan_duty_min}%"
debug_print 3 "Peripheral (device or case) post-validation fan duty maximum duty cycle: ${device_fan_duty_max}%"

##################################
# Estimate Minimum Fan Duty Cycles
##################################

##
# 1. Normalize starting point for minimum fan speeds based on config declared variables.
# 2. Level set minimum duty cycles based on absolute minimum rpm thresholds for each fan.
# 3. Pad minimum allowed CPU fan speeds to avoid triggering BMC panic mode during normal fan operation.
# 4. Calibrate minimum fan speeds against BMC fan thresholds, fan hysteresis, and user-defined minimum fan
# speeds found in the configuration and/or .conf files.
#
# Bare minimum RPM for each fan is the greater of the Lower Non-Critical (LNC) fan speed
# threshold + 2x fan hysteresis, or 5x fan hysteresis.
#
# BMC thresholds could have previously been set to different values for each fan. Therefore, it is wise to
# check each when calculating an overall minimum speed threshold when fan zones are utilized.
##



<<>>

calculate_cpu_fan_speed_min

#######################################################################
# Automatic BMC Fan Speed Threshold Management : Lower BMC Fan Settings
#######################################################################

##
# Configure upper and lower fan speed thresholds when requested and all
# related conditions are met. When automatic thresholds are not adjusted,
# incumbent settings will prevail.
##

validate_lower_bmc_fan_thresholds

####################################
# Validate CPU Fan Duty Cycle Levels
####################################

# validate CPU fan duty levels
validate_cpu_fan_duty_targets

# compute CPU fan speed levels relative to updated CPU fan duty levels
validate_cpu_fan_speed_levels

###########################################
# Validate Disk Device Fan Zone Duty Cycles
###########################################

##
# Check minimum fan duty cycle and its corresponding estimated fan speed
# against incumbent lower BMC fan speed thresholds.
#
# Calibrate minimum disk device fan zone duty cycle based on limitations of each fan in the fan zone.
# The fan with the highest Lower Non-Critical (LNC) threshold in its BMC settings will set the tone
# for all other fans in the same zone.
#
# The final disk device fan zone minimum duty cycle percentage may be modified later, if automatic
# BMC threshold adjustments are allowed per config.
##

<<>>

--> do this after all device fan speed duties are sorted
--> convert duty cycles to estimated rpms

validate_device_fan_speed_levels

###############################################
# Adjust Fan Speed Monitors for All Active Fans
###############################################

##
# Tweak fan speed monitoring targets as necessary to prevent false positive
# error reporting by Service program.
#
# Adjusts target fan speed thresholds associated with each fan header, based
# on each level of fan duty cycles.
##

cleanup_fan_speed_arrays

##################################
# Lower BMC Fan Settings: 2nd Pass
##################################

# 2nd pass to pickup any changes related to device cooling fans
validate_lower_bmc_fan_thresholds

#####################################
# Validate CPU Temperature Thresholds
#####################################

# validate CPU temperature variables when CPU temperature control preference set
validate_cpu_temperature_thresholds

#############################################################
# Copy Service Program Source Files to Target Service Folders
#############################################################

##
# Copy Service program files. Abort if anything goes wrong.
##

! copy_service_program_files && bail_noop "An error occurred when attempting to copy Service program files to target directory"

###########################################
# Create New .init File in Target Directory
###########################################

# create new init file for Service Launcher
! create_init_file "$service_launcher_init_filename" && bail_noop "Service Launcher .init file creation failed"

# populate Launcher init file with dynamic program metadata
update_launcher_init_file

######################################
# Create Fan Controller Service Daemon
######################################

##
# When program mode is automatic, create new daemon services for
# Service Launcher and Service Runtime.
#
# This means version checking .service file templates, copying
# .service file templates, setting their files permissions, and 
# modifying the new .service files to point to their respective
# Service program executables.
#
# This step does NOT include activating the daemon services.
##

create_service_daemons

####################################
# Start New Daemon Services and Exit
####################################

##
# After successful completion of the Builder program, on exit,
# the Universal Fan Controller Service Launcher daemon is triggered,
# which should in turn activate the Service Runtime daemon, which
# is the actual fan controller workhorse, and should take over
# control of the system fans.
##

# launch automated runtime service on program exit
debug_print 1 bold "Enable and start Service Launcher daemon on exit"

# stop existing Runtime daemon when recycling pre-existing install, before forcing Launcher to re-run and pickup new .init file
[ "$recycle_service_daemons" = true ] && stop_service_daemon "$runtime_daemon_service_name" "$runtime_daemon_service_state"

debug_print 1 "Builder script completed successfully"

printf "Starting Launcher systemd daemon service"

debug_print 1 "Start Launcher systemd daemon service"

# reset systemd services
run_command systemctl daemon-reload

# enable service on server restart
run_command systemctl enable "$launcher_daemon_service_name"
run_command systemctl start "$launcher_daemon_service_name"

# [ -n "$log_filename" ] && printf "\n" >> "$log_filename" # pad extra line for cleaner viewing using cat

debug_print 1 "Success. Builder program complete. View program log for details: %s\n" "$log_filename" false true
