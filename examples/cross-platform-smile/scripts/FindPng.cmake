if (UNIX AND NOT APPLE AND NOT ANDROID)

    find_package(PNG REQUIRED)

    function(add_png_library inTargetName)
        add_library(${inTargetName} SHARED IMPORTED)

        foreach(_pnglib ${PNG_LIBRARIES})
            get_filename_component(_pnglibname ${_pnglib} NAME)
            if ("${_pnglibname}" STREQUAL "libpng.so")
                set(_png ${_pnglib})
                break()
            endif()
        endforeach()

        set_target_properties(${inTargetName} PROPERTIES
            IMPORTED_LOCATION "${_png}")

        target_include_directories(${inTargetName} INTERFACE
            "${PNG_INCLUDE_DIRS}")

        target_link_libraries(${inTargetName} INTERFACE z)
    endfunction()

elseif (ANDROID)

    set(_Png_SEARCH_PATH "${CMAKE_BINARY_DIR}")

    if (PNG_DIR)
        list(APPEND _Png_SEARCH_PATH "${PNG_DIR}")
    endif()

    set(_tryIncludePath "${PNG_DIR}/android/${ARCH}/include/png.h")
    if (EXISTS ${_tryIncludePath})
        set(Png_INCLUDE_DIR "${PNG_DIR}/android/${ARCH}/include")
    endif()

    set(_tryLibPath "${PNG_DIR}/android/${ARCH}/lib/libpng.a")
    if (EXISTS ${_tryLibPath})
        set(Png_LIBRARY ${_tryLibPath})
    endif()

    if (Png_LIBRARY)
        set(Png_LIBRARY_FOUND TRUE)
    endif()

    if (${VERBOSE})
        message(STATUS "* Png INCLUDE DIR = ${Png_INCLUDE_DIR}")
        message(STATUS "* Png LIBRARY     = ${Png_LIBRARY}")
    endif()

    if (Png_INCLUDE_DIR AND Png_LIBRARY_FOUND)
        message(STATUS "Png - FOUND")
        set(Png_FOUND TRUE)
    else()
        message(STATUS "Png - NOT FOUND")
        set(Png_FOUND FALSE)
        if (Png_FIND_REQUIRED)
            message(FATAL_ERROR "Png NOT FOUND\nDetails:\n    ${_Png_SEARCH_PATH}")
        endif()
    endif()

    mark_as_advanced(Png_FOUND Png_INCLUDE_DIR Png_LIBRARY Png_IMPLIBRARY)

    function(add_png_library inTargetName)
        add_library(${inTargetName} STATIC IMPORTED)

        set_target_properties(${inTargetName} PROPERTIES
            IMPORTED_LOCATION "${Png_LIBRARY}"
        )

        target_include_directories(${inTargetName} INTERFACE
            "${Png_INCLUDE_DIR}")


        target_link_libraries(${inTargetName} INTERFACE z)
    endfunction()

else ()

    set(_Png_SEARCH_PATH "${CMAKE_BINARY_DIR}")

    if (PNG_DIR)
        list(APPEND _Png_SEARCH_PATH "${PNG_DIR}")
    endif()

    if (MACOSX)
        set(_pathPrefix "/osx-${ARCH}")
    elseif (IOS)
        set(_pathPrefix "/${IOS_TYPE}")
    else ()
        set(_pathPrefix "/${PLATFORM_NAME}-${ARCH}")
    endif()

    find_path(Png_INCLUDE_DIR NAMES png.h
        PATHS ${_Png_SEARCH_PATH}${_pathPrefix}/include
        NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH
    )

    if (WINDOWS)
        find_library(Png_IMPLIBRARY NAMES libpng16.lib
            PATHS ${_Png_SEARCH_PATH}${_pathPrefix}
            PATH_SUFFIXES lib
            NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH
        )
        find_file(Png_LIBRARY NAMES libpng16.dll
            PATHS ${_Png_SEARCH_PATH}${_pathPrefix}
            PATH_SUFFIXES bin
            NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH
        )
        if (Png_LIBRARY AND Png_IMPLIBRARY)
            set(Png_LIBRARY_FOUND TRUE)
        endif()
    else ()
        set(_libName libpng.a)

        find_library(Png_LIBRARY NAMES ${_libName}
            PATHS ${_Png_SEARCH_PATH}${_pathPrefix}
            PATH_SUFFIXES lib
            NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH
        )
        if (Png_LIBRARY)
            set(Png_LIBRARY_FOUND TRUE)
        endif()
    endif()

    if (${VERBOSE})
        message(STATUS "* Png INCLUDE DIR = ${Png_INCLUDE_DIR}")
        message(STATUS "* Png LIBRARY     = ${Png_LIBRARY}")
    endif()

    if (Png_INCLUDE_DIR AND Png_LIBRARY_FOUND)
        message(STATUS "Png - FOUND")
        set(Png_FOUND TRUE)
    else()
        message(STATUS "Png - NOT FOUND")
        set(Png_FOUND FALSE)
        if (Png_FIND_REQUIRED)
            message(FATAL_ERROR "Png NOT FOUND\nDetails:\n    ${_Png_SEARCH_PATH}")
        endif()
    endif()

    mark_as_advanced(Png_FOUND Png_INCLUDE_DIR Png_LIBRARY Png_IMPLIBRARY)

    function(add_png_library inTargetName)

        if (WINDOWS)
            add_library(${inTargetName} SHARED IMPORTED)

            set_target_properties(${inTargetName} PROPERTIES
                IMPORTED_LOCATION "${Png_LIBRARY}"
                IMPORTED_IMPLIB "${Png_IMPLIBRARY}"
            )

            target_include_directories(${inTargetName} INTERFACE
                "${Png_INCLUDE_DIR}")
        else()
            add_library(${inTargetName} STATIC IMPORTED)

            set_target_properties(${inTargetName} PROPERTIES
                IMPORTED_LOCATION "${Png_LIBRARY}")

            target_include_directories(${inTargetName} INTERFACE
                "${Png_INCLUDE_DIR}")

            target_link_libraries(${inTargetName} INTERFACE z)
        endif()
    endfunction()

endif()

