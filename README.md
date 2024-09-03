# Stoned Fox's Awesome MK Script

The purpose of the script is to simplify work with CMake-based projects.

## Table of Contents

1. [Motivation](#motivation)
2. [Usage](#usage)
    1. [Script basic flags](#script-basic-flags)
    2. [Special local.properties file](#special-localproperties-file)
    3. [What about Windows](#what-about-windows)
3. [Examples](#examples)
4. [License](#license)

## Motivation

I've found out that when developing C++ projects using CMake I have to perform certain types of actions:
1) write a CMakeLists.txt script
2) create _build_ folder
3) cd to the _build_ folder
4) execute cmake with a certain number of flags to generate Makefiles or IDE project
5) execute cmake to build the code
6) execute cmake to run CTest tests
7) change the code
8) cleanup the _build_ folder (optional)
9) repeat from 3)

As the project grows in complexity number of required flags passed to CMake is increased. Some of the flags are variables which are host-platform or even development environment specific and it's difficult to track them.
<br/>
As a result I end up writing bash scripts to manage project generation and building/testing processes. In case of cross-compilation or cross-platform code development these scripts become quite messy.
<br/>
So after all the pain I've decided to create this more or less universal Bash script, which will automate basic steps.

## Usage

Just copy the script into the root of the project, specify environment-specific variable in the local.properties file (don't forget to add it to the .gitignore) and run **MK** script when needed.

### Script basic flags

Here my favorite flags are listed. With some description.

> **NOTE:** More information about MK flags can be found in the help output: ```./mk --help ``

#### platform

This is basically an optional flag. When **MK** script is executed without it, the script will try to detect which platform the code should be built for and which generator could be used. For example, when **MK** is executed under the MacOSX platform, the platform flag is deduced to be _macosx_ and Xcode generator is used. The build folder will be build-macosx in this case.
<br/>
The purpose of this flag is to name the build folder correctly: it will be named _build-<platform>_.
<br/>
There are some special values which will affect the generation/buildin pipeline:
* _android_ - this will hint the **MK** script to try to find _gradlew_ script among sources and use it to build the android project. If none is found then **MK** script will try to use NDK CMake and corresponding toolchain to build the project.
* _iphone_ - this will hint the **MK** script to generate Xcode project for the iOS platform; it is important to notice that an iOS CMake toolchain will be required (can be specified by the _--toolchain_ flag).
* _msvc_ - this will hint the script to generate using default CMake generator, but in case if the script is run under VSCode [git bash](#what-about-windows) it seems that CMake will choose Visual Studio generator.
* _macosx_ - this value means that **MK** script should generate Xcode project.

#### toolchain

This flag allows to specify CMake toolchain script. Simply pass path to the toolchain file and it will be used in the generation process. This case can be found in some of the examples ([cross-compile](examples/cross-compile/README.md) and [cross-platform-smile](examples/cross-platform-smile/README.md)).

#### cleanup

Just clear the build folder before generation.

#### source

Specifies path to the root CMakeLists.txt script. Default value is a 'sources' folder.

#### test

If CTest framework is used then this flag will force **MK** to execute the tests.

#### only

This flag helps to filter out which tests should be executed (works with a --test flag).

#### tocmake

Allows to pass some variables to CMake. Usage examples can be found in [cross-platform-smile mk-iphone](examples/cross-platform-smile/mk-iphone.sh) script.

### Special local.properties file

Environment-specific information could be passed to CMake using either CMake flags (-D<VARNAME>=<VALUE>) or by setting up environment variables. **MK** has a machanism to get such information another way. One can create local.properties file in the root project folder and place key-value pairs there. The script will parse the file and fetch variables to be passed to CMake. The syntax of the file is simple:
```
var.name.with.dots="quote-separated-value"
```
Variable in the example above will be transformed to VAR_NAME_WITH_DOTS and will be passed to CMake (like if it was specified -DVAR_NAME_WITH_DOTS="quote-separated-value" directly or by --tocmake flag of the **MK** script). In case of the Android Gradle building system, the variable above will be passed to gradle as var_name_with_dots variable. In this case its value could be used in a build.gradle script.
<br/>
> **NOTE:** It is better to add local.properties to .gitignore.

### What about Windows

As one can notice, there's no Windows BATCH or PowerShell copy of the script. Does this mean that **MK** is unusable under Windows? Actually, no. In Visual Studio Code there's an option to use a Git Bash terminal. And this terminal actually allows to run the script.

## Examples

There's a number of example projects in this repo. Each contains its own documentation:

* [cross-compile](examples/cross-compile/README.md)
* [cross-platform-smile](examples/cross-platform-smile/README.md)
* [simple-cli-tool](examples/simple-cli-tool/README.md)

## License

This script is under [MIT License](LICENSE).

