set(_Glfw_SEARCH_PATH "${CMAKE_BINARY_PATH}")

if (DEFINED GLFW_DIR)
    list(APPEND _Glfw_SEARCH_PATH "${GLFW_DIR}")
endif()

if (${VERBOSE})
    message(STATUS "* GLFW SEARCH PATH = ${_Glfw_SEARCH_PATH}")
endif()

find_path(Glfw_INCLUDE_DIR
    NAME glfw3.h
    PATHS ${_Glfw_SEARCH_PATH}
    PATH_SUFFIXES "${PLATFORM_NAME}-${ARCH}/include/GLFW"
    NO_SYSTEM_ENVIRONMENT_PATH)

find_library(Glfw_LIBRARY
    NAMES glfw3
    PATHS ${_Glfw_SEARCH_PATH}
    PATH_SUFFIXES "${PLATFORM_NAME}-${ARCH}/lib"
    NO_SYSTEM_ENVIRONMENT_PATH)

if (Glfw_LIBRARY)
    set(Glfw_LIBRARIES_FOUND TRUE)
endif()

if (${VERBOSE})
    message(STATUS "* Glfw INCLUDE DIR     = ${Glfw_INCLUDE_DIR}")
    message(STATUS "* Glfw LIBRARY         = ${Glfw_LIBRARY}")
    message(STATUS "* Glfw LIBRARIES FOUND = ${Glfw_LIBRARIES_FOUND}")
endif()

if (Glfw_INCLUDE_DIR AND Glfw_LIBRARIES_FOUND)
    message(STATUS "Find Glfw - Success")
    set(Glfw_INCLUDE_DIR "${Glfw_INCLUDE_DIR}/..")
    set(Glfw_FOUND TRUE)
else ()
    message(STATUS "Find Glfw - Failed")
    set(Glfw_FOUND FALSE)
    if (Glfw_FIND_REQUIRED)
        message(FATAL_ERROR "Glfw NOT FOUND\nDetails:\n${_Glfw_SEARCH_PATH}\n${PLATFORM_NAME}-${ARCH}")
    endif()
endif()

mark_as_advanced(Glfw_FOUND Glfw_INCLUDE_DIR Glfw_LIBRARY)

function(add_glfw_library inTargetName)
    add_library(${inTargetName} STATIC IMPORTED)

    set_target_properties(${inTargetName} PROPERTIES
        IMPORTED_LOCATION "${Glfw_LIBRARY}")

    target_include_directories(${inTargetName} INTERFACE
        "${Glfw_INCLUDE_DIR}")
endfunction()

