# MacOSX and iPhone Platform Code

This folder contains a code for the MacOSX and iPhone platform parts. A simple application which uses UIKit or AppKit frameworks depending on the platform. Metal is used as a graphics backend.
<br/>
Smile core context setup can be found in a _MainViewController.m_ source file. Overall code is straightforward.

## Environment

It would be easier to manage dependencies if built 3rdparty libraries are placed into a specific folder and THIRDPARTY_HOME environment variable is to the path to this folder. For example:
```
export THIRDPARTY_HOME=~/3rdparty
```
This variable will only be used when libPng is built. It is not used the base making script.

## Thirdparty dependencies

Only libPng is needed. This library could be built for MacOSX and iPhone platforms with a help of some scripts in the _scripts_ folder of this example.

### Prepare thirdparty home folder

Create THIRDPARTY_HOME folder if needed:
```
mkdir -p $THIRDPARTY_HOME
```
Next copy utility script to the create folder:
```
cd /path/to/example/root
cp scripts/prepare-libpng-apple.sh $THIRDPARTY_HOME
```

### libPng for MacOSX and iPhone

It is suggested to use official [libpng](http://www.libpng.org/pub/png/libpng.html) site. Code snippets below will use _prepare-libpng-apple.sh_ utility script for the whole process of building libpng for both platforms.
<br/>
This script requires 2 parameters:
- path to the thirdparty home folder
- path to the mk-script repo folder
<br/>
The code below shows how the script could be used:
```
cd $THIRDPARTY_HOME
./prepare-libpng-apple.sh $THIRDPARTY_HOME /path/to/mk-script/repo
```
Building the example will require png.dir variable from local.properties:
```
cd /path/to/mk-script/repo
cd examples/cross-platform-smile
echo png.dir=\"$THIRDPARTY_HOME\" >> local.properties
```

## Build the example for MacOSX

Just use _mk-all.sh_ script to generate Xcode project and build the code:
```
./mk-all.sh
```
The Xcode project could be found in created _build-macosx_ folder:
```
open build-macosx/smile.xcodeproj
```

## Build the example for iPhone device

Script _mk-iphone.sh_ could be used to generate Xcode project and build the code for the device:
```
./mk-iphone.sh
```
The Xcode project could be found in created _build-iphone_ folder:
```
open build-iphone/smile.xcodeproj
```

## Issues with signing

In order to run built app on the device, code signing is required. It can be either specified explicitly in the Xcode project or it could be specified using apple.team variable in local.properties:
```
cd /path/to/example/root
echo apple.team=\"<your team id>\" >> local.properties
```
In order to provide custom bundle name, osx.bundle variable in local.properties could be specified.

## What about Simulator?

It is possible to build the example for the iPhone simulator. In this case raw MK script could be copied to the example root and executed in a way similar to what _mk-iphone.sh_ does it. But in this case IOS_TYPE should be set to _iphonesimulator_ value.

