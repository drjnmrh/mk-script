# Parametrized by
# * IOS_TYPE
# * IOS_MINIMUM_VERSION
# * IOS_BITCODE

if (NOT DEFINED IOS_TYPE)
    message(STATUS "Autodetect iOS Type")
    if (CMAKE_OSX_ARCHITECTURES)
        if (CMAKE_OSX_ARCHITECTURES MATCHES ".*arm.*")
            set(IOS_SDK_TYPE "iphoneos")
        elseif (CMAKE_OSX_ARCHITECTURES MATCHES "i386" OR CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
            set(IOS_SDK_TYPE "iphonesimulator")
        else ()
            message(FATAL_ERROR "Unexpected architecture: ${CMAKE_OSX_ARCHITECTURES}")
        endif()
    else ()
        set(IOS_SDK_TYPE "iphoneos")
    endif()
else()
    if (IOS_TYPE STREQUAL "iphone")
        set(IOS_SDK_TYPE "iphoneos")
        set(CMAKE_OSX_ARCHITECTURES arm64)
    elseif (IOS_TYPE STREQUAL "watchos")
        set(IOS_SDK_TYPE "watchos")
        set(CMAKE_OSX_ARCHITECTURES armv7k arm64_32)
    elseif (IOS_TYPE STREQUAL "watchos-simulator")
        set(IOS_SDK_TYPE "watchsimulator")
        set(CMAKE_OSX_ARCHITECTURES x86_64)
    elseif (IOS_TYPE STREQUAL "iphone-simulator")
        set(IOS_SDK_TYPE "iphonesimulator")
        set(CMAKE_OSX_ARCHITECTURES i386 x86_64 arm64)
    elseif (IOS_TYPE STREQUAL "tvos")
        set(IOS_SDK_TYPE "appletvos")
        set(CMAKE_OSX_ARCHITECTURES arm64)
    elseif (IOS_TYPE STREQUAL "tvos-simulator")
        set(IOS_SDK_TYPE "appletvos")
        set(CMAKE_OSX_ARCHITECTURES x86_64)
    else()
        message(FATAL_ERROR "Unexpected iOS type: ${IOS_TYPE}")
    endif()
    set(CMAKE_OSX_ARCHITECTURES ${CMAKE_OSX_ARCHITECTURES} CACHE STRING "Build architectures") 
endif()
message(STATUS "Configuring for ${IOS_SDK_TYPE} (${CMAKE_OSX_ARCHITECTURES})")

execute_process(COMMAND xcodebuild -version -sdk ${IOS_SDK_TYPE} Path OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
if (NOT EXISTS ${CMAKE_OSX_SYSROOT})
    message(FATAL_ERROR "Failed to find SDK for ${IOS_SDK_TYPE}")
endif()
message(STATUS "Using SDK: ${CMAKE_OSX_SYSROOT}")

get_filename_component(_tmp ${CMAKE_OSX_SYSROOT} PATH)
get_filename_component(_tmp ${_tmp} PATH)
set(CMAKE_FIND_ROOT_PATH ${_tmp} ${CMAKE_OSX_SYSROOT} ${CMAKE_PREFIX_PATH}
    CACHE STRING "Search path root" FORCE)

if (NOT CMAKE_C_COMPILER)
    execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find clang
        OUTPUT_VARIABLE CMAKE_C_COMPILER ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
endif()

if (NOT CMAKE_CXX_COMPILER)
    execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find clang++
        OUTPUT_VARIABLE CMAKE_CXX_COMPILER ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")
endif()

#if (NOT CMAKE_METAL_COMPILER)
#    execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find metal
#        OUTPUT_VARIABLE CMAKE_METAL_COMPILER ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
#    message(STATUS "Using Metal compiler: ${CMAKE_METAL_COMPILER}")
#endif()

execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find libtool
    OUTPUT_VARIABLE _libtool ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

set(CMAKE_C_CREATE_STATIC_LIBRARY "${_libtool} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "${_libtool} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")

execute_process(COMMAND uname -r OUTPUT_VARIABLE CMAKE_HOST_SYSTEM_VERSION
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process(COMMAND xcodebuild -sdk ${CMAKE_OSX_SYSROOT} -version SDKVersion
    OUTPUT_VARIABLE SDK_VERSION ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

if (NOT IOS_MINIMUM_VERSION)
    set(IOS_MINIMUM_VERSION "${SDK_VERSION}" CACHE STRING "Mimimum iOS version")
endif()
message(STATUS "Mimimum iOS version: ${IOS_MINIMUM_VERSION}")

set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_VERSION ${IOS_MINIMUM_VERSION})
set(APPLE TRUE)
set(IOS TRUE)

set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set(CMAKE_SHARED_MODULE_PREFIX "lib")
set(CMAKE_SHARED_MODULE_SUFFIX ".so")
set(CMAKE_MODULE_EXISTS 1)
set(CMAKE_DL_LIBS "")

set(CMAKE_C_COMPILER_ABI ELF)
set(CMAKE_CXX_COMPILER_ABI ELF)
set(CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set(CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set(CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set(CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

set(CMAKE_MACOSX_BUNDLE YES)

set(_versionFlags "-m${IOS_SDK_TYPE}-version-min=${IOS_MINIMUM_VERSION}")

if (IOS_BITCODE)
    set(_bitcode "-fembed-bitcode")
    set(CMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE "bitcode")
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "YES")
else ()
    set(_bitcode "")
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")
endif()

set(CMAKE_C_FLAGS "${_versionFlags} ${_bitcode} -fobjc-abi-version=2 -fobjc-arc ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${_versionFlags} ${_bitcode} -fvisibility=hidden -fvisibility-inlines-hidden -fobjc-abi-version=2 -fobjc-arc ${CMAKE_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -O3 -ffast-math ${CMAKE_CXX_FLAGS_RELEASE}")
set(CMAKE_C_LINK_FLAGS "${_versionFlags} -Wl,-search_paths_first ${CMAKE_C_LINK_FLAGS}")
set(CMAKE_CXX_LINK_FLAGS "${_versionFlags} -Wl,-search_paths_first ${CMAKE_CXX_LINK_FLAGS}")

list(APPEND _forceInCache CMAKE_C_FLAGS CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_RELEASE CMAKE_C_LINK_FLAGS CMAKE_CXX_LINK_FLAGS)
foreach(_flag ${_forceInCache})
    set(${_flag} "${${_flag}}" CACHE STRING "" FORCE)
endforeach()

set(CMAKE_PLATFORM_HAS_INSTALLNAME 1)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib -Wl,-headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle -Wl,headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set(CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set(CMAKE_SHARED_LINKER_FLAGS "-rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")
set(CMAKE_SHARED_LIBRARY_SONAME_C_FLAG "-install_name")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".tbd" ".dylib" ".so" ".a")

set(CMAKE_FIND_FRAMEWORK FIRST)

set(CMAKE_SYSTEM_FRAMEWORK_PATH
    ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
    ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks
    ${CMAKE_OSX_SYSROOT}/Developer/Library/Frameworks
)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

if (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
    message(STATUS "Find install_name_tool")
    execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find install_name_tool
        OUTPUT_VARIABLE CMAKE_INSTALL_NAME_TOOL ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(CMAKE_INSTALL_NAME_TOOL ${CMAKE_INSTALL_NAME_TOOL} CACHE INTERNAL "")
endif()

get_property(_inTryCompile GLOBAL PROPERTY IN_TRY_COMPILE)
if (NOT _inTryCompile)
    #    set(CMAKE_MAKE_PROGRAM "xcodebuild" CACHE INTERNAL "" FORCE)
endif()

