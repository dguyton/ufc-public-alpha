##
# Validate email address format.
#
# Regular expression matching. The regex:
#
# ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
#
# Checks:
#
# 1. Local Part: One or more letters, digits, or allowed symbols (._%+-)
# 2. At-Symbol (@): Separates local part from the domain
# 3. Domain: One or more letters, digits, or allowed symbols (.-)
# 4. Top-Level Domain (TLD): at least two letters

function validate_email ()
{
	# check if an argument was provided.
	[ -z "$email" ] && return 1

	# basic email regex: alphanumerics and allowed symbols, an '@', a domain name and a top-level domain.
	if echo "$email" | grep -E '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' > /dev/null; then # 1/
		return 0 # email addr ok
	else # 1/
		return 1
	fi # 1/
}
