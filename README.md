# Stoned Fox's Awesome MK Script

The purpose of the script is to simplify work with CMake-based projects.

## How to setup the project

Currently one needs to setup project this way:
```
<project root folder>
 |
 *- sources             <- folder with the main CMakeLists.txt script.
 |  |
 |  *- CMakeLists.txt   <- the main CMakeLists.txt script of your project.
 |  | 
 |   ...
 *- mk                  <- this MK script.
 *- local.properties    <- file with local developer properties (e.t.c. 
                           paths to 3rdparty libs) wich will be parsed
                           by the MK script and read variables will be
                           passed to the CMake on the generation step.
```

## How to use the script

Simply write your CMake scripts, fill local.properties file if needed and run the MK script with needed flags.
<br/>
> **NOTE:** More information about MK flags can be found in the help output:```./mk --help```
