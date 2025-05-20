# Global Variable Declarations
What are these "global declaration files" mentioned in some portions of the UFC documentation?

A part of UFC's modular design calls for the use of independent BaSH files containing all global variable name declarations which are not required upon the immediate initialization of each core program file. This process was adopted for two reasons which align with UFC's core design principles:
1. Compartmentalization of important program functions makes maintanance easier. For example, to add a new global variable, one simply adds it to the global declarations file instead of editing the main executable.
2. Easy to determine if the same or a similar global variable already exists.

The exceptions where variables are declared in the main program are simply for vars that have to be setup prior to importing the global var file.
