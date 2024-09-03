# Ubuntu and Windows Platform Code

This folder contains a code for the Ubuntu and Windows desktop platform parts. Both platforms use GLFW and GLEW to create and manage window and setup OpenGL.
<br/>
The sole source file _main.cpp_ contains the code which sets up Smile Core Context. Also [opengl-utils](../opengl/README.md) is used to provide platform graphics API.

## Ubuntu

> **NOTE:** This paragraph is for Ubuntu-only.

### Environment

It would be easier to manage dependencies if prebuilt 3rdparty libraries are placed into a specific folder and THIRDPARTY_HOME environment variable is set to the path to this folder. For example:
```
export THIRDPARTY_HOME=~/3rdparty
```
This variable will be used only when 3rdparty libs are prepared.

### Thirdparty dependencies

In order to build the example, libpng, zlib, GLEW, GLFW and GLM libraries are needed. Below it is described how to install all of them.

### libPng and ZLib

Just install using apt-get:

```
sudo apt-get install libpng-dev
sudo apt-get install zlib1g-dev
```

### GLEW, GLM, GLFW

First set up the thirdparty home folder:

```
mkdir -p $THIRDPARTY_HOME
```

Then copy to THIRDPARTY_HOME preparation scripts from the _scripts_ folder of the example:
```
# we assume that we are in an example root folder
cp scripts/prepare-glew.sh $THIRDPARTY_HOME
cp scripts/prepare-glfw.sh $THIRDPARTY_HOME
cp scripts/prepare-glm.sh $THIRDPARTY_HOME
```

Next run the copied scripts:
```
cd $THIRDPARTY_HOME
./prepare-glew.sh $THIRDPARTY_HOME
./prepare-glfw.sh $THIRDPARTY_HOME
./prepare-glm.sh $THIRDPARTY_HOME
```

At last, put corresponding paths into local.properties file
```
cd /path/to/example/root
echo glm.dir=\"$THIRDPARTY_HOME\" >> local.properties
echo glew.dir=\"$THIRDPARTY_HOME\" >> local.properties
echo glfw.dir=\"$THIRDPARTY_HOME\" >> local.properties
```

That's it, dependencies should be ready.

### Building

Just execute _mk-all.sh_ script from the example root folder:
```
./mk-all.sh
```
The built binary will be placed into build-linux/desktop folder.

## Windows

In order to build for windows it is required to have Visual Studio installed. Building was tested using Visual Studio 2022 Community Edition.
<br/>
Also it would be nice to use Visual Studio Code for the script execution and files editing since it allows to execute Bash scripts (via Git Bash Terminal).

### Thirdparty dependencies

These libraries are needed:
* [zlib](https://github.com/madler/zlib/releases/download/v1.3.1/zlib131.zip)
* [libpng](https://sourceforge.net/projects/libpng/files/libpng16/1.6.43/lpng1643.zip/download)
* [GLEW](https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.zip)
* [GLFW](https://github.com/glfw/glfw)
* [GLM](https://github.com/g-truc/glm/archive/refs/tags/1.0.1.zip)

#### zlib

Unpack zlib131.zip and open VS project in contrib/vstudio/vc17. Build static library and place it into some folder (let's say it will be ZLIB_HOME).

#### libPNG

Download lpng1643.zip file, unpack it into some folder (LIBPNG_HOME).
Next go to the libpng sources root folder and use CMake to build it:
```
# these commands can be executed from git bash terminal in VS Code
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../Windows-x86_64 -DPNG_SHARED=ON -DPNG_STATIC=OFF -DZLIB_ROOT=/path/to/zlib
cmake --build . --config Release
cmake --install . --config Release
```

Append to local.properties variable png.dir:
```
png.dir="/path/to/libpng/sources"
```

#### GLEW

Can be downloaded from [github](https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.zip).
<br/>
Unpack the zip file and open VS project (build/vc15/glew.sln). Build static library using VS. Place lib and include folders with built library into Windows-x86_64 folder.

#### GLFW

Can be downloaded from [github](https://github.com/glfw/glfw).
<br/>
Use CMake to configure and build the library:
```
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../Windows-x86_64
cmake --build . --config Release -- all
cmake --build . --config Release -- install
```

#### GLM

The same as GLFW: sources can be downloaded for [github releases]((https://github.com/g-truc/glm/archive/refs/tags/1.0.1.zip). Unzip archive and cd into the GLM sources root folder.
<br/>
Use CMake to build and install GLM:
```
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../Windows-x86_64 -DGLM_BUILD_TESTS=OFF -DBUILD_SHARED_LIBS=OFF 
cmake --build . -- all
cmake --build . -- install
```
#### Append dirs to local.properties

```
glew.dir="/path/to/glew/dir"
glfw.dir="/path/to/glfw/dir"
glm.dir="/path/to/glm/dir"
```

### Building for Windows

Just run _mk-all.sh_ from VSCode Git Bash Terminal.
<br/>
Generated Visual Studio project will be placed into build-msvc folder.

