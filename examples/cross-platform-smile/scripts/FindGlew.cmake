set(_Glew_SEARCH_PATH "${CMAKE_BINARY_PATH}")

if (DEFINED GLEW_DIR)
    list(APPEND _Glew_SEARCH_PATH "${GLEW_DIR}")
endif()

if (${VERBOSE})
    message(STATUS "* GLEW SEARCH PATH = ${_Glew_SEARCH_PATH}")
endif()

find_path(Glew_INCLUDE_DIR
    NAME glew.h
    PATHS ${_Glew_SEARCH_PATH}
    PATH_SUFFIXES "${PLATFORM_NAME}-${ARCH}/include/GL"
    NO_SYSTEM_ENVIRONMENT_PATH)

if (WINDOWS)
    set(_libName glew32s)
else()
    set(_libName GLEW)
endif()

find_library(Glew_LIBRARY
    NAMES ${_libName}
    PATHS ${_Glew_SEARCH_PATH}
    PATH_SUFFIXES "${PLATFORM_NAME}-${ARCH}/lib" "${PLATFORM_NAME}-${ARCH}/lib64"
    NO_SYSTEM_ENVIRONMENT_PATH)

if (Glew_LIBRARY)
    set(Glew_LIBRARIES_FOUND TRUE)
endif()

if (${VERBOSE})
    message(STATUS "* Glew INCLUDE DIR     = ${Glew_INCLUDE_DIR}")
    message(STATUS "* Glew LIBRARY         = ${Glew_LIBRARY}")
    message(STATUS "* Glew LIBRARIES FOUND = ${Glew_LIBRARIES_FOUND}")
endif()

if (Glew_INCLUDE_DIR AND Glew_LIBRARIES_FOUND)
    message(STATUS "Find Glew - Success")
    set(Glew_INCLUDE_DIR "${Glew_INCLUDE_DIR}/..")
    set(Glew_FOUND TRUE)
else ()
    message(STATUS "Find Glew - Failed")
    set(Glew_FOUND FALSE)
    if (Glew_FIND_REQUIRED)
        message(FATAL_ERROR "Glew NOT FOUND\nDetails:\n${_Glew_SEARCH_PATH}\n${PLATFORM_NAME}-${ARCH}")
    endif()
endif()

mark_as_advanced(Glew_FOUND Glew_INCLUDE_DIR Glew_LIBRARY)

macro(add_glew_library inTargetName)
    if (WINDOWS)
        add_library(${inTargetName} STATIC IMPORTED)

        target_compile_definitions(${inTargetName} INTERFACE GLEW_STATIC)
    else()
        add_library(${inTargetName} SHARED IMPORTED)
    endif()

    set_target_properties(${inTargetName} PROPERTIES
        IMPORTED_LOCATION "${Glew_LIBRARY}")

    target_include_directories(${inTargetName} INTERFACE
        "${Glew_INCLUDE_DIR}")
endmacro()

