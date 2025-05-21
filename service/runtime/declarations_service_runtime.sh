# Universal Fan Controller (UFC)
# Service Runtime program version 2.0
#
# variable declarations file for Service Runtime
# filename: declarations_launcher.sh
#
# DO NOT REMOVE LINE BELOW
# program_version="2.0"

################################################
# GLOBAL VARIABLE DECLARATIONS - SERVICE RUNTIME
################################################

##
# These variables need to be treated globally. In order to ensure this is the case,
# they are explicitly declared here. Forcing their declaration here ensures there
# are no mishaps related to the order of operation in which variables are declared,
# since the script may take different paths depending on user preferences defined
# in config file, and automated system discovery processes.
##

# basic program operations
declare program_name							# human-readable name for this program
declare server_id								# optional unique identifier of hardware device this program is being run on
declare service_name							# service program/daemon service name
declare service_program_version					# version number of new (target) service program
declare -l program_module						# which core program module is currently running (e.g., builder, launcher)

# IPMI write command ordering
declare ipmi_payload_byte_count					# number of bytes expected by IPMI in write command data payload

# CPU fan override flag
declare cpu_fan_override							# override byte required by some group fan management style BMC chips

# Failure Notification Handler
declare failure_handler_daemon_service_filename		# full path to Failure Notification Handler SHell script called by FNH daemon service on Service program failure

# number of ordinals per binary type
declare fan_zone_binary_length					# maximum number of fan zones
declare fan_header_binary_length					# maximum number of fan headers

# motherboard info
declare -l mobo_manufacturer						# motherboard manufacturer; force lowercase to prevent errors in the script
declare -u mobo_model							# motherboard model, forced uppercase for consistency
declare mobo_gen								# motherboard generation/version/group

# cpu temperature thresholds
declare cpu_temp_low							# user-defined temperature threshold to trigger cpu fan mode low speed
declare cpu_temp_med							# user-defined temperature threshold to trigger cpu fan mode medium speed
declare cpu_temp_high							# user-defined temperature threshold to trigger cpu fan mode high speed
declare cpu_temp_override						# force disk device fans to maximum speed when specified cpu temperature is reached

# cpu duty cycle correlated percentages
declare -A fan_duty_min							# minimum allowed cpu fan duty cycle
declare -A fan_duty_low							# duty cycle (%age fan speed) to set fans to when average temperature is <= low temp threshold
declare -A fan_duty_med							# duty cycle to set fans to when average temperature is <= medium temp threshold
declare -A fan_duty_high							# duty cycle to set fans to when average temperature is >= high temp threshold
declare -A fan_duty_max							# duty cycle to set fans to when cpu critical temperature threshold reached (cpu panic mode)
declare -A fan_duty_start						# duty cycle to start fans on program start-up
declare -A fan_duty_last							# prior fan duty of fans

# maximum fan duty limited by hardware or firmware
declare fan_duty_limit							# set via .conf files or config file

# user-defined controls governing cpu temperature control and monitoring factors
declare -l cpu_temp_sensor						# cpu temperature sensor utility (e.g. sensors or ipmitool)
declare -l cpu_temp_method						# cpu temperature monitoring method (raw physical or core average)

# specified in .config file, or .conf files, or both
declare -l cpu_fan_control 						# determines whether or not the program responds to changes in CPU temperatures

# flag indicating all fan zones are treated as a single zone
declare -l only_cpu_fans							# true when there is only one fan zone or all fan zones are responsible for cooling CPU

# number of physical CPUs
declare numcpu									# number of active, physical CPUs (not cores); auto-detected

# global CPU operating variables
declare cpu_temp_highest							# current highest temperature of all physical CPUs
declare cpu_temp_highest_last						# previous highest temperature of all physical CPUs

declare cpu_temp_lowest							# current lowest temperature of all physical CPUs
declare cpu_temp_lowest_last						# previous lowest temperature of all physical CPUs

# monitoring mean temperature of all cpus combined
declare cpu_temp_rolling_average					# rolling average of average CPU temperatures
declare cpu_temp_rolling_average_limit				# number of averages to use in calculating rolling average of cpu temps over time

# logging (this program)
declare debug_level								# debug service level
declare -l log_to_syslog							# true when syslog can be written to via built-in logger program
declare log_filename							# current program log filename
declare -l log_file_active						# true/false flag that determines when log_filename is validated and available for logging
declare service_runtime_log_filename				# Service Runtime program log filename passed to Runtime program

# color text in program log
declare enable_color_output						# when true, colorize program log output

# log directories
declare service_log_dir							# service program log directory; default /target_dir/logs/
declare service_launcher_log_dir					# service launcher program log directory; default /target_dir/logs/launcher/
declare service_runtime_log_dir					# service runtime program log directory; default /target_dir/logs/runtime/
declare service_json_log_dir						# /target_dir/service/runtime/json/

# Failure Notification Handler (FNH) daemon service
declare -l enable_failure_notification_service		# true/false flag to indicate whether or not the Failure Notification Handler daemon should be implemented (true) or not (false)

# misc variable init
declare device_temp_reader 						# pointer to device temperature reading program
declare ipmitool 								# pointer to IPMI tool

# program logging related variables
declare -l log_hourly_alignment					# indicates whether or not new runtime program logs should be started on the hour (true/false)
declare log_hourly_interval						# number of hours between posted log summaries

# JSON metadata logging related variables
declare -l log_json_export						# JSON log file export preference
declare log_json_interval						# time interval in seconds between JSON metadata file dumps by runtime program

# PID vars
declare pid_Kp 								# proportional Constant
declare pid_Ki 								# Integral Constant
declare pid_Kd 								# Derivative Constant

# disk device temp monitors
declare device_avg_temp_target 					# mean of all current disk device temperatures
declare device_max_allowed_temp 					# trip panic mode when a disk device exceeds this temperature

# global fan management properties
declare bmc_threshold_interval 					# multiple of BMC fan hysteresis
declare -l bmc_command_schema						# IPMI raw fan modulation command schema
declare fan_control_method						# type of fan control capability of the BMC

# email alerts
declare -l email_alerts							# status flag which determines whether or not to send alert emails when warranted
declare email									# email address to which alert emails will be sent (the "To" address)

#################################
# Declared in Builder Config File
#################################

# temperature probe frequency
declare cpu_temp_polling_interval					# interval in seconds between cpu temperature checks (default = 2 seconds)
declare device_temp_polling_interval	 			# interval in seconds between disk device temperature checks

# fan probe frequency
declare fan_speed_delay 							# minimum time in seconds between between fan speed adjustments and fan speed validation checks

#######################
# Calculated by Builder
#######################

# fan check timers
declare cpu_fan_validation_delay					# modified active CPU fan probe cycle
declare device_fan_validation_delay				# modified active disk device fan probe cycle
declare suspicious_fan_validation_delay 			# time buffer (in seconds) between fan speed validation checks of fans flagged as suspicious
declare all_fan_validation_delay					# calculated probe cycle of all fans regardless of fan duty category or fan state

# device polling timer
declare device_polling_interval					# interval (in seconds) between disk device temperature polls

########################
# Calculated by Launcher
########################

declare service_functions_dir						# top-level include file directory /target_dir/functions/
declare wait_timer								# artificial delay at the start of each runtime loop to prevent unnecessary churn

#############################
# Runtime Operating Variables
#############################

# disk device temp monitors
declare device_highest_temp						# highest recorded device tempertaure

# disk device tracking
declare device_count 							# number of storage devices (auto-detected)
declare device_list								# newline delimited list of all disk device names (e.g. sda, sdb, etc.)
declare device_list_old							# newline delimited list of previous poll of disk device names (i.e., previous value of $device_list)
declare -l include_ssd							# include SSDs as disk devices when true

# timers
declare check_time								# current Epoch time
declare next_cpu_temp_check_time					# when to trigger next CPU temperature check
declare next_device_temp_check_time				# when to trigger next disk device temperature check

declare next_cpu_fan_validation_time				# next timestamp to validate cpu fans (based on cpu_fan_validation_delay timer)
declare next_device_fan_validation_time				# next timestamp to validate disk device fans (based on device_fan_validation_delay timer)
declare next_fan_validation_time					# next timestamp to validate all fans (based on all_fan_validation_delay timer)
declare suspicious_fan_timer						# next timestamp to validate previously reported suspicious fans
declare next_device_list_poll_time					# next time interval in seconds (epoch time) to inventory active disk devices

# misc
declare filename								# temporary variable used for managing filenames
declare -a suspicious_fan_email_sent				# tracks fan IDs of fans removed from service, where an email was sent to user, to prevent repetitive notifications

# fan duties
declare device_fan_duty							# current device fan duty as integer
declare -l device_fan_override					# when true, device fans are commanded to run at full speed to help cool CPU (i.e. CPU panic mode)

# fan speed trackers
declare -a fan_header_speed						# current speed of each fan in RPMs

# program logging related variables
declare next_log_hour							# next hour number (based on 24-hour clock) when new program log must be started on the hour
declare next_log_time							# time (in epoch, seconds) to create next summary in program log

# JSON metadata logging related variables
declare json_next_log_time						# time to begin next JSON log

# PID calculators
declare device_fan_duty_pid						# current device fan duty as floating point PID value
declare device_fan_duty_pid_last					# previous device fan duty PID value

# suspicious fan tracker
declare -a suspicious_fan_list					# array of fan headers flagged for suspicious behavior (pending exclusion)

######################################
# Persistence Between Subroutine Calls
######################################

declare next_cpu_fan_level_change_time				# only used by cpu_fan_speed_filter subroutine, but needs to be global for persistence

########
# Arrays
########

# fan header binary trackers
declare -A fan_header_binary						# binary tracker of all existing, physically present fan header IDs
declare -A fan_header_active_binary				# binary tracker of all existing, physically present, active fan header IDs

# fan zone binary trackers
declare -A fan_zone_binary						# binary tracker of all existing, physically present fan zone IDs
declare -A fan_zone_active_binary					# binary list of active fan zone IDs

# global CPU operating variables
declare -a cpu_temp								# array of current temperature of each physical CPU
declare -a cpu_temp_last							# array of previous temperature of each physical CPU

# global CPU operating variables
declare -A cpu_core_temp							# [$cpu_id:$core_id]
declare -A cpu_core_temp_last						# [$cpu_id:$core_id]

delcare -a cpu_core_temp_highest					# array of highest temperature of all cores for a given cpu
delcare -a cpu_core_temp_lowest					# array of lowest temperature of all cores for a given cpu

# monitoring mean temperature of all cpus combined
declare -a cpu_temp_average						# array of current and recent average CPU temperatures

# IPMI write command ordering
declare -a ipmi_write_position_fan_id				# map sequential fan write position to fan ID for group method fan control; [write position] = fan id
declare -a ipmi_fan_id_write_position				# map fan ID to corresponding write position for direct fan control method; [fan id] = write position
declare -a -u ipmi_write_position_fan_name			# write position to fan name mappings for direct and group fan control methods; [write position] = fan name
declare -a -u ipmi_fan_write_order					# reference write order of fan header names based on BMC command schema
declare -a -l ipmi_group_fan_payload				# map fan ID to its pending duty cycle; [fan id] = pending duty cycle
declare -A -u reserved_fan_name					# special fan placeholder mappings required for group fan control method

# align each fan with its fan duty cooling type
declare -a -l fan_duty_category					# array of valid fan duty categories (e.g. cpu, device)

# physical fan header trackers
declare -a -u fan_header_name						# array of fan header ID = name ( key = fan header id ; value = fan header name )
declare -A fan_header_id							# array of fan header name = ID ( key = fan header name ; value = fan header id )
declare -a fan_header_zone						# array of fan header ID = fan zone ( key = fan header id ; value = fan zone id )

# IPMI sensor data column positions (sensor long form)
declare -A ipmi_sensor_column_cpu					# various ipmitool cpu sensor output column locations; passed thru to Service program
declare -A ipmi_sensor_column_fan					# various ipmitool fan sensor output column locations

# IPMI sdr data column positions (sensor short form)
declare -A ipmi_sdr_column_cpu					# ipmitool sdr mode cpu related variables (carry-thru to service program)

# lm-sensors output data columns
declare -A ipmi_sensor_column_cpu_temp					# lm-sensors output cpu specific

# BMC managed fan speed thresholds
declare -a fan_speed_lnr 						# Lower Non-Recoverable RPM array ( key = fan header id )
declare -a fan_speed_lcr 						# Lower CRitical
declare -a fan_speed_lnc 						# Lower Non-Critical
declare -a fan_speed_unc 						# Upper Non-Critical
declare -a fan_speed_ucr 						# Upper CRitical
declare -a fan_speed_unr 						# Upper Non-Recoverable

# fan speed trackers
declare -a fan_speed_limit_min					# minimum physical operating speed of each fan (key = fan header id) in RPMs
declare -a fan_speed_limit_max					# maximum physical operating speed of each fan (key = fan header id) in RPMs

# fan speed alert thresholds, by duty cycle
declare -a fan_speed_duty_low						# lowest expected RPM when duty cycle = low
declare -a fan_speed_duty_med						# lowest expected RPM when duty cycle = medium
declare -a fan_speed_duty_high					# lowest expected RPM when duty cycle = high
declare -a fan_speed_duty_max						# maximum allowed RPM when duty cycle = maximum (allowed)

##################################
# END GLOBAL VARIABLE DECLARATIONS
##################################
