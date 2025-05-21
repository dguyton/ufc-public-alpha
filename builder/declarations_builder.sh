# Universal Fan Controller (UFC)
# Builder program version 2.0
#
# variable declarations file for Builder
# filename: declarations_builder.sh
#
# DO NOT REMOVE LINE BELOW
# program_version="2.0"

########################################
# GLOBAL VARIABLE DECLARATIONS - BUILDER
########################################

##
# These variables need to be treated globally. In order to ensure this is the case,
# they are explicitly declared here. Forcing their declaration here ensures there
# are no mishaps related to the order of operation in which variables are declared,
# since the script may take different paths depending on user preferences defined
# in config file, and automated system discovery processes.
##

# basic program operation
declare server_id								# optional unique identifier of hardware device this program is being run on
declare service_name							# service program/daemon service name
declare builder_username							# name of user running Builder program executables
declare service_username							# username expected to run Service program executables
declare -l program_module						# which core program module is currently running (e.g., builder, launcher)

# motherboard info
declare -l mobo_manufacturer						# motherboard manufacturer; force lowercase to prevent errors in the script
declare -u mobo_model							# motherboard model, forced uppercase for consistency
declare mobo_gen								# motherboard generation/version/group

# manufacturer-specific motherboard metadata
declare idrac_generation							# generation of Dell iDRAC firmware
declare idrac_version							# Dell iDRAC firmware version number

# global fan management properties
declare -l bmc_command_schema						# IPMI raw fan modulation command schema
declare fan_control_method						# fan control capability of BMC
declare -A -u reserved_fan_name					# special fan placeholder mappings required for group fan control method

# IPMI write command ordering
declare -a ipmi_write_position_fan_id				# map sequential fan write position to fan ID for group method fan control; [write position] = fan id
declare -a ipmi_fan_id_write_position				# map fan ID to corresponding write position for direct fan control method; [fan id] = write position
declare -a -u ipmi_write_position_fan_name			# write position to fan name mappings for direct and group fan control methods; [write position] = fan name
declare -a -u ipmi_fan_write_order					# reference write order of fan header names based on BMC command schema
declare -a -l ipmi_group_fan_payload				# map fan ID to its pending duty cycle; [fan id] = pending duty cycle
declare ipmi_payload_byte_count					# number of bytes expected by IPMI in write command data payload

# number of ordinals per binary type
declare fan_zone_binary_length					# maximum number of fan zones
declare fan_header_binary_length					# maximum number of fan headers

# fan header binary trackers
declare -A fan_header_binary						# binary tracker of all existing, physically present fan header IDs
declare -A fan_header_active_binary				# binary tracker of all existing, physically present, active fan header IDs

# fan zone binary trackers
declare -A fan_zone_binary						# binary tracker of all existing, physically present fan zone IDs
declare -A fan_zone_active_binary					# binary list of active fan zone IDs

# CPU fan override flag
declare cpu_fan_override							# override byte required by some group fan management style BMC chips

# align each fan with its fan duty
declare -l duty_type							# fan duty category (functional group) placeholder
declare -a -l fan_duty_category					# array list of all valid fan duty categories (e.g. cpu, device, etc.)
declare -a -l fan_header_category					# an indexed array mapping fan id to associated fan duty cooling type (e.g. cpu, device, etc.)

# physical fan header trackers
declare -a -u fan_header_name						# array of fan header ID = name ( key = fan header id ; value = fan header name )
declare -A fan_header_id							# array of fan header name = ID ( key = fan header name ; value = fan header id )
declare -a fan_header_zone						# array of fan header ID = fan zone ( key = fan header id ; value = fan zone id )

# fan speed trackers
declare -a fan_header_speed						# current speed of each fan in RPMs (used by subroutine that gets current fan info)
declare -a fan_speed_limit_min					# minimum physical operating speed of each fan (key = fan header id) in RPMs
declare -a fan_speed_limit_max					# maximum physical operating speed of each fan (key = fan header id) in RPMs

# fan speed alert thresholds, by duty cycle
declare -a fan_speed_duty_low						# lowest expected RPM when duty cycle = low
declare -a fan_speed_duty_med						# lowest expected RPM when duty cycle = medium
declare -a fan_speed_duty_high					# lowest expected RPM when duty cycle = high
declare -a fan_speed_duty_max						# maximum allowed RPM when duty cycle = maximum (allowed)

# fan speed hysteresis
declare bmc_threshold_interval 					# multiple of BMC fan hysteresis

# low fan duty RPM calc offset
declare low_duty_cycle_offset						# percentage offset to apply when estimating low RPM fan speeds
declare low_duty_cycle_threshold					# below this fan duty level, adjust fan speed estimates to account for skewed raw fan speeds

# IPMI sensor data column positions (sensor long form)
declare -A ipmi_sensor_column_cpu					# various ipmitool cpu sensor output column locations; passed thru to Service program
declare -A ipmi_sensor_column_fan					# various ipmitool fan sensor output column locations

# IPMI sdr data column positions (sensor short form)
declare -A ipmi_sdr_column_cpu					# ipmitool sdr mode cpu related variables (carry-thru to service program)

# lm-sensors output data columns
declare -A ipmi_sensor_column_cpu_temp				# lm-sensors output cpu specific

# flag indicating all fan zones are treated as a single zone
declare -l only_cpu_fans							# true when there is only one fan zone or all fan zones are responsible for cooling CPU (true/false)

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
declare -A fan_duty_high							# duty cycle to set fans to when average temperature is >= high temp threshold
declare -A fan_duty_max							# duty cycle to set fans to when critical temperature threshold reached
declare -A fan_duty_start						# duty cycle to set fans on program start-up

# user-defined controls governing cpu temperature control and monitoring factors
declare -l cpu_temp_sensor						# cpu temperature sensor utility (e.g. sensors or ipmitool)
declare -l cpu_temp_method						# cpu temperature monitoring method (raw physical or core average)

# maximum fan duty limited by hardware or firmware
declare fan_duty_limit							# set via .conf files or config file

# logging (this program)
declare debug_level								# debug service level
declare -l log_to_syslog							# true when syslog can be written to via built-in logger program (true/false)
declare log_filename							# builder program current log filename
declare -l log_file_active						# true/false flag that determines when log_filename is validated and available for logging

# misc variable init
declare device_temp_reader 						# pointer to device temperature reading program
declare ipmitool 								# pointer to IPMI tool
declare key									# temporary variable

# timers
declare fan_speed_delay 							# minimum time in seconds between between fan speed adjustments and fan speed validation checks

# misc variable init
declare init_filename							# filename to store runtime settings; specified in config file

# disk device tracking
declare device_count 							# number of storage devices (auto-detected)
declare device_list								# newline delimited list of all disk device names (e.g. sda, sdb, etc.)

#################################################
# Critical program dir and file location trackers
#################################################

# source file directories
declare config_dir								# /source_dir_parent/config/
declare daemon_source_dir						# /source_dir_parent/daemon/
declare functions_source_dir						# /source_dir_parent/functions/
declare service_source_dir						# top level directory of all source files
declare service_launcher_source_dir				# Service Launcher source code directory
declare service_runtime_source_dir					# Service Runtime program top-level of source code directory tree

# executable source file locations
declare service_launcher_source_filename			# filename of source/master copy of Service Launcher program (set by inventory_service_program_files subroutine)
declare service_runtime_source_filename				# filename of source/master copy of Service Runtime program (set by inventory_service_program_files subroutine)
declare failure_handler_script_filename				# source filename of Service Failure Notification Handler universal program script

# include file sub-directories
declare functions_builder_source_dir				# /source_dir_parent/functions/builder/
declare functions_common_source_dir				# /source_dir_parent/functions/common/
declare functions_service_source_dir				# /source_dir_parent/functions/service/

# target file locations
declare service_launcher_declarations_target_filename	# pointer to file location of Service Launcher variable declarations file used by Service Launcher
declare service_runtime_declarations_target_filename	# pointer to file location of Runtime Launcher variable declarations file used by Runtime Launcher

declare service_launcher_manifest_target_filename		# pointer to file location of Service Launcher include file manifest validated by Service Launcher
declare service_runtime_manifest_target_filename		# pointer to file location of Service Runtime include file manifest validated by Service Launcher

# pre-existing installation target locations
declare target_dir_old							# pre-existing top level target Service program files operating directory
declare service_launcher_target_dir_old				# existing/incumbent Service Launcher program files operating directory
declare service_runtime_target_dir_old				# existing/incumbent Service Runtime program files operating directory
declare service_failure_handler_target_dir_old		# existing/incumbent Service Failure Notification Handler program files operating directory
declare service_functions_target_dir_old			# existing/incumbent Service program include files directory

# target directories
declare target_dir								# top level target service program operating directory /target_dir/
declare service_launcher_target_dir				# service launcher program operating directory /target_dir/launcher/
declare service_runtime_target_dir					# service runtime program operating directory /target_dir/runtime/
declare service_functions_target_dir				# /target_dir/functions/

# destination filenames when copying/creating new executables
declare service_launcher_target_filename			# full path to new Service Launcher executable /target_dir/launcher/{launcher_filename.sh}
declare service_runtime_target_filename				# target service runtime program full path filename /target_dir/runtime/{runtime_filename.sh}
declare service_failure_handler_target_filename		# full path to Failure Notification Handler SHell script called by FNH daemon service on Service program failure

# Service program global variable declarations source filenames
declare service_launcher_declarations_filename		# global declarations file required for service launcher program /source_dir/service/launcher/service_launcher_declarations.sh
declare service_runtime_declarations_filename		# global declarations file required for service runtime program /source_dir/service/runtime/service_runtime_declarations.sh

# Service program .init filenames
declare service_launcher_init_filename				# full path of Service Launcher .init file /target_dir/launcher/{service_name}.init
declare service_runtime_init_filename				# full path of Service Runtime .init file /target_dir/runtime/{service_name}.init

# Service manifest filenames
declare service_launcher_manifest_filename			# /source_dir_parent/config/manifest_service_launcher.info
declare service_runtime_manifest_filename			# /source_dir_parent/config/manifest_service_runtime.info

# primary log directories
declare service_log_dir							# service program log directory; default /target_dir/log/
declare service_log_test_file						# service program log test file for probing file system permissions access

# systemd service locations
declare daemon_service_dir						# directory path of systemd daemon .service files
declare daemon_service_dir_default					# user preference for daemon service directory specified in config file

declare launcher_daemon_service_dir				# directory of systemd Service Launcher .service file
declare runtime_daemon_service_dir					# directory of systemd Service Runtime .service file
declare service_failure_handler_target_dir			# directory of systemd Service Failure Handler Notification .service file

declare launcher_daemon_service_filename			# full filename path of Service Launcher systemd .service file
declare runtime_daemon_service_filename				# full filename path of Service Runtime systemd .service file
declare failure_handler_daemon_service_filename		# full path to Failure Notification Handler systemd daemon .service file

declare launcher_daemon_service_template			# full path to Service Launcher daemon .service template file
declare runtime_daemon_service_template				# full path to Service Runtime daemon .service template file
declare failure_handler_daemon_service_template		# full path to Failure Notification Handler daemon .service template file

# systemd service criteria
declare launcher_daemon_service_name				# daemon service name of systemd service associated with Service Launcher program
declare runtime_daemon_service_name				# daemon service name of systemd service associated with Service Runtime program
declare failure_handler_service_name				# daemon service name of systemd service associated with Service Failure Notification Handler

declare launcher_daemon_service_name_default			# default Service Launcher daemon service name, based on Service Name specified in config file
declare runtime_daemon_service_name_default			# default Service Runtime daemon service name, based on Service Name specified in config file
declare failure_handler_service_name_default			# default Service Failure Notification Handler daemon service name, based on Service Name specified in config file

declare -l launcher_daemon_service_state			# Service Launcher daemon service current operating state
declare -l runtime_daemon_service_state				# Service Runtime daemon service current operating state
declare -l failure_handler_daemon_service_state		# Service Failure Notification Handler daemon service current operating state
declare -l enable_failure_notification_service		# true/false flag to indicate whether or not the Failure Notification Handler daemon should be implemented (true) or not (false)

# user-defined controls governing cpu temperature control and monitoring factors
declare -l auto_detect_cpu_critical_temp			# automatically detect cpu temperature the manufacturer indicates is critical threshold with risk of damage to cpu (true/false)
declare -l auto_detect_cpu_high_temp				# automatically detect cpu temperature considered to be high by the cpu manufacturer (true/false)

# delay timers
declare daemon_init_delay						# delay in seconds between multi-plexed sysctl commands

# BMC threshold flags
declare -l auto_bmc_fan_thresholds 				# automatic BMC fan speed threshold calculation (true/false)
declare -l bmc_threshold_buffer_mode				# mode for managing proximity of upper BMC fan thresholds to their absolute limit

# operating modes
declare -l recycle_service_daemons					# operational flag relative to recycling pre-existing service files (true/false/null)

# motherboard info
declare manufacturer_config_dir					# motherboard manufacturer .conf file sub-directory
declare manufacturer_config_file					# motherboard manufacturer specific .conf filename
declare model_config_file						# motherboard model specific .conf filename

# logging
declare log_temp_hold							# temporary log storage while log file not yet created

# builder-only parameters
declare config_file								# filename the builder expects for the config filename (same dir, same basename)

##########################################
# GLOBAL VARIABLE DECLARATIONS - PASS-THRU
##########################################

##
# These variables are not needed by the Builder, but must be
# passed from the config file to one or more Service components.
# This is accomplished by passing these variables via the
# .init file created by the Builder, which gets passed to the
# Service Launcher program.
#
# These variables may also be utilized by Builder-specific
# functions (include files).
##

# program version trackers
declare service_program_version					# version number of new (target) service program
declare service_program_version_old				# existing/incumbent service launcher program version

# disk device temp monitors
declare device_avg_temp_target 					# mean of all current disk device temperatures
declare device_max_allowed_temp 					# trip panic mode when a disk device exceeds this temperature
declare -l include_ssd							# include SSDs as disk devices when true

# email alerts
declare -l email_alerts							# status flag which determines whether or not to send alert emails when warranted
declare email									# email address to which alert emails will be sent (the "To" address)

# Service program pass-thru log-related variables
declare -l log_json_export						# JSON log file export preference
declare log_hourly_alignment						# indicates whether or not new runtime program logs should be started on the hour
declare log_hourly_interval						# number of hours between posted log summaries
declare log_age_max								# maximum age in days of oldest program log file
declare log_json_interval						# time interval in seconds between JSON metadata file dumps by runtime program
declare log_json_age_max							# maximum age in days of oldest JSON metadata log file

# PID vars
declare pid_Kp 								# proportional Constant
declare pid_Ki 								# Integral Constant
declare pid_Kd 								# Derivative Constant

# fan timers
declare fan_validation_delay						# base delay (in seconds) between fan header operation checks
declare cpu_fan_validation_delay					# calculated delay between CPU fans validation against current duty setting
declare device_fan_validation_delay				# calculated delay between disk device fans validation against current duty setting
declare suspicious_fan_validation_delay 			# time buffer (in seconds) between fan speed validation checks
declare all_fan_validation_delay					# calculated delay between validation of all fans regardless of fan duty category or status

declare next_cpu_fan_validation_time				# next timestamp to validate cpu fans (based on cpu_fan_validation_delay timer)
declare next_device_fan_validation_time				# next timestamp to validate disk device fans (based on device_fan_validation_delay timer)
declare next_fan_validation_time					# next timestamp to validate all fans (based on all_fan_validation_delay timer)

# temperature check timers
declare cpu_temp_polling_interval					# interval in seconds between cpu temperature checks (default = 2 seconds)
declare device_temp_polling_interval	 			# interval in seconds between disk device temperature checks
declare device_polling_interval					# interval between device inventory polls by Service Runtime program

# monitoring mean temperature of all cpus combined
declare cpu_temp_rolling_average_limit				# number of averages to use in calculating rolling average of cpu temps over time

# suspicious fan tracker
declare -a suspicious_fan_list					# array of fan headers flagged for suspicious behavior (pending exclusion)

# cpu rpm vars
declare -A fan_speed_min							# universal, minimum operating speed in RPM of CPU fans
declare -A fan_speed_lowest_max					# lowest maximum operating speed in RPM of all CPU fans (i.e. top speed of slowest CPU fan)

# BMC managed fan speed thresholds
declare -a fan_speed_lnr 						# Lower Non-Recoverable RPM array ( key = fan header id )
declare -a fan_speed_lcr 						# Lower CRitical
declare -a fan_speed_lnc 						# Lower Non-Critical
declare -a fan_speed_unc 						# Upper Non-Critical
declare -a fan_speed_ucr 						# Upper CRitical
declare -a fan_speed_unr 						# Upper Non-Recoverable

##
# Below are imported from .config file or motherboard manufacturer/model .conf files
##

# motherboard fan group schema management
declare -A fan_group_category						# from config file; array of fan header and fan group schema labels; defined in .config file; maps index names to fan cooling types
declare -a fan_group_schema						# array of fan groups and list of associated fan headers on current motherboard
declare -a -l fan_group_label						# array of labels associated with each fan group, force lowercase for consistency
declare cpu_fan_group 							# names of fan headers or fan zone IDs tagged in .config file as responsible for cpu cooling

# below may be specified in .config file, or .conf files, or both
declare -l cpu_fan_control 						# determines whether or not the program responds to changes in CPU temperatures (true/false)

##################################
# END GLOBAL VARIABLE DECLARATIONS
##################################
