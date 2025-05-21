# Universal Fan Controller (UFC)
# Service Launcher program version 2.0
#
# variable declarations file for Service Launcher
# filename: declarations_launcher.sh
#
# DO NOT REMOVE LINE BELOW
# program_version="2.0"

#################################################
# GLOBAL VARIABLE DECLARATIONS - SERVICE LAUNCHER
#################################################

##
# These variables need to be treated globally. In order to ensure this is the case,
# they are explicitly declared here. Forcing their declaration here ensures there
# are no mishaps related to the order of operation in which variables are declared,
# since the script may take different paths depending on user preferences defined
# in config file, and automated system discovery processes.
##

declare program_name							# human-readable name for this program
declare key									# for/loop operating variable
declare version								# generic variable for comparing version information

# basic program operation
declare server_id								# optional unique identifier of hardware device this program is being run on
declare service_name							# service program/daemon service name
declare service_username							# username expected to run Service program executables
declare -l program_module						# which core program module is currently running (e.g., builder, launcher)

# daemon .service and related files
declare failure_handler_daemon_service_filename		# full path to Failure Notification Handler SHell script called by FNH daemon service on Service program failure
declare failure_handler_script_filename				# Failure Notification Handler SHell script called by FNH daemon service on Service program failure

# motherboard info
declare -l mobo_manufacturer						# motherboard manufacturer; force lowercase to prevent errors in the script
declare -u mobo_model							# motherboard model, forced uppercase for consistency
declare mobo_gen								# motherboard generation/version/group

# global fan management properties
declare bmc_threshold_interval 					# multiple of BMC fan hysteresis
declare -l bmc_command_schema						# IPMI raw fan modulation command schema
declare fan_control_method						# fan control capability of the BMC

# number of ordinals per binary type
declare fan_zone_binary_length					# maximum number of fan zones
declare fan_header_binary_length					# maximum number of fan headers

# fan header binary trackers
declare -A fan_header_binary						# binary tracker of all existing, physically present fan header IDs
declare -A fan_header_active_binary				# binary tracker of all existing, physically present, active fan header IDs

# fan zone binary trackers
declare -A fan_zone_binary						# binary tracker of all existing, physically present fan zone IDs
declare -A fan_zone_active_binary					# binary list of active fan zone IDs

# IPMI write command ordering
declare -A -u reserved_fan_name					# special fan placeholder mappings required for group fan control method
declare -a ipmi_write_position_fan_id				# map sequential fan write position to fan ID for group method fan control; [write position] = fan id
declare -a ipmi_fan_id_write_position				# map fan ID to corresponding write position for direct fan control method; [fan id] = write position
declare -a -u ipmi_write_position_fan_name			# write position to fan name mappings for direct and group fan control methods; [write position] = fan name
declare -a -u ipmi_fan_write_order					# reference write order of fan header names based on BMC command schema
declare -a -l ipmi_group_fan_payload				# map fan ID to its pending duty cycle; [fan id] = pending duty cycle
declare ipmi_payload_byte_count					# number of bytes expected by IPMI in write command data payload

# CPU fan override flag
declare cpu_fan_override							# override byte required by some group fan management style BMC chips

# align each fan with its fan duty cooling type
declare -a -l fan_duty_category					# array list of all valid fan duty categories (e.g. cpu, device, etc.)

# physical fan header trackers
declare -a -u fan_header_name						# array of fan header ID = name ( key = fan header id ; value = fan header name )
declare -A fan_header_id							# array of fan header name = ID ( key = fan header name ; value = fan header id )
declare -a fan_header_zone						# array of fan header ID = fan zone ( key = fan header id ; value = fan zone id )

# fan speed trackers
declare -a fan_header_speed						# current speed of each fan in RPMs
declare -a fan_speed_limit_min					# minimum physical operating speed of each fan (key = fan header id) in RPMs
declare -a fan_speed_limit_max					# maximum physical operating speed of each fan (key = fan header id) in RPMs

# fan speed alert thresholds, by duty cycle
declare -a fan_speed_duty_low						# lowest expected RPM when duty cycle = low
declare -a fan_speed_duty_med						# lowest expected RPM when duty cycle = medium
declare -a fan_speed_duty_high					# lowest expected RPM when duty cycle = high
declare -a fan_speed_duty_max						# maximum allowed RPM when duty cycle = maximum (allowed)

# IPMI sensor data column positions (sensor long form)
declare -A ipmi_sensor_column_cpu					# various ipmitool cpu sensor output column locations; passed thru to Service program
declare -A ipmi_sensor_column_fan					# various ipmitool fan sensor output column locations

# IPMI sdr data column positions (sensor short form)
declare -A ipmi_sdr_column_cpu					# ipmitool sdr mode cpu related variables (carry-thru to service program)

# lm-sensors output data columns
declare -A ipmi_sensor_column_cpu_temp				# specific to lm-sensors output

# flag indicating all fan zones are treated as a single zone
declare -l only_cpu_fans							# true when there is only one fan zone or all fan zones are responsible for cooling CPU

# number of physical CPUs
declare numcpu									# number of active, physical CPUs (not cores); auto-detected

# cpu temperature thresholds
declare cpu_temp_low							# user-defined temperature threshold to trigger cpu fan mode low speed
declare cpu_temp_med							# user-defined temperature threshold to trigger cpu fan mode medium speed
declare cpu_temp_high							# user-defined temperature threshold to trigger cpu fan mode high speed
declare cpu_temp_override						# force disk device fans to maximum speed when specified cpu temperature is reached

# duty cycle correlated percentages
declare -A fan_duty_min							# minimum allowed fan duty cycle
declare -A fan_duty_low							# duty cycle (%age fan speed) to set fans to when average temperature is <= low temp threshold
declare -A fan_duty_med							# duty cycle to set fans to when average temperature is <= medium temp threshold
declare -A fan_duty_high						# duty cycle to set fans to when average temperature is >= high temp threshold
declare -A fan_duty_max							# duty cycle to set fans to when cpu critical temperature threshold reached (cpu panic mode)
declare -A fan_duty_start						# duty cycle to start fans on program start-up

# user-defined controls governing cpu temperature control and monitoring factors
declare -l cpu_temp_sensor						# cpu temperature sensor utility (e.g. sensors or ipmitool)
declare -l cpu_temp_method						# cpu temperature monitoring method (raw physical or core average)

# maximum fan duty limited by hardware or firmware
declare fan_duty_limit							# set via .conf files or config file

# disk device fan duty cycle percentage trackers
declare device_fan_duty_min
declare device_fan_duty_low
declare device_fan_duty_med
declare device_fan_duty_high
declare device_fan_duty_max
declare device_fan_duty_start						# duty cycle percentage to set device fans to on program start

# logging
declare debug_level								# debug service level
declare -l log_to_syslog							# true when syslog can be written to via built-in logger program
declare log_filename							# builder program current log filename
declare service_runtime_log_filename				# Service Runtime program log filename passed to Runtime program
declare -l log_file_active						# Service Launcher program true/false flag that determines when log_filename is validated and available for logging
declare -l runtime_log_file_active					# Service Runtime program true/false flag that determines when log_filename is validated and available for logging

# misc variable init
declare device_temp_reader 						# pointer to device temperature reading program
declare ipmitool 								# pointer to IPMI tool
declare permissions								# file object permissions

# timers
declare fan_speed_delay 							# minimum time in seconds between between fan speed adjustments and fan speed validation checks
declare wait_timer								# Service Runtime main loop delay timer

# disk device tracking
declare device_count 							# number of storage devices (auto-detected)
declare device_list								# newline delimited list of all disk device names (e.g. sda, sdb, etc.)
declare device_list_old							# newline delimited list of previous poll of disk device names (i.e., previous value of $device_list)

#################################################
# Critical program dir and file location trackers
#################################################

# pre-existing installation target locations
# declare service_launcher_declarations_target_filename	# pointer to file location of Service Launcher variable declarations file used by Service Launcher
# declare service_runtime_declarations_target_filename	# pointer to file location of Runtime Launcher variable declarations file used by Runtime Launcher
# declare service_launcher_manifest_target_filename		# pointer to file location of Service Launcher include file manifest validated by Service Launcher
# declare service_runtime_manifest_target_filename		# pointer to file location of Service Runtime include file manifest validated by Service Launcher

# target directories
declare target_dir								# top level target service program operating directory /target_dir/
declare service_launcher_dir						# service launcher program operating directory /target_dir/launcher/
declare service_runtime_dir						# service runtime program operating directory /target_dir/runtime/
declare service_functions_dir						# /target_dir/functions/

# Service program .init filenames
declare service_launcher_init_filename				# full path of Service Launcher .init file /target_dir/launcher/{service_name}.init
declare service_runtime_init_filename				# full path of Service Runtime .init file /target_dir/runtime/{service_name}.init

# Service manifest filenames
declare service_launcher_manifest_filename			# /source_dir_parent/config/manifest_service_launcher.info
declare service_runtime_manifest_filename			# /source_dir_parent/config/manifest_service_runtime.info

# destination filenames when copying/creating new executables
declare service_runtime_filename					# target service runtime program full path filename /target_dir/runtime/{runtime_filename.sh}

# primary log directories
declare service_log_dir							# service program log directory; default /target_dir/logs/
declare service_launcher_log_dir					# service launcher program log directory; default /target_dir/logs/launcher/
declare service_runtime_log_dir					# service runtime program log directory; default /target_dir/logs/runtime/
declare service_json_log_dir						# /target_dir/service/runtime/json/
declare service_json_log_test_filename				# /target_dir/service/runtime/json/filename.json

# program logging related variables
declare next_log_hour							# next hour number (based on 24-hour clock) when new program log must be started on the hour
declare next_log_time							# time (in epoch, seconds) to create next summary in program log

# JSON metadata logging related variables
declare json_next_log_time						# time to begin next JSON log

# Failure Notification Handler
declare -l enable_failure_notification_service		# true/false flag to indicate whether or not the Failure Notification Handler daemon should be implemented (true) or not (false)

# program version trackers
declare service_program_version					# version number of new (target) service program

# disk device temp monitors
declare device_avg_temp_target 					# mean of all current disk device temperatures
declare device_max_allowed_temp 					# trip panic mode when a disk device exceeds this temperature
declare -l include_ssd							# include SSDs as disk devices when true

# email alerts
declare -l email_alerts							# status flag which determines whether or not to send alert emails when warranted
declare email									# email address to which alert emails will be sent (the "To" address)

# Service program logging related variables
declare log_hourly_alignment						# indicates whether or not new runtime program logs should be started on the hour
declare log_hourly_interval						# number of hours between posted log summaries
declare log_age_max								# maximum age in days of oldest program log file

declare -l log_json_export						# JSON log file export preference
declare log_json_interval						# time interval in seconds between JSON metadata file dumps by runtime program
declare log_json_age_max							# maximum age in days of oldest JSON metadata log file

# PID vars
declare pid_Kp 								# proportional Constant
declare pid_Ki 								# Integral Constant
declare pid_Kd 								# Derivative Constant

# timers
declare fan_validation_delay 						# time buffer (in seconds) between fan speed validation checks
declare cpu_temp_check_delay						# minimum time interval in seconds between cpu temperature checks (default = 2 seconds)
declare device_temp_check_delay	 				# minimum time interval in seconds between disk device temperature checks
declare device_polling_interval					# interval (in seconds) between disk device temperature polls
declare next_device_list_poll_time					# next time interval in seconds (epoch time) to inventory active disk devices

# monitoring mean temperature of all cpus combined
declare cpu_temp_rolling_average_limit				# number of averages to use in calculating rolling average of cpu temps over time

# cpu rpm vars
declare -A fan_speed_min						# universal, minimum operating speed in RPM of CPU fans

# BMC managed fan speed thresholds
declare -a fan_speed_lnr 						# Lower Non-Recoverable RPM array ( key = fan header id )
declare -a fan_speed_lcr 						# Lower CRitical
declare -a fan_speed_lnc 						# Lower Non-Critical
declare -a fan_speed_unc 						# Upper Non-Critical
declare -a fan_speed_ucr 						# Upper CRitical
declare -a fan_speed_unr 						# Upper Non-Recoverable

# below may be specified in .config file, or .conf files, or both
declare -l cpu_fan_control 						# determines whether or not the program responds to changes in CPU temperatures

# temperature check timers
declare cpu_temp_polling_interval					# interval in seconds between cpu temperature checks (default = 2 seconds)
declare device_temp_polling_interval	 			# interval in seconds between disk device temperature checks

# suspicious fan tracker
declare -a suspicious_fan_list					# array of fan headers flagged for suspicious behavior (pending exclusion)

##################################
# END GLOBAL VARIABLE DECLARATIONS
##################################
