##
# Convert first letter found in a string to a number representing
# its position in the alphabet.
#
# This sub is used by fan write-ordering sub to determine rank of
# fan header names with incremental position values expressed as
# letters instead of numbers.
##

function convert_alpha_to_position ()
{
	local alphabet
	local input
	local letter
	local -A position

	input="$1"
	input="${input//[!a-zA-Z]/}" # strip non-alpha chars
	input="${input:0:1}" # first letter only

	alphabet=({a..z})

	for (( i=0; i<${#alphabet[*]}; ++i )); do # 1/
		position[${alphabet[i]}]=$i
	done # 1/

	letter="$(printf "%s" "$input" | tr '[:upper:]' '[:lower:]')"
	printf "%s" $(( position[$letter] + 1 ))
}
