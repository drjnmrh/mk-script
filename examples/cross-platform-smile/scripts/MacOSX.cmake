macro(smile_Platform_Prepare)
    set(MACOSX_DEPLOYMENT_TARGET 10.12)

    set(CMAKE_XCODE_ATTRIBUTE_ARCHS "$(ARCHS_STANDARD)")
endmacro()


macro(smile_Platform_setup_common_flags inTargetName)
    target_compile_options(${inTargetName} PRIVATE
        $<$<CONFIG:Release>:-Ofast>
        $<$<CONFIG:Debug>:-O0>
        -fcxx-modules -fmodules
    )

    target_compile_definitions(${inTargetName} PRIVATE
        PLATFORM_MACOSX
        $<$<CONFIG:Release>:NDEBUG _NDEBUG>
        $<$<CONFIG:Debug>:DEBUG _DEBUG>
    )
    
    set_target_properties(${inTargetName} PROPERTIES
        XCODE_ATTRIBUTE_CLANG_C_LANGUAGE_STANDARD   "c99"
        XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY           "libc++"
        XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++20"
        XCODE_ATTRIBUTE_SWIFT_VERSION               "5.0"

        XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL[variant=Debug]          "0"
        XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL[variant=MinSizeRel]     "z"
        XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL[variant=RelWithDebInfo] "fast"
        XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL[variant=Release]        "fast"

        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
        XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES  "YES"

        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Debug]          "dwarf-with-dsym"
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=MinSizeRel]     "dwarf-with-dsym"
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=RelWithDebInfo] "dwarf-with-dsym"
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release]        "dwarf-with-dsym"

        XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS[variant=Debug]          "YES"
        XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS[variant=MinSizeRel]     "NO"
        XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS[variant=RelWithDebInfo] "YES"
        XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS[variant=Release]        "NO"

        XCODE_ATTRIBUTE_SDKROOT "macosx"

        XCODE_ATTRIBUTE_MACOSX_DEPLOYMENT_TARGET "${MACOSX_DEPLOYMENT_TARGET}"

        XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME "YES"
        XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN "YES"
    )
endmacro()


macro(smile_Platform_setup_static_library inTargetName)
endmacro()

