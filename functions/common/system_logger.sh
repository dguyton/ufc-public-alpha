##
# Report messages to system log
#
# No syslog recording when user preference indicates.
# Force syslog entry when program log not available.
##

function system_logger ()
{
	[ "$log_to_syslog" != true ] && return

	if [ -n "$service_name" ]; then # 1/
		logger -t "$service_name" "$1"
	else # 1/ default service name
		logger -t "universal-fan-controller" "$1"
	fi # 1/
}
