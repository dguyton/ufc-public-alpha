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
	! refresh_failure_handler_daemon && return 1
}
