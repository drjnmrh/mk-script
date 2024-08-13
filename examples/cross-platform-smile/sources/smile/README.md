# Smile Core static library

This is a code for the smile-core static library which implements business logic of the example app. On all platforms this target requires libPng library to read texture of the smiley face. Details of how to prepare 3rdparty libraries could be found in platform-specific targets folders README.md files:
- [Desktop](../desktop/README.md)
- [Apple](../apple/README.md)
- [Android](../apple/README.md)

## Some details

The library provides simple C interface for the platform:
* **smile_SetUp** - sets up and initializes Smile Core Context (callee must specify pointers to functions in the _platform_api_ field of the context
* **smile_TearDown** - tears down Smile Core Context and frees resources acquired by the buisness logic
* **smile_ReloadResources** - called by the platform code when graphics context is ready and core can reload resources (like textures and buffers)
* **smile_UnloadResources** - called by the platform code when it is required to free resources (like when iphone app goes background)
* **smile_Update** - method to update buisness logic state
* **smile_Render** - method to render graphics
<br/>
Also smile-core provides a simple logging mechanism (found in _smile/log.hpp_ header file).

