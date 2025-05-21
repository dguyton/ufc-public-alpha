##
# Convert name of file system permissions abbreviation
# as a magic number. Return converted magic number to
# caller. Return null when an error occurs or no match
# found for specified permissions abbreviation.
##

function convert_perms_to_level ()
{
	local level
	local permissions

	permissions="$1"

	case "$permissions" in # 1/

		PERM_TRAVERSE)
			level=1
			;;
		
		PERM_WRITE_ONLY)
			level=2
			;;

		PERM_WRITE_TRAVERSE)
			level=3
			;;

		PERM_READ_ONLY)
			level=4
			;;

		PERM_READ_TRAVERSE)
			level=5
			;;

		PERM_READ_WRITE)
			level=6
			;;

		PERM_ALL)
			level=7
			;;

		*)
			# presume input is integer
			level="$permissions"
			;;

	esac # 1/

 	# bad input (contains non-numeric characters or integers out of range)
	[ -n "${level//[0-7]/}" ] && return 1

	# return numeric permissions level
	printf "%d" $((level))
}
