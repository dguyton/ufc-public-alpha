##
# Print something to the (human-readable) server log, provided
# the log message meets or exceeds the designated runtime debug
# level setting.
#
# Acceptable patterns:
#
# {debug_level} {message}
# {debug_level} {message} {trace}
#
# {debug_level} {alert} {message}
# {debug_level} {alert} {message} {trace}
##

function debug_print ()
{
	local alert			# alert type
	local level			# debug level assigned to message
	local message			# message payload
	local trace			# when true, include trace info in log

	level="$1" # first input must always be debug level associated with the debug message ($2)
	level="$(printf "%.0f" "${level//[!0-9]/}")" # numeric only, defaults to 0 (zero)

	(( level == 0 )) && return 1 # invalid debug level

	trace=false # default

	# filter var parsing based on number of arguments
	case $# in # 1/

		1) 
			return 1 # too few arguments
		;;

		2)
			# expected input: {level} {message}
			message="$2"
		;;

		##
		# When an alert status is included with the debug message, it pushes the
		# message content from arg $2 to arg $3.
		#
		# When arg $3 is true or false, it must be trace flag, meaning there is
		# no alert arg.
		##

		*)
			case "$2" in # 2/
				bold|caution|critical|warn)
					# {debug_level} {alert} {message}
					# {debug_level} {alert} {message} {trace}
					alert="$2"
					message="$3"
					trace="$4"
				;;

				*)
					# {debug_level} {message} {trace}
					message="$2"
					trace="$3"
				;;
			esac # 2/
		;;
	esac # 1/

	# default trace flag to false when not defined
	trace="${trace:-false}"

	# debug level less than level threshold and debug trace flag not set
	{ (( debug_level < level )) && [ "$trace" != true ]; } && return 0

	[ -z "$message" ] && return 1 # empty message content

	# append debug trace info when requested
	[ "$trace" = true ] && command -v trace_debug &>/dev/null && message+="$(printf "\n%s" "$(trace_debug)")"

	##
	# When logging to a file, build the log entry including time/datestamp prefix,
	# special character highlighting when requested, and append trace debug info
	# when requested.
	##

	if [ "$log_file_active" = true ]; then # 1/ append debug message to log file
		{
			command -v build_date_time_string &>/dev/null && printf "%s " "$(build_date_time_string)"

			case "$alert" in # 1/
				caution|critical)
					printf "%s: " "${alert^^}"
				;;

				warn|warning)
					printf "WARNING: "
				;;
			esac # 1/

			printf "%s\n" "$message"
		} &>> "$log_filename"
	else # 1/ post message to syslog
		send_to_syslog "$message"
	fi # 1/

	return 0
}
