#!/bin/bash

# shellcheck source=/dev/null
# shellcheck disable=SC2034  # Don't warn about unused variables
# shellcheck disable=SC2154  # Don't warn about undefined variables
# shellcheck disable=SC2317  # Don't warn about unreachable commands

# Universal Fan Controller (UFC)
# Service Runtime program version 2.0

# Builder and Service programs are version specific and must match.

# DO NOT REMOVE LINE BELOW
# program_version="2.0"

##
# Program Overview
#
# This program is the universal fan controller Runtime Service Runtime.
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

#################################################

# this program is a CPU and chassis fan control script
# written in BaSH for Ubuntu 16/18/20/22/24
# test environment: SuperMicro X9DRi-F | Supermicro 835 3U chassis | dual Xeon E5-2680 v2 | 2x Noctua NH-D9DX i4 3U cpu fans | 5x stock case fans

########################
# What This Program Does
########################

# 1. When CPU temperatures rise, adjust speed of CPU fans.
# 2. When disk temperatures rise, adjust speed of case fans.
# 3. Pro-actively monitor for signs of unresponsive fans, and when this occurs cold restart the BMC, and try again to control the fan speed.
# 4. If shared cpu/disk cooling is specified, and cpu temperature is high, then use the case fans to provide additional cooling.

#################
# Version History
#################
#
# The following changes by David Guyton
#
# 2024-09-11 New version 2.0 of modular program framework
#
#################

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
				logger -t "$program_name" "Runtime: $1"
				return 0
			fi # 3/
		fi # 2/
	fi # 1/

	# no message or no syslog program is available
	return 1
}

##
# Trap forced exits.
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
		printf "$program_name system Service Runtime on %s was stopped abruptly\n" "$(hostname)"
		printf "due to a non-planned system event (SIGnal trap trigger), causing the program to exit.\n\n"
		printf "%s\n\n" "${message^}"
		[ -n "$log_filename" ] && printf "More information may be available in the UFC Service program log found here:\n%s\n" "$log_filename"
	} | sendmail -t 2>&1 | send_to_syslog "SIG trap door email notification sent" || send_to_syslog "failed to send SIG trap door email notification"
}

###########################
# Format Exit Code Messages
###########################

##
# Human-readable error messages pushed to the user when a controlled program
# exit occurs. This information may help the user to diagnose potential
# problems with the Service Runtime program or their system hardware.
##

declare -a exit_code

exit_code[1]="Service Runtime global variable declarations file missing, invalid, or user lacks sufficient permissions"
exit_code[2]="failed to load Service Runtime global variable declarations file: $service_runtime_declarations_filename"
exit_code[3]="Service Runtime initialization file missing, invalid, or user lacks sufficient permissions"
exit_code[4]="failed to import Service Runtime .init file"
exit_code[5]="failed to import one or more include files"

# exit_code[4]="missing Service Runtime .init file"
# exit_code[6]="one or more Service Runtime include files failed to load correctly"

# systemd notification messages
declare -a notify_on_exit

notify_on_exit[1]="failed to validate Service Runtime global variable declarations file"
notify_on_exit[2]="failed to import Service Runtime global variable declarations file"
notify_on_exit[3]="failed to validate Service Runtime init file"
notify_on_exit[3]="failed to import Service Runtime init file"
notify_on_exit[5]="Service Runtime failed to import one or more include files"

# notify_on_exit[4]="Service Runtime failed to identify Runtime program directory"

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

	# post info in system log when possible, depending on user prefs
	send_to_syslog "$message"

	# send email to user
	if [ -n "$email" ] && command -v sendmail &>/dev/null; then # 1/
		{
			printf "%s\n" "To: $email"
			printf "%s\n" "Subject: UFC Service Failure Notification"
			printf "%s\n" "Content-Type: text/plain; charset=UTF-8"
			printf "\n" # separate headers from the body per sendmail requirements
			printf "Universal Fan Controller (UFC) system Service Runtime on %s detected a failure condition and exited\n\n" "$(hostname)"
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
			debug_print 4 warn "Undefined file system object variable name '\$1'"
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
	return 0
}

###########
# Set Traps
###########

# trap signals and interrupts
trap trap_door_on_signal SIGTERM SIGABRT INT

# trap intentional program exits
trap 'trap_door_on_exit $?' EXIT

##########
# Pre-Init
##########

declare init_filename							# filename to store runtime settings; specified in config file
declare program_name							# human-readable name of this fan controller (UFC)
declare service_runtime_declarations_filename		# filename of global variable declarations to import

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
# The two var declaration lines below are modified in-vitro by the Builder or Launcher programs.
##

## DO NOT REMOVE LINE BELOW
# service_runtime_declarations_filename="{service_program_dir}/declarations_service_runtime.sh"

## DO NOT REMOVE LINE BELOW
# init_filename="{service_program_dir}/{service_name}_runtime.init"

##########################################
# Import Global Variable Declarations File
##########################################

# fail on missing info
! validate_file_system_object "$service_runtime_declarations_filename" "file" && exit 1

# load global variable declarations
! source "$service_runtime_declarations_filename" && exit 2

############################
# Import Initialization File
############################

##
# Load initialization file created by Service Launcher
##

# validate file exists and is accessible
! validate_file_system_object "$init_filename" "file" && exit 3

# load init file
! source "$init_filename" 2>/dev/null && exit 4

send_to_syslog "imported global variable declarations file: $service_runtime_declarations_filename"
send_to_syslog "imported initialization file: $init_filename"

########################################################
# Import Service Runtime Include Files per File Manifest
########################################################

##
# Verify include files appear to be imported successfully.
# Bail when any expected include file cannot be imported.
##

# load include files mentioned in Service Runtime manifest
send_to_syslog "load include files"

while read -r filename; do # 1/ import each filename from manifest
	{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue
	debug_print 4 "\tload include file... $filename"

	# catch errors
	if ! source "${service_functions_dir}/${filename}" &>/dev/null; then # 1/
		notify_systemd_status "Error: one or more include files failed to load correctly"
		exit 5
	fi # 1/
done < <(sort -u "$service_runtime_manifest_filename" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames, .sh lines only

##############
# Housekeeping
##############

# set current program module (controls branching in some subroutines)
program_module="runtime"

##
# The 'wait timer' controls the waiting period between loops of the Runtime program logic.
# It is derived by the Launcher from a variety of related other timers. Generally, it is
# resolved by the Launcher to the least common denominator of other timers. This helps to
# ensure all of these other timers run at their expected frequencies.
#
# The primary founction of the 'wait timer' is to force the primary and infinite loop in
# the Service Runtime program to pause or delay between runs, in order to reduce CPU load
# on the host machine, and to avoid unnecessary cycles when most if not all functions are
# not going to be run as quickly anyway.
##

# validate wait_timer before starting infinite loop
(( wait_timer < 2 )) && wait_timer=2 # default = 2 seconds

########################################
# Re-Enable Failure Notification Handler
########################################

##
# If program log file is missing for any reason, the program
# will continue, but any logging related functions will be disabled.
#
# Note the first Runtime log is created by the Launcher.
##

if [ -n "$log_filename" ] && [ -f "$log_filename" ]; then # 1/ update automatic program log state refresh
	log_file_active=true
	refresh_failure_handler_daemon
else # 1/
	log_file_active=false
	unset log_filename
fi # 1/

notify_systemd_status "starting infinite loop"

####################################
##
##
## Start Fan Controller Service Loop
##
##
####################################

while : ; do # 1/ infinite loop
	
	##
	# Top of loop
	#
	# 1. Implement artificial delay to avoid unnecessary churn and inefficent process utilization.
	# 2. Set global timer to current time (in seconds from Epoch).
	##

	pause # wait timer, set current time after wait

	################################################
	# Check CPU Temperature and Adjust CPU Fan Speed
	################################################

	##
	# Process CPU temperature deltas and potential CPU fan speed change when
	# not entering CPU panic mode, not exiting CPU panic mode, AND CPU zone
	# fans are actively managed.
	#
	# If $only_cpu_fans = true, both conditions will be met, because $cpu_fan_control
	# will be true, and $device_fan_override will be false.
	##

	if (( check_time > next_cpu_temp_check_time )); then # 1/ time to check CPU temp(s)
		get_cpu_temp # update CPU temp records regardless of CPU fan control status
		next_cpu_temp_check_time=$(( check_time + cpu_temp_polling_interval )) # reset timer
		{ [ "$cpu_fan_control" = true ] && [ -z "$device_fan_override" ]; } && cpu_fan_speed_filter # cpu fan control enabled and cpu panic mode not active
	fi # 1/

	################################
	# Disk Devices Temperature Check
	################################

	##
	# Check disk device temperatures.
	#
	# If related fan speeds need adjustment, this is handled below in a later
	# step.
	#
	# When disk devices exist, check average temperature of all disk devices.
	# This will occur even when there are no fan headers dedicated to disk
	# device cooling duty.
	##

	if (( check_time > next_device_temp_check_time )); then # 1/ time to check disk temps
		get_device_temp # poll drive temps, compute highest/lowest/average
		next_device_temp_check_time=$(( check_time + device_temp_polling_interval ))
	fi # 1/

	################################
	# Disk Device PID Fan Management
	################################

	##
	# Re-calculate PID fan duty for disk device cooling fans.
	#
	# This section contains the primary P.I.D. algorithm logic for tweaking device
	# zone fan speeds. It is the workhorse responsible for nudging disk zone fan
	# speeds up and down.
	#
	# The disk device fan speed management process utilizes an algorithm called
	# P.I.D. to ramp fan speeds up or down in a proportional manner relative to
	# a combination of the rate of temperature change and time, such that when
	# possible, fan speed changes are gradual.
	#
	# $device_fan_duty_pid is a floating point number and is retained between loop cycles.
	# Therefore, small incremental PID adjustments that are less than 1 are not lost, but
	# build up until they are large enough to cause a change when the PID adjusted value
	# is rounded up to the nearest integer.
	#
	# $device_fan_duty_pid_last stores the previous P.I.D. value.
	##

	if [ "$only_cpu_fans" != true ]; then # 1/ only perform this section when there are fan headers dedicated to disk cooling
		if (( device_highest_temp < device_max_allowed_temp )); then # 2/ current environmental conditions warrant normal fan speed moderation
			calc_pid # perform P.I.D. calculations

			##
			# Keep PID adjusted fan duty cycle range-bound between
			# absolute min and max duty cycle integer values.
			##

			if awk -v a="$device_fan_duty_pid" -v b="$device_fan_duty_max" 'BEGIN { exit (a > b) }'; then # 3/ device_fan_duty_pid too high
				device_fan_duty_pid=$((device_fan_duty_max))
				debug_print 3 "Adjusted P.I.D. duty cycle because it cannot be above maximum duty cycle (${device_fan_duty_max}%)"
			else # 3/
				if awk -v a="$device_fan_duty_pid" -v b="$device_fan_duty_min" 'BEGIN { exit (a < b) }'; then # 4/ device_fan_duty_pid too low
					device_fan_duty_pid=$((device_fan_duty_min))
					debug_print 3 "Adjusted P.I.D. duty cycle because it cannot be below minimum duty cycle (${device_fan_duty_min}%)"
				else # 4/ round floating point percentage to applied fan duty cycle (convert it to an integer)
					device_fan_duty="$(printf "%0.f" "$device_fan_duty_pid")"
				fi # 4/
			fi # 3/
		else # 2/ when drives are running hot, force disk device fan speeds to maximum when not already there
			if (( device_fan_duty < device_fan_duty_max )); then # 3/ force max fan speed when not already there

				# warn user
				debug_print 1 warn "Drives are too hot, pushing disk device fans to maximum: ${device_fan_duty_max}%"

				# force device fan duty to max
				device_fan_duty=$((device_fan_duty_max))

				##
				# Force-align PID, ignoring its history.
				#
				# Note: This will cause PID to start from max level and ramp down
				# slowly after control is handed back to PID, which will happen
				# after CPU temps drop below critical threshold.
				##

				device_fan_duty_pid=$((device_fan_duty_max))
			fi # 3/
		fi # 2/

		# notify user via program log when PID value changes
		awk -v a="$device_fan_duty_pid" -v b="$device_fan_duty_pid_last" 'BEGIN { exit (a != b) }' && debug_print 3 "P.I.D. changed from $device_fan_duty_pid_last to $device_fan_duty_pid"

		###################################
		# Adjust Disk Device Fan Duty Cycle
		###################################

		##
		# Regardless of PID calculation changes, it is not necessary nor prudent
		# to send fan speed change requests to the BMC unless there a material
		# change in fan speed is warranted. Namely, what matters is not whether
		# or not the P.I.D. value has changed, but whether or not the actual fan
		# duty cycle level (%age) needs to be modified, based on the PID result
		# calculated above.
		#
		# That said, extraneous circumstances can impact this logic, resulting in
		# the potential for override conditions, such as when CPU temperature(s)
		# indicate a high-temperature / panic condition.
		##

		##
		# Normal operating mode:
		#
		# 1. Not in CPU panic mode, and
		# 2. Did not just exit CPU panic mode
		#
		# Means:
		#
		# 1. PID augmented duty cycle is a floating point value is the source of truth.
		# 2. PID adjusted duty cycle is rounded to the nearest integer, and compared to
		# the previously rounded value.
		# 3. When there is a change of at least 1% (one percent), only then is the fan
		# duty cycle moderated.
		##

		if (( device_fan_duty != device_fan_duty_last )); then # 2/ did fan duty integer value (percentage) change from previous pass?
			device_fan_duty_last=$((device_fan_duty)) # store prior value before it is changed
			set_fan_duty_cycle "device" $((device_fan_duty)) false
		fi # 2/

		#############################
		# Look Out for CPU Panic Mode
		#############################

		##
		# Purpose: Determine when CPU(s) need cooling assistance from other fan headers
		# not dedicated to CPU cooling.
		##

		# check if cpu fan panic mode is warranted, or if it should be turned off
		validate_device_fan_override_mode

		##
		# Reset the override status flag now that time has passed, allowing
		# the device fans to re-adjust to their normal operating speeds.
		# There is no longer a need to skip the device fan PID comparisons.
		##

		# emerging from CPU panic mode
		if [ "$device_fan_override" = false ]; then # 2/
			unset device_fan_override

			##
			# Force wait timer, which will:
			#
			# 1. Force extra wait interval to encourage system to calm down a bit.
			# 2. Re-calibrate current time tracker.
			##

			pause

			# reset failsafe timers
			next_cpu_fan_validation_time=$(( check_time + cpu_fan_validation_delay ))
			next_device_fan_validation_time=$(( check_time + device_fan_validation_delay ))
			next_fan_validation_time=$(( check_time + all_fan_validation_delay ))
			[ -n "$suspicious_fan_timer" ] && suspicious_fan_timer=$(( check_time + suspicious_fan_validation_delay ))
		fi # 2/
	fi # 1/

	#########################################
	# Defective and Suspicious Fan Mitigation
	#########################################

	##
	# Suspicious fan states and the suspicious fan timer are set
	# by active_fan_sweep and validate_fan_duty_cycle subroutines.
	#
	# A fan is deemed 'suspicious' when it appears to be operating
	# outside of expected parameters. This may indicate a failing fan,
	# or possibly a temporary anomaly that will likely resolve itself.
	#
	# Fan headers determined to be failing or at high risk of failure
	# are disqualiifed from the pool of active cooling fans until the
	# next system reboot.
	##

	# periodically verify all fans are operating as expected
	if (( check_time > next_fan_validation_time )); then # 1/
		active_fan_sweep # re-calibrate active vs inactive fan header inventory
		next_fan_validation_time=$(( check_time + all_fan_validation_delay ))
	fi # 1/

	##
	# Check on previously reported suspicious fans when suspicious fan timer has expired.
	# When no previously reported suspicious fans exist, look for them.
	#
	# Note this will trigger active_fan_sweep during the first loop upon initial program
	# execution. The suspicious fan timer will also be set to its initial time increment.
	##

	# validate potentially suspicious fans when timer is up
	{ [ -n "$suspicious_fan_timer" ] && (( check_time > suspicious_fan_timer )); } && validate_suspicious_fans

	##############################################
	# Validate Fan Operations by Cooling Duty Type
	##############################################

	##
	# Periodically verify cooling fans are operating as expected.
	##

	# probe CPU cooling duty fans
	if (( check_time > next_cpu_fan_validation_time )); then # 1/
		validate_fan_duty_cycle cpu # verify cpu cooling fans are operating as expected
		next_cpu_fan_validation_time=$(( check_time + cpu_fan_validation_delay ))
	fi # 1/

	# probe disk device cooling fans
	if (( check_time > next_device_fan_validation_time )); then # 1/
		validate_fan_duty_cycle device
		next_device_fan_validation_time=$(( check_time + device_fan_validation_delay ))
	fi # 1/

	########################################
	# Disk Device Inventory Change Detection
	########################################

	# periodically check whether connected disk devices have changed (hot swap, new disk added to cluster, or a disk died)
	if [ -n "$device_polling_interval" ] && (( check_time > next_device_list_poll_time )); then # 1/
		poll_device_list # refresh disk device list
		next_device_list_poll_time=$(( check_time + device_polling_interval )) # reset timer to next interval
	fi # 1/

	########################
	# Program Log Management
	########################

	# when program log file timer expires, begin new log file
	if [ "$log_file_active" = true ] && (( check_time >= next_log_time )); then # 1/

		if [ -n "$log_filename" ]; then # 2/ append closure text to existing log file
			debug_print 1 "----------------------------------------------------------------"
			debug_print 1 "---------------------------- End -------------------------------"
			debug_print 1 "----------------------------------------------------------------"
			debug_print 1 "Log file closed: $(build_date_time_string)"
		fi # 2/

		# disable logging temporarily
		log_file_active=false # this will force sub call below to drop current log file pointer
		refresh_failure_handler_daemon

		# re-activate logging
		log_file_active=true

		# start new log file
		if [ -n "$service_program_version" ]; then # 2/ begin new program log file
			log_filename="${service_runtime_log_dir}/${service_name}_runtime_v${service_program_version}_$(build_date_time_string "$check_time").log"
		else # 2/ program version unknown or invalid
			log_filename="${service_runtime_log_dir}/${service_name}_runtime_$(build_date_time_string "$check_time").log"
		fi # 2/

		# start new log file and print system summary snapshot
		create_log_file "log_filename"

		if [ -n "$log_filename" ]; then # 2/
			debug_print 1 "Begin new Service Runtime program log"

			# log header
			{
				printf "Service Runtime program log\n"
				printf "version: %s\n\n" "$service_program_version"
				printf "%s \n" "$(build_date_time_string)"
				printf "This log file: %s" "$service_runtime_log_filename"
				printf "\n----------------------------------------------------------------"
				printf "\n--------------- Service Runtime Program Log File ---------------"
				printf "\n----------------------------------------------------------------"
			}  >> "$log_filename"

			# force-refresh of log filename pointer in Failure Notification Handler daemon
			refresh_failure_handler_daemon

			send_to_syslog "Service Runtime program log file created successfully: $log_filename"

			# snapsot summary
			print_log_summary

			# set timer for next program log file
			next_log_time=$(( next_log_time + ( log_hourly_interval * 3600 ) ))

		else # 2/ new log file creation failed
			log_file_active=false # disable writing program log to a file
			debug_level=0 # disable program debug logging

			send_to_syslog "failed to create new Runtime program log for an unknown reason"
			send_to_syslog "further Runtime Program logging has been disabled"
		fi # 2/
	fi # 1/

	debug_print 4 "Next Service Runtime program log time: $(build_date_time_string "$check_time")"

	################################
	# Metadata (JSON) Log Management
	################################

	##
	# The following will:
	# 1. Create new JSON file in $service_json_log_dir directory
	# 2. Dump current real-time stats to new file
	# 3. Reset timer for when to create next JSON file metadata snapshot
	##

	# save stats to JSON file when requested and timer has expired
	if [ "$log_json_export" = true ] && (( check_time >= json_next_log_time )); then # 1/
		json_log="${service_json_log_dir}/${service_name}_$(build_date_time_string "${check_time}").json" # filename for new JSON file export

		# abandon further JSON logging when failure to create a new JSON log occurs
		create_log_file "json_log"

		if [ -n "$json_log" ]; then # 2/
			debug_print 4 "Generate new JSON metadata log file"
			print_stats_to_json_log
			debug_print 4 "JSON metadata export: $json_log"
			json_next_log_time=$(( json_next_log_time + log_json_interval )) # set next log interval in epoch time
		else # 2/
			debug_print 2 warn "Failed to generate new JSON log file for an unknown reason: $json_log"
			log_json_export=false
			debug_print 1 warn "JSON logging disabled"
		fi # 2/
	fi # 1/
done # 1/ end inf loop
