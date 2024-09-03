# Android Platform Code

This folder contains a code for the Android platform part. This code contains simple Android application (implemented using Java) with a C++ dynamic library which provides JNI bridge.
<br/>
Android Activity loads GLSurfaceView with a custom Renderer. This renderer proxies calls to the native functions. Native functions are implemented in a native-lib.cpp source file. OpenGLES 3.0 is used as a graphics backbone.

## Environment

It would be nice to set NDK_HOME variable to the path to Android NDK root folder. MacOSX host example:
```
export NDK_HOME=~/Library/Android/sdk/ndk/26.1.10909125
```
Also it would be easier to manage dependencies if built 3rdparty libraries are placed into specific folder and THIRDPARTY_HOME environment variable is set to the path to this folder. For example:
```
export THIRDPARTY_HOME=~/3rdparty
```

## Thirdparty dependencies

* _smile-core_ needs libPng
* _opengl-utils_ needs glm header-only library

### Prepare thirdparty home folder

Create THIRDPARTY_HOME folder if needed:
```
mkdir -p $THIRDPARTY_HOME
```
Next one can copy utility scripts to the created folder:
```
cd /path/to/example/root
cp scripts/prepare-libpng-android.sh $THIRDPARTY_HOME
cp scripts/prepare-glm.sh $THIRDPARTY_HOME
```

### libPng for Android

It is suggested to use [libpng-android](https://github.com/julienr/libpng-android) repo to build libpng library. In the code snippet below it is assumed that NDK_HOME is set.
Let's use _prepare-libpng-android.sh_ script:
```
cd $THIRDPARTY_HOME
./prepare-libpng-android.sh $THIRDPARTY_HOME
```

CMake script will require PNG_DIR variable from local.properties:
```
cd /path/to/example/root
echo png.dir=\"$THIRDPARTY_HOME\" >> local.properties
```

### GLM header-only library

We will use GLM library just for lulz. Here some command-line snippets to install GLM headers to the THIRDPARTY_HOME folder:
```
cd $THIRDPARTY_HOME
./prepare-glm.sh $THIRDPARTY_HOME 
```

CMake script will require GLM_DIR variable from local.properties:
```
cd /path/to/example/root
echo glm.dir=\"$THIRDPARTY_HOME\" >> local.properties
```

## Building app using MK script

As soon as thirdparty libraries are prepared and local.properties is filled just use the _mk-android.sh_ script.
```
./mk-android.sh
```

## Open project in Android Studio

Folder which contains this README file can be opened in **Android Studio** as a project. All should be fine :-)

## Some details

**MK** script is able to pass variables from local.properties to **Gradle**. For example if _local.properties_ contains variable _some.var_ then **MK** script will pass _some_var_ variable to gradle, which can pass this variable (for example as SOME_VAR CMake variable) to cmake in build.gradle (see app/build.gradle).
<br/>
This mechanics take place if **MK** script can detect _gradlew_ script in sources. Otherwise the script will try to make project using CMake and Android CMake toolchain. In this case it is required to specify:
* android.dir - specifies Android SDK path
* ndk.dir - specifies Android NDK path.

