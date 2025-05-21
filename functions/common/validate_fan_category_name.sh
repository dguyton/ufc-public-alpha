# determine whether or not input value matches a fan duty category name
function validate_fan_category_name ()
{
	local category_name
	local target

	target="$1" # input is potential fan duty category name to be validated

	# input validation
	if [ -z "$target" ]; then # 1/
		debug_print 2 warn "Cannot evaluate fan duty category name (\$1) because input is empty" true
		return 1
	fi # 1/

	for category_name in "${fan_duty_category[@]}"; do # 1/ does target match a known fan duty category name?
		[ "$target" = "$category_name" ] && return 0 # yes
	done # 1/

	return 1 # no
}
