# validate include file manifests
function validate_service_file_manifest ()
{
	local common_dir				# shared (common) include files dir
	local file_error				# not null when an error occurs
	local filename					# current filename being evaluated
	local manifest_directory
	local manufacturer_sub_dir		# manufacturer-specific include files dir
	local parent_dir				# when not null, inspect specified manifest dir
	local service_manifest_var_name	# Service manifest filename
	local service_type

	service_type="$1"				# Service program type (Launcher | Runtime) [required]
	manifest_directory="$2"			# directory to scan for manifest file [required]
	parent_dir="$3"				# top-level functions dir name [required]
	common_dir="$4"				# common functions dir name [optional]
	manufacturer_sub_dir="$5"		# manufacturer sub-directory name [optional]

	##
	# Service manifest var name should be a literal string here. When it passed on to
	# the match_file_version, the latter function will indirectly reference the indicated
	# var name and populate it with its result.
	##

	if [ -z "$service_type" ]; then # 1/
		debug_print 2 warn "Service type not specified" true
		return 1 # failure
	fi # 1/

	# normalize display of service type in the program log
	service_type="${service_type^}"

	if [ -z "$manifest_directory" ]; then # 1/
		debug_print 2 warn "No directory specified to scan for Service ${service_type^} include file manifest" true
		return 1
	fi # 1/

	if [ -z "$parent_dir" ]; then # 1/
		debug_print 2 warn "No directory specified to scan for Service program ${service_type^} include files" true
		return 1
	fi # 1/

	[ -z "$common_dir" ] && debug_print 4 "No directory specified to scan for common (shared) ${service_type^} include files"
	[ -z "$manufacturer_sub_dir" ] && debug_print 4 "No directory specified to scan for manufacturer-specific include files"

	# confirm mannifest is a file and not some other file system object type
	if ! validate_file_system_object "$manifest_directory" "directory"; then # 1/
		debug_print 2 warn "manifest file location is not a directory" true
		return 1
	fi # 1/

	# confirm current user can read the manifest
	if ! set_target_permissions "$manifest_directory" PERM_TRAVERSE true; then # 1/
		debug_print 2 warn "Indicated directory containing include file manifests is inaccessible"
		return 1
	fi # 1/

	##
	# Scan manifest files directory and identify the best version-matched manifest file
	##

	# {name of global var to receive result} {dir of manifests to be scanned} {target pattern} {target version} {file extension}
	if ! service_manifest_var_name="$(match_file_version "$manifest_directory" "$service_type" "$builder_program_version" info)"; then # 1/ bail when no good match found in specified search dir
		debug_print 2 warn "Failed to identify manifest file corresponding to Service ${service_type^}"
		return 1
	fi # 1/

	debug_print 2 "Identified version-matched $service_type manifest file location: $service_manifest_var_name"

	# count number of include filenames in manifest file, while ignoring duplicates
	count=$(sort -u "$service_manifest_var_name" | grep -c '\.sh$')
	debug_print 4 "Found $count unique filenames in include file manifest"

	if (( count == 0 )); then # 1/
		debug_print 2 warn "Include file manifest is devoid of any include filenames"
		return 1
	fi # 1/

	debug_print 4 "Verify files in Service $service_type manifest"

	debug_print 4 "Top-level include files source directory: ${parent_dir}/"
	[ -n "$manufacturer_sub_dir" ] && debug_print 4 "Include files priority manufacturer sub-directory: ${manufacturer_sub_dir}/"
	[ -n "$common_dir" ] && debug_print 4 "Common include files source directory: ${common_dir}/"

	##
	# Parent dir is required
	# Manufacturer dir is optional
	# Common dir is optional
	##

	# parse each filename in manifest and verify it exists
	while read -r filename; do # 1/
		{ [ -z "$filename" ] || [ "${filename::1}" = "#" ]; } && continue # skip headers and empty lines

		# prioritize manufacturer sub-dir files, when present
		{ [ -n "$manufacturer_sub_dir" ] && query_target_permissions "${manufacturer_sub_dir}/${filename}" PERM_READ_ONLY true; } && continue
		query_target_permissions "${parent_dir}/${filename}" PERM_READ_ONLY true && continue
		{ [ -n "$common_dir" ] && query_target_permissions "${common_dir}/${filename}" PERM_READ_ONLY true; } && continue

		# fallback to error when file indicated in manifest could not be found in a validated search directory
		debug_print 3 warn "File not found: $filename"
		file_error=true
	done < <(sort -u "$service_manifest_var_name" | grep '\.sh$') # 1/ unique records only, ignore duplicate filenames

	# abort when any files in the manifest are missing
	if [ -n "$file_error" ]; then # 1/
		debug_print 2 warn "Failed to validate Service ${service_type^} manifest because one or more files were not found"
		return 1
	fi # 1/

	debug_print 2 "Service ${service_type^} manifest validated successfully"
	printf "%s" "$service_manifest_var_name"
}
