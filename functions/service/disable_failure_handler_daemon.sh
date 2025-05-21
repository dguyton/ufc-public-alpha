##
# Disable Failure Notification Handler (FNH) daemon service functionality.
#
# Adjusts FNH daemon pass-thru environmental variables.
#
# Functionally disables the FNH daemon by disabling environmental
# variables that execute triggers in its program script.
#
# This generally needs to happen for only brief periods of
# time when the Service program is going through some sort
# of transition. Examples of when this behavior should occur:
#
# --> Transitioning from Service Launcher to Runtime programs,
# before the latter has had time to initialize its log file.
# --> Exiting Service Runtime program to restart the server.
# --> Graceful exit of either Service program for any reason.
##

function disable_failure_handler_daemon ()
{
	# skip when FNH service not utilized
	[ "$enable_failure_notification_service" != true ] && return

	# disable email address line (this ensures FNH daemon will do nothing and exit immediately when triggered)
	sed -i 's%^\s*#\?\s*Environment="email=.*%# Environment="email="%I' "$failure_handler_daemon_service_filename"
}
