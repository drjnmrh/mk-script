macro(smile_Platform_Prepare)
    set(CMAKE_CXX_STANDARD 20)
endmacro()

macro(smile_Platform_setup_common_flags inTargetName)
    target_compile_options(${inTargetName} PRIVATE
        $<$<CONFIG:Release>:/O2>
        $<$<CONFIG:Debug>:/Zi /Od>
        /std:c++20
        /std:c11
    )

    target_compile_definitions(${inTargetName} PRIVATE
        PLATFORM_WINDOWS
        $<$<CONFIG:Release>:NDEBUG _NDEBUG>
        $<$<CONFIG:Debug>:DEBUG _DEBUG>
    )
endmacro()


macro(smile_Platform_setup_static_library inTargetName)
endmacro()

