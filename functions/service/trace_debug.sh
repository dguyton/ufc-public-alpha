# print call chain from point of failure back to main script
function trace_debug() {

	local datetimestring="$1"
	local pop
	local stack_size="${#FUNCNAME[@]}"

	datetimestring="$1"
	stack_size="${#FUNCNAME[@]}"

	printf "\n===== Debug Trace Start =====\n"

	if (( stack_size == 1 )); then # 1/ trace_debug was called directly from the main script (global context)
		printf "%sLast executed line in main script: %s\n" "${datetimestring:+$datetimestring }" "N/A"
	else # 1/

		##
		# Loop from pop=1 (the immediate caller of trace_debug) to the bottom of the call stack.
		# For pop from 1 to (stack_size - 2), print the function call info.
		# The last element (pop == stack_size - 1) represents the call site in the main script.
		##

		for (( pop = 1; pop < stack_size; pop++ )); do # 1/
			if (( pop < stack_size - 1 )); then # 2/
				printf "%sfunction '%s' called by '%s' at line %s\n" "${datetimestring:+$datetimestring }" "${FUNCNAME[pop]}" "${FUNCNAME[pop+1]}" "${BASH_LINENO[pop]}"
			else # 2/ the bottom frame: print the last executed line in the main script.
				printf "%sLast executed line in main script: %s\n" "${datetimestring:+$datetimestring }" "${BASH_LINENO[pop-1]}"
			fi # 2/
		done # 1/
	fi # 1/

	printf "===== Debug Trace End =====\n\n"
}
