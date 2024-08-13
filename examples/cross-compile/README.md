# Cross-compilation for Windows using MinGW64

This examples shows how MK script can be used for cross-compilation.

## General information

The MK script allows to set the CMake toolchain file. This means for example that in order to cross-compile using MinGW it is enough to pass correct path to the CMake toolchain file using --toolchain option. A simple example of such toolchain script can be found in the 'scripts' folder of the example.

## Building

The example can be built using mk-all.sh script. Internally the script prepares working folder and runs the MK script with corresponding flags.

> **_NOTE:_** The mk-all.sh script is simple and one can dive into it in order to see what exactly it does.
<br/>

In fact one can just copy the MK script to the root folder of the example and run
```
./mk --platform mingw --cleanup --toolchain scripts/MinGW64-toolchain.cmake
```
* ```--platform mingw``` here is intended to set the build folder.
* ```--cleanup``` is set to clean the build folder if it already exists (can be safely ommitted).
* ```--toolchain scripts/MinGW64-toolchain.cmake``` actually sets up the CMake toolchain for the cross-compilation build.

## MacOS Cheatsheet

These next lines show how to install MinGW64 for OS X. Just decided to keep it here.
```
brew install binutils

echo 'export PATH="/opt/homebrew/opt/binutils/bin:$PATH"' >> /Users/o.zhukov/.zshrc

export LDFLAGS="-L/opt/homebrew/opt/binutils/lib"
export CPPFLAGS="-I/opt/homebrew/opt/binutils/include"

brew install mingw-w64
```
