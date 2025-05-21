##
# Print snapshot of cpu and disk temps and fan status to log file.
# --> current PID fan duty cycle values
# --> disk temps average (aggregate)
# --> last/previous average temp
# --> difference between current/last average temps
# --> temperature trend (increasing, decreasing, or neither)
# --> lowest current disk temp of all disks
# --> highest current disk temp of all disks
#
# notes on how to color some text red or green to highlight trend
# warning: printf character spacing (e.g. %5s) counts number of bytes in the string, not number of characters
# (( delta > 0 )) && trend="$(printf "\e[31minc\e[0m")"
# (( delta < 0 )) && trend="$(printf "\e[32mdec\e[0m")"
# printf "\nAvg   Last   Diff   Trend   Low   High\n%3s%4s%-3d%4s%-3s%4s%3s%4s%3d%3s%3d\n\n" $((device_avg_temp)) " " $((device_avg_temp_last)) " " "$((( device_avg_temp_delta > 0 )) && printf "+" )$((device_avg_temp_delta))" " " "$trend" " " $((device_lowest_temp)) " " $((device_highest_temp))
# printf "\nAvg   Last   Diff   Trend   Low   High\n%-3s%6d%7s%17s%7d%6d\n\n" "$((( device_avg_temp > device_avg_temp_target )) && printf " \e[31m$device_avg_temp\e[0m" || printf " $device_avg_temp")"$((device_avg_temp_last)) "$((( device_avg_temp_delta > 0 )) && printf "+" )$((device_avg_temp_delta))" "$trend" $((device_lowest_temp)) $((device_highest_temp))
# printf "\nAvg   Last   Diff   Trend   Low   High\n%3s%4s%-3d%4s%-3s%4s%3s%4s%3d%3s%3d\n\n" "$((( device_avg_temp > device_avg_temp_target )) && printf "\e[31m$device_avg_temp\e[0m" || printf "$device_avg_temp")" " " $((device_avg_temp_last)) " " "$((( device_avg_temp_delta > 0 )) && printf "+" )$((device_avg_temp_delta))" " " "$trend" " " $((device_lowest_temp)) " " $((device_highest_temp))
# printf "\nAvg   Last   Diff   Trend   Low   High\n%3s%4s%-3d%4s%-3s%4s%3s%4s%3d%3s%3d\n\n" "$((( device_avg_temp > device_avg_temp_target )) && printf " \e[31m$device_avg_temp\e[0m" || printf " $device_avg_temp")" " " $((device_avg_temp_last)) " " "$((( device_avg_temp_delta > 0 )) && printf "+" )$((device_avg_temp_delta))" " " "$trend" " " $((device_lowest_temp)) " " $((device_highest_temp))
##

function print_log_summary ()
{
	{ (( debug_level < 1 )) || [ -z "$log_filename" ] || [ "$log_file_active" != true ]; } && return

	local core
	local core_id
	local core_temp
	local cpu_id 		# numeric id of physical cpu currently being examined
	local datestring
	local delta
	local device_name
	local device_name_short
	local duty
	local fan_category
	local fan_id
	local fan_name
	local level
	local speed
	local status
	local timestring
	local trend
	local zone_id

	# log header
	printf "Service Runtime program log\n" >> "$log_filename"
	[ -n "$service_program_version" ] && printf "version: %s\n\n" "$service_program_version" >> "$log_filename"

	datestring="$(build_date_string)" # YYYY-MMM-DD
	timestring="$(build_time_string)" # HH:MM:SS

	trend=$(compute_trend $(( device_avg_temp_delta - device_avg_temp_delta_last )))

	# high level summary of all disk averages
	{
		if [ "$cpu_temp_method" = "core" ]; then # 1/
			printf "\n---------------------------- begin summary report -----------------------------\n" >> "$log_filename"
		else # 1/
			printf "\n------------------------ begin summary report -----------------------\n" >> "$log_filename"
		fi # 1/

		printf "\n%s %s\n\n" "$datestring" "$timestring"

		printf "Universal Fan Controller Log\n\n"
		printf "  ---  Average Disk Temperature = %2d deg C\n" $((device_avg_temp))
		printf "  ---  Target Disk Temperature  = %2d deg C\n" "$device_avg_temp_target"
		printf "  ---  PID Control Gains: pid_Kp = %6.3f | pid_Ki = %6.3f | pid_Kd = %5.1f\n" "$pid_Kp" "$pid_Ki" "$pid_Kd"

		printf "\nDisk Device Temperature Summary (all Devices)"
		printf "\n----------------------------------------------------------------"
		printf "\n|  Curr Avg  |  Last Avg  |  Delta  |  Trend  |  Low  |  High  |"
		printf "\n|    %3d     |    %3d     |   $( (( device_avg_temp_delta > 0 )) && printf "+" )%3s   |   %3s   |  %3d  |  %3d   |" $((device_avg_temp)) $((device_avg_temp_last)) $((device_avg_temp_delta)) "$trend" $((device_lowest_temp)) $((device_highest_temp))
		printf "\n----------------------------------------------------------------\n"
	} >> "$log_filename"

	# every physical drive state
	{
		printf "\nDisk Device Current Temps:"
		printf "\n------------------------------------------------\n"
		printf "|  Device  |  Temp  |  Trend  |  Low  |  High  |\n"
		printf "|----------------------------------------------|"
	} >> "$log_filename"

	for device_name in "${device_list_array[@]}"; do # 1/ parse current list of all disk devices
		(( device_temp_last["$device_name"] == 0 )) && device_temp_last["$device_name"]=$((device_temp["$device_name"]))

		trend=$(compute_trend $(( device_temp["$device_name"] - device_temp_last["$device_name"] )))

		(( ${#device_name} < 10 )) && device_name_short="$(printf "$device_name%$(((10-${#device_name})/2))s" " ")" # pad device name to keep display spacing consistent

		printf "\n|%10s|  %3d   |   %3s   |  %3d  |  %3d   |" "$device_name_short" $((device_temp["$device_name"])) "$trend" $((device_temp_low["$device_name"])) $((device_temp_high["$device_name"])) >> "$log_filename"
	done # 1/

	# footer of previous chart
	printf "\n------------------------------------------------\n\n" >> "$log_filename"

	##
	# fan header metadata
	##

	# header of fan headers chart
	if [ "$fan_control_method" = "zone" ]; then # 1/
		{
			printf "Fan Header States:"
			printf "\n--------------------------------------------------------------------------------\n"
			printf "| Fan ID |   Fan Name  |  Status  |  RPM  | Fan %% |  Level |   Duty   | Zone ID |"
			printf "\n--------------------------------------------------------------------------------"
		} >> "$log_filename"
	else # 1/ not zoned
		{
			printf "Fan Header States:"
			printf "\n----------------------------------------------------------------------\n"
			printf "| Fan ID |   Fan Name  |  Status  |  RPM  | Fan %% |  Level |   Duty   |"
			printf "\n----------------------------------------------------------------------"
		} >> "$log_filename"
	fi # 1/

	# report details of each existing fan header
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array" # report all fan headers
	for fan_id in "${!fan_array[@]}"; do # 1/ process each fan header

		duty="------"
		level="????"
		fan_category="------"
		speed="-----"

		fan_name="${fan_header_name[$fan_id]}"
		status="${fan_header_status[$fan_id]}"
		[ -n "${fan_header_category[$fan_id]}" ] && fan_category="${fan_header_category[$fan_id]}"
		[ -n "${fan_header_speed[$fan_id]}" ] && speed="${fan_header_speed[$fan_id]}"
		zone_id="${fan_header_zone[$fan_id]}"

		[ -n "$fan_category" ] && duty=$(( ${fan_category}_fan_duty ))

		convert_fan_duty_to_fan_level "level" "$fan_category"

		# beautify text formatting
		(( ${#fan_name} < 11 )) && fan_name="$(printf "$fan_name%$(((11-${#fan_name})/2))s" " ")"
		(( ${#status} < 8 )) && status="$(printf "$status%$(((8-${#status})/2))s" " ")"
		(( ${#speed} < 5 )) && speed="$(printf "$speed%$(((5-${#speed})/2))s" " ")"
		(( ${#level} < 6 )) && level="$(printf "$level%$(((6-${#level})/2))s" " ")"
		(( ${#fan_category} < 6 )) && fan_category="$(printf "$fan_category%$(((6-${#fan_category})/2))s" " ")"

		# print next row in the chart
		if [ "$fan_control_method" = "zone" ]; then # 1/
			(( ${#zone_id} < 2 )) && zone_id="$(printf "$zone_id%$(((2-${#zone_id})/2))s" " ")"
			printf "\n|   %2d   | %11s | %8s | %5s |  %6s  | %6s | %6s |   %2d    |" "$fan_id" "$fan_name" "$status" "$speed" "$duty" "$level" "$fan_category" "$zone_id" >> "$log_filename"
		else # 1/
			printf "\n|   %2d   | %11s | %8s | %5s |  %6s  | %6s | %6s |" "$fan_id" "$fan_name" "$status" "$speed" "$duty" "$level" "$fan_category" >> "$log_filename"
		fi # 1/
	done # 1/

	if [ "$fan_control_method" = "zone" ]; then # 1/
		printf "\n---------------------------------------------------------------------------------\n\n" >> "$log_filename" # chart footer
	else # 1/
		printf "\n-----------------------------------------------------------------------\n\n" >> "$log_filename"
	fi # 1/

	##
	# cpu temperature charts
	##

	trend=$(compute_trend $(( cpu_temp_average[1] - cpu_temp_average[-1] )))

	{
		printf "CPU temperatures:"
		printf "\n-----------------------------------\n"
		printf "| CPU ID |  Temp  |  Avg  | Trend |"
		printf "\n-----------------------------------"
		printf "\n|   all  |  %3d   |  %3d  |  %3s  |" $((cpu_temp_average[1])) $((cpu_temp_rolling_average)) "$trend"
	} >> "$log_filename"



	for cpu_id in "${!cpu_temp}"; do # 1/ cpu ids may start with 0 or 1
		if [ -n "${cpu_temp[$cpu_id]}" ] && [ -n "${cpu_temp_last[$cpu_id]}" ]; then # 1/
			trend=$(compute_trend $(( cpu_temp[$cpu_id] - cpu_temp_last[$cpu_id] )))
			printf "\n|   %2d   |  %3d   |  %3d  |  %3s  |" $((cpu_id)) $((cpu_temp[$cpu_id])) $((cpu_temp_last[$cpu_id])) "$trend" >> "$log_filename"
		fi # 1/
	done # 1/

	printf "\n-----------------------------------\n" >> "$log_filename"

	# cpu cores
	if [ "$cpu_temp_method" = "core" ]; then # 1/

		# print high-level core stats
		{
			printf "\nCPU core range:"
			printf "\n------------------------------\n"
			printf "|        |  Core Temp Range  |\n"
			printf "| CPU ID | Lowest |  Highest |"
			printf "\n------------------------------"
		} >> "$log_filename"

		for cpu_id in "${!cpu_temp}"; do # 1/
			printf "\n|  %2d    |   %3d   |   %3d   |" $((cpu_id)) $((cpu_core_temp_lowest[$cpu_id])) $((cpu_core_temp_highest[$cpu_id])) >> "$log_filename"
		done # 1/

		printf "\n------------------------------\n" >> "$log_filename"

		# print individual core stats
		printf "\nCPU core detail:" >> "$log_filename"

		for cpu_id in "${!cpu_temp}"; do # 1/

			{
				printf "\n-------------------------\n"
				printf "| CPU |  Core  |  Temp  |"
				printf "\n-------------------------"
			} >> "$log_filename"

			for core in "${!cpu_core_temp[@]}"; do # 2/ loop by array element id (index)
				if (( ${core%%:*} == cpu_id )); then # 2/ current array element belongs to current cpu id
					core_temp="${cpu_core_temp[$core]}" # element value (core temperature)
					core_id="${core##*:}" # extract core number
					printf "\n| %2d  |   %2d   |  %3d   |" $((cpu_id)) $((core_id)) $((core_temp)) >> "$log_filename"
				fi # 2/
			done # 2/
			printf "\n-------------------------\n" >> "$log_filename"
		done # 1/
	fi # 1/

	# the end
	if [ "$cpu_temp_method" = "core" ]; then # 1/
		printf "\n------------------------------ end summary report -------------------------------\n\n" >> "$log_filename"
	else # 1/
		printf "\n-------------------------- end summary report -------------------------\n\n" >> "$log_filename"
	fi # 1/
}
