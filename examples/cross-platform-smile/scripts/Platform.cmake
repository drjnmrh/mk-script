function(autodetect_architecture _outvar)
    set(_archdetect_code "
#if defined(__MINGW64__) || defined(_M_X64) || defined(_M_AMD64)
#   error detected_ARCH x86_64
#elif defined(__MINGW32__) || defined(_M_IX86) || defined(_X86_)
#   error detected_ARCH i386
#elif defined(__amd64__) || defined(__amd64) || defined(__x86_64__) || defined(__x86_64)
#   error detected_ARCH x86_64
#elif defined(i386) || defined(__i386) || defined(__i386__)
#   error detected_ARCH i386
#elif defined(__aarch64__) || defined(__arm__) || defined(__TARGET_ARCH_ARM)
#   error detected_ARCH arm64
#else
#   error detected_ARCH unknown
#endif")

    file(WRITE "${CMAKE_BINARY_DIR}/detect-arch.c" "${_archdetect_code}")

    enable_language(C)
    try_run(_rr _cr "${CMAKE_BINARY_DIR}" "${CMAKE_BINARY_DIR}/detect-arch.c"
        COMPILE_OUTPUT_VARIABLE ARCH)
    string(REGEX MATCH "detected_ARCH ([a-zA-Z0-9_]+)" ARCH "${ARCH}")
    string(REPLACE "detected_ARCH " "" ARCH "${ARCH}")

    set(${_outvar} "${ARCH}" PARENT_SCOPE)
endfunction()

function(smile_detect_platform _outvar)
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Android")
        set(${_outvar} "Android" PARENT_SCOPE)

        set(ARCH ${ANDROID_ABI} PARENT_SCOPE)

        if (NOT DEFINED ANDROID)
            set(ANDROID TRUE PARENT_SCOPE)
        elseif (NOT ANDROID)
            set(ANDROID TRUE PARENT_SCOPE)
        endif()

        include(Android)
    elseif (IOS)
        set(${_outvar} "iOS" PARENT_SCOPE)

        set(ARCH ${CMAKE_OSX_ARCHITECTURES} PARENT_SCOPE)

        include(iOS)
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        set(${_outvar} "MacOSX" PARENT_SCOPE)

        if (CMAKE_OSX_ARCHITECTURES STREQUAL "")
            debug_message("Autodetect architecture")
            autodetect_architecture(ARCH)

            set(CMAKE_OSX_ARCHITECTURES ${ARCH} CACHE STRING "")
            set(ARCH ${ARCH} PARENT_SCOPE)
        else ()
            set(ARCH ${CMAKE_OSX_ARCHITECTURES} PARENT_SCOPE)
        endif()
        debug_message("ARCH is ${ARCH}; CMAKE_OSX_ARCHITECTURES is ${CMAKE_OSX_ARCHITECTURES}")

        if (NOT DEFINED MACOSX)
            set(MACOSX TRUE PARENT_SCOPE)
        elseif (NOT MACOSX)
            set(MACOSX TRUE PARENT_SCOPE)
        endif()

        include(MacOSX)
    elseif(UNIX)
        set(${_outvar} "Unix" PARENT_SCOPE)

        autodetect_architecture(ARCH)
        set(ARCH "${ARCH}" PARENT_SCOPE)

        include(Unix)
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
        set(${_outvar} "Windows" PARENT_SCOPE)

        autodetect_architecture(ARCH)
        set(ARCH "${ARCH}" PARENT_SCOPE)

        if (NOT DEFINED WINDOWS)
            set(WINDOWS TRUE PARENT_SCOPE)
        elseif (NOT WINDOWS)
            set(WINDOWS TRUE PARENT_SCOPE)
        endif()

        include(Windows)
    else()
        message(FATAL_ERROR "Unsupported (yet) platform ${CMAKE_SYSTEM_NAME}!")
    endif()

    smile_Platform_Prepare()
endfunction()

function(smile_setup_common_flags inTargetName)
    smile_Platform_setup_common_flags(${inTargetName})
endfunction()

function(smile_setup_library_flags inTargetName)
    get_target_property(_type ${inTargetName} TYPE)
    if (${_type} STREQUAL "STATIC_LIBRARY")
        smile_Platform_setup_static_library(${inTargetName})
    elseif (${_type} STREQUAL "SHARED_LIBRARY")
        smile_Platform_setup_shared_library(${inTargetName})
    else()
        message(FATAL_ERROR "Expected library, got ${_type}")
    endif()
endfunction()
