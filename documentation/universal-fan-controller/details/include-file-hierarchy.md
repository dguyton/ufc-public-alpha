# Include File Order Hierarchy
As a portion of UFC's modular program design, include files are loaded in a particular order. These include files contain subroutines ("functions" in Linux parlance). The file import logic uses a multi-part process to determine which files to import, decide from where, and import them.

Step 1: Locate include file manifest.
Step 2: Validate include file manifest.
Step 3: Verify each filename in the manifest exists in a qualified directory.
Step 4: Import each filename.

The first step is to locate the include file manifest. Each core program has its own file manifest, and each manifest is always found in a pre-determined directory. The file manifest must exist in its expected location, or the program will abort.

During step 2, every filename mentioned in the manifest must exist in at least one of the known source file directories earmarked for include files. If any filename is not found, the entire process fails and the program will exit.

Steps 3 and 4 attempt to validate and load each file according to a set of rules.

The presence of the file is validated in a hierarchical fashion. For example, if the filename is found in the the first priority directory level, the search stops and the filename in the first location is tagged for import. If it is not found in the first (highest priority) directory location, the secondary location is checked, and if not (when relevant), the tertiary. If the filename is not found in any of the possible locations, the file validation fails, the entire process stops, and the program exits due to a missing file.

## Builder Include File Validation Process
1. Each file is validated if it is present in either of these two directories:
  - Builder-specific include files sub-directory
  - Common (shared) include files directory
2. Attempt to import the file.
  - If the filename cannot be imported successfully, abort.
  - Even if the file is present in both directories, if it fails to load from the first matching directory, do not attempt to load it from the second.

## Service Program Include File Validation Process
1. Each file is validated if it is present in either of these three directories:
  - Service-specific include files sub-directory
  - Common (shared) include files directory
  - Manufacturer-specific sub-directory
2. Attempt to import the file.
  - If the filename cannot be imported successfully, abort.
  - Even if the file is present in both directories, if it fails to load from the first matching directory, do not attempt to load it from the second.
