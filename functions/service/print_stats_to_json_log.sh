##
# Create new JSON metadata log and print current stats to it
#
# Write metadata to a new JSON data log (different from human-readable log).
# Creates a new log file every time this sub is run.
#
# NOTE: A lot of files will be created when this feature is active!
##

function print_stats_to_json_log ()
{
	local counter
	local core
	local core_temp
	local cpu_id 			# numeric id of physical cpu currently being examined
	local device_name
	local fan_id
	local flag 			# temporary state flag
	local json_log

	local -a fan_array

	get_fan_info all quiet false # force fan status updates before data export

	{
		printf "[\n"
		printf "\t{\n"
		printf "\t\t\"epoch_timestamp\" : \"%s\",\n" "$check_time"
		printf "\t\t\"date_time_stamp\" : \"%s\",\n" "$(build_date_time_string)"
		printf "\t\t\"cpu_count\" : %d,\n" $((numcpu))
		printf "\t\t\"cpu_temp_current_average\" : %d,\n" $((cpu_temp_average))
		printf "\t\t\"cpu_temp_rolling_average\" : %d,\n" $((cpu_temp_rolling_average))
		printf "\t\t\"num_drives\" : %d,\n" $((device_count))
		printf "\t\t\"drive_average_temperature\" : %d,\n" $((device_avg_temp))
		printf "\t\t\"drive_average_target\" : %d,\n" $((device_avg_temp_target))
		printf "\t\t\"drive_fan_duty\" : %d,\n" $((device_fan_duty))

		if [ "$only_cpu_fans" != true ]; then # 1/
			if [ -n "$device_fan_duty_pid" ]; then # 2/
				printf "\t\t\"drive_fan_duty_pid\" : \"%s\"\n" "$device_fan_duty_pid"
			else # 2/
				printf "\t\t\"drive_fan_duty_pid\" : 0\n"
			fi # 2/

			printf "\t\t\"P\" : \"%s\",\n" "$pid_P"
			printf "\t\t\"I\" : \"%s\",\n" "$pid_I"
			printf "\t\t\"D\" : \"%s\",\n" "$pid_D"
		fi # 1/

		printf "\t},\n\n"
	} >> "$json_log"

	# export cpu stats
	{
		printf "\t{\n"
		printf "\t\t\"cpu_info\" :\n"
		printf "\t\t[\n"
	} >> "$json_log"

	##
	# cpu id records begin with 1
	# cpu actual ids begin with 0
	##

	for (( cpu_id=1; cpu_id<=numcpu; cpu_id++)); do # 1/

		{
			printf "\t\t\t{\n"
			printf "\t\t\t\t\"cpu_id\" : %d,\n" $((cpu_id-1))
			printf "\t\t\t\t\"cpu_temp\" : %d" $((cpu_temp[cpu_id]))
		} >> "$json_log"

		if [ "$cpu_temp_method" = "core" ]; then # 1/
			{
				printf ",\n" >> "$json_log"
				printf "\t\t\t\t\"lowest_core_temp\" : %d,\n" $((cpu_core_temp_lowest[cpu_id]))
				printf "\t\t\t\t\"highest_core_temp\" : %d" $((cpu_core_temp_highest[cpu_id]))
			} >> "$json_log"

			# export cpu cores
			if (( ${#cpu_core_temp[@]} > 0 )); then # 2/ confirm core temp data exists before creating construct

				{
					printf ",\n"
					printf "\t\t\t\t\"cpu_core_temps\" :\n"
					printf "\t\t\t\t[\n"
				} >> "$json_log"

				unset flag

				for core in "${!cpu_core_temp[@]}"; do # 2/ loop by array element id (index)
					if (( ${core%%:*} == cpu_id )); then # 3/ current array element belongs to current cpu id
						if [ "$flag" = true ]; then # 4/ another JSON array element precedes this one
							printf ",\n" >> "$json_log" # append end of previous array element
							unset flag
						fi # 4/

						core_id="${core##*:}" # extract core number from array index key

						# store core number and corresponding core temperature)
						{
							printf "\t\t\t\t\t{\n"
							printf "\t\t\t\t\t\t\"cpu_core_id\" : %d,\n" $((core_id))
							printf "\t\t\t\t\t\t\"core_temp\" : %d\n" $((cpu_core_temp["$core"]))
							printf "\t\t\t\t\t}"
						} >> "$json_log"

						flag=true
					fi # 3/
				done # 2/ core_id

				{
					printf "\n"
					printf "\t\t\t\t]\n"
				} >> "$json_log"
			fi # 2/

			if (( cpu_id < numcpu )); then # 2/ not the last one
				printf "\n\t\t\t},\n\n" >> "$json_log"
			else # 2/ last one = no comma
				printf "\n\t\t\t}\n" >> "$json_log"
			fi # 2/
		else # 1/ not in 'core' mode
			if (( cpu_id < numcpu )); then # 2/ not the last one
				printf "\n\t\t\t},\n\n" >> "$json_log"
			else # 2/
				printf "\n\t\t\t}\n" >> "$json_log"
			fi # 2/
		fi # 1/
	done # 1/ cpu_id

	printf "\t\t]\n\t},\n\n" >> "$json_log"

	# export drive temps
	counter=$((device_count)) # number of active disk devices
	if (( counter > 0 )); then # 1/ must have data for at least 1 device

		{
			printf "\t{\n"
			printf "\t\t\"device_info\" :\n"
			printf "\t\t[\n"
		} >> "$json_log"

		for device_name in "${!device_list[@]}"; do # 1/
			((counter--)) # remaining devices to report

			{
				printf "\t\t\t{\n"
				printf "\t\t\t\t\"device_name\" : \"%s\",\n" "${device_list[$device_name]}"
				printf "\t\t\t\t\"temperature\" : %d\n" $((device_temp[device_name]))
				printf "\t\t\t}"
			} >> "$json_log"

			if (( counter > 0 )); then # 3/ not the last one
				printf ",\n\n" >> "$json_log"
			else # 3/ last one = no comma and close out JSON array
				printf "\n\t\t]\n" >> "$json_log"
			fi # 3/
		done # 1/
		printf "\t},\n\n" >> "$json_log"
	fi # 1/

	# export fan header info
	{
		printf "\t{\n"
		printf "\t\t\"fan_header\" :\n"
		printf "\t\t[\n"
	} >> "$json_log"

	count_active_ordinals_in_binary "fan_header_binary" "master" "counter" # total number of fan headers
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array" # parse all fan headers regardless of state

	for fan_id in "${!fan_array[@]}"; do # 1/ process each fan header
		((counter--)) # remaining devices

		{
			printf "\t\t\t{\n"
			printf "\t\t\t\t\"fan_header_id\" : \"%s\",\n" "$fan_id"
			printf "\t\t\t\t\"fan_header_name\" : \"%s\",\n" "${fan_header_name[$fan_id]}"

			[ "$fan_control_method" = "zone" ] && printf "\t\t\t\t\"fan_header_zone\" : \"%s\",\n" "${fan_header_zone[$fan_id]}"

			printf "\t\t\t\t\"fan_header_status\" : \"%s\",\n" "${fan_header_status[$fan_id]}"
			printf "\t\t\t\t\"fan_header_speed\" : %d\n" $((fan_header_speed[fan_id]))
			printf "\t\t\t}"
		} >> "$json_log"

		# get the JSON syntax correct
		if (( counter > 0 )); then # 1/ not the last one
			printf ",\n\n" >> "$json_log"
		else # 1/ last one
			printf "\n\t\t]\n" >> "$json_log"
		fi # 1/
	done # 1/

	printf "\t}\n]\n" >> "$json_log" # end of JSON data stream
}
