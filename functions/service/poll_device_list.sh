##
# Get list of all hard drives. Non-disk devices and SSDs are excluded (ignored).
# $device_list is global so that changes in active disk devices can be detected.
#
# Monitor for changes in the list of active disk devices. Changes may occur due
# to failed disks or when hot-swap disks are added or removed.
#
# This program does not alert users to specific disk issues. It merely monitors
# the number of disks available. This information is very important because it
# directly impacts the mean temperature calculations, which in turn are critical
# to correct disk device fan cooling management.
#
# Note that currently, SSDs are ignored, as the program is optimized for HDDs.
##

function poll_device_list ()
{
	debug_print 4 "Refresh disk device list"

	device_list_old="$device_list"

	if [ "$include_ssd" = true ]; then # 1/ include SSDs
		device_list="$(lsblk --scsi | grep disk | cut -c 1-3)" # new line delimited list stored as string
	else # 1/
		device_list="$(lsblk --scsi | grep disk | grep -iv 'solid.state' | cut -c 1-3)" # exclude SSD disks
	fi # 1/

	# if device list changed, re-calibrate device name array and print a new log header
	if [ "$device_list" != "$device_list_old" ]; then # 1/ use latest device id list when old list is outdated
		[ -n "$device_list_old" ] && debug_print 1 warn "Disk device list changed... re-calibrating device list." # mention in log when not 1st run
		unset device_temp # reset global drive temperature array since list of devices changed

		# count number of disk devices (default = 0)
		device_count=$(printf "%s" "$device_list" | wc -l) # re-count number of disk devices

		# send email alert if warranted
		send_email_alert "A change in disk devices was detected. There are now $device_count disk devices present." false false

		if (( device_count == 0 )); then # 2/ no disk storage devices found
			only_cpu_fans=true
			debug_print 1 "All fan headers will be treated as CPU cooling fans because no disk devices are detected"
			return
		fi # 2/

		debug_print 1 "Detected $device_count disk device(s)"
		[ "$only_cpu_fans" = true ] && debug_print 1 caution "One or more disk devices were found, yet program configuration requires all fans dedicated to CPU cooling only"

		read -ra device_list_array <<< "$device_list" # parse list of drives into global array
		[ -n "$device_list_old" ] && print_log_summary # re-print device header in the log when not first device list poll
	fi # 1/
}
