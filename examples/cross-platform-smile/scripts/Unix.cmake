macro(smile_Platform_Prepare)
    set(CMAKE_CXX_STANDARD 20)
endmacro()

macro(smile_Platform_setup_common_flags inTargetName)
    target_compile_options(${inTargetName} PRIVATE
        $<$<CONFIG:Release>:-Ofast>
        $<$<CONFIG:Debug>:-O0>
        -std=c++20
    )

    target_compile_definitions(${inTargetName} PRIVATE
        PLATFORM_UNIX
        $<$<CONFIG:Release>:NDEBUG _NDEBUG>
        $<$<CONFIG:Debug>:DEBUG _DEBUG>
    )
endmacro()


macro(smile_Platform_setup_static_library inTargetName)
endmacro()

