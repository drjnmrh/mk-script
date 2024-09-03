# Simple example of the CLI tool with testing

This examples shows how MK script can be used to build a simple C++ CLI tool. Also it shows how it can be used to execute unit tests specified in the CMake script.

## General information

The MK script tries to provide simple way of building and testing C++ projects. So most of the work should be done in a CMake script ;-)
<br/>
The example contains C++ code for the CLI tool, CMake script which specifies target and tests. The MK script is copied by the mk-all.sh and executed with just one '--test' flag.

## Building

The example can be built using mk-all.sh script. It is a simple set of steps, which could be substituted by copying current version of the MK script to the root folder of the example and execution of the next line:
```
./mk --test
```
