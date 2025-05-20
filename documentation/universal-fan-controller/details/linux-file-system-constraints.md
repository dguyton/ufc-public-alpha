# Linux File System Constraints
The Builder has the greatest need for robust access to files, hardware, and certain programs. However, there are some functions of the Service programs that also tend to require low level access rights. 

## User Permissions
Notably, IPMI commands and the ability to run most _systemd_ daemon services are typically reserved for _root_ access only. Therefore, there is a bias toward running all programs as the _root_ user. For example, must daemon services be run as root? This is normally the case, but if your system allows other users to do so, then defining a non-root user as the Service program operator may be feasible. 

## File System Permissions 
UFC is heavily influenced by [Linux file system permission](/documentation/linux-file-permissions.md) rules. The following program features are not possible without appropriate file system permissions.
1. Logging program events and system metadata
2. Validating file dependencies
3. Importing include files
4. Running the Service programs in the background as daemon services

This is why UFC expects all three core programs to be run as the 'root' user or a user with privileges elevated to _root_ level.

## UFC Directory Structures
UFC's directory structures are designed to segment related architectural components.

There are two ways of viewing UFC's directory structure:
1. Native program layout prior to Builder execution
2. Post-setup and configuration layout

### Source Files
The program layout is the directory structure of the program source files. Essentially, this is the directory layout required for the Builder, including files the Builder copies to target location (for example, the Service program executables).

> /source_dir/<br>
> /source_dir/builder/<br>
> /source_dir/config/<br>
> /source_dir/daemon/<br>
> /source_dir/functions/<br>
> /source_dir/service/<br>

### Post-Installation
After the Builder completes its work, a separate file system directory structure will have been created that contains the Service programs and their associated support files.

> /target_dir/<br>
>
> /target_dir/launcher/<br>
>	/target_dir/launcher/{service_name}_launcher.sh<br>
>	/target_dir/launcher/{service_name}.init<br>
>	/target_dir/launcher/declarations_launcher.sh<br>
>	/target_dir/launcher/manifest_launcher.info<br>
>
> /target_dir/runtime/<br>
>	  /target_dir/runtime/{service_name}_runtime.sh<br>
>	  /target_dir/runtime/{service_name}.init<br>
>	  /target_dir/runtime/declarations_runtime.sh<br>
>	  /target_dir/runtime/manifest_runtime.info<br>
>
> /target_dir/functions/<br>
>	  /target_dir/functions/{filename}.sh<br>
>
> /daemon_service_dir/<br>
>	  /daemon_service_dir/{service_name}_launcher.service<br>
>	  /daemon_service_dir/{service_name}_runtime.service<br>
>	  /daemon_service_dir/{service_name}_fnh.service<br>

### Log Directories
The log directory locations vary. First, they will not exist at all if the user chose to disable all logging of the Service programs. Second, if they do exist, the exact location of the top-level log directory is dependent on the corresponding configuration setting. The Builder will have created or validated that directory as necessary when it was run.

> /target_dir/log/
>
>   /target_dir/log/launcher/<br>
>     /target_dir/log/launcher/{filename}.log<br>
>
>    /target_dir/log/runtime/<br>
>      /target_dir/log/runtime/{filename}.log<br>
>      /target_dir/log/runtime/json/<br>
>        /target_dir/log/runtime/json/{filename}.json<br>
