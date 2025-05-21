# append legend of human-readable program exit code reasons to program log
function print_exit_code_legend ()
{
	local position

	{
		printf "\n----------------------------------------------------------------\n"
		printf "Exit Code Legend:\n"

		for ((position=1; position<${#exit_code[@]}; position++)); do # 1/
			[ -n "${exit_code[$position]}" ] && printf "\t%d: %s\n" "$position" "${exit_code[$position]}"
		done # 1/

		printf "\n----------------------------------------------------------------\n"
	} >> "$log_filename"
}
