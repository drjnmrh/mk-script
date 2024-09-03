# Cross-platform simple app example

This is an example which demonstrates how **MK** script could be used for setting up and building CMake-based cross-platform code.
<br/>
Supported platforms and links to the corresponding documentation:
* [MacOSX](sources/apple/README.md)
* [iOS](sources/apple/README.md)
* [Android](sources/android/README.md)
* [Windows](sources/desktop/README.md)
* [Ubuntu](sources/desktop/README.md)

## Some details

Business logic is implemented in the [smile-core](sources/smile/README.md) static library. Some platforms use [opengl-utils](sources/opengl/README.md) library which implements common code for the OpenGL-based graphics backbone.
<br/>
Each platform code is responsible for setting up the business logic context (SmileContext) platform api and manage app lifecycle. Platform API is a set of pointers to functions which are used be the smile-core to manage assets, load/unload resources, drawing stuff.

