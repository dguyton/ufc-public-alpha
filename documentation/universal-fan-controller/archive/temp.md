
## Program Responsibilities
Each of the three core programs has various tasks it is responsible for.

### The Builder's Tasks
The Builder is reponsible for:
1. Analyzing system hardware
2. Determining whether or not the UFC is compatible with current server hardware
3. Validating Builder configuration files
4. Validating all files required to setup Launcher and Runtime programs
5. Validating all include files required by Launcher and Runtime programs
6. Recording a program log of Builder's activities
7. Defining the initialization parameters of the Service Launcher program
8. Defining the operating parameters of the Service Runtime program

### Service Launcher Tasks
The Service Launcher is reponsible for the following tasks:
1. Validate Runtime program file exists and its version
2. Validate inventory of Runtime include files
3. Validate Runtime external dependencies
4. Inventory existing fan headers
5. Perform initial fan header validation sweep
6. Confirm CPU/device fan control settings
7. Set initial fan speeds
8. Set starting Runtime operational variables
9. Initialize new Runtime program log
10. Launch Runtime executable

### Service Runtime Tasks
The Service Runtime program is primarily comprised of a main loop that performs the following tasks repeatedly:
1. Monitor CPU temperatures
2. Monitor disk device temperatures
3. Adjust disk device cooling PID controller
4. Adjust disk device fans per PID controller algorithm
5. Adjust CPU fans
6. Monitor for signs of suspicious (failing) fans
7. Validate fan operations
8. Monitor for disk device inventory changes
9. Program and JSON log management
