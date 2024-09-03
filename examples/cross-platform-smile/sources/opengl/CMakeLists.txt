set(opengl_utils_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/include/api.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/include/shader.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/include/errors.hpp
)

set(opengl_utils_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/api.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/shader.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/errors.cpp
)

add_library(opengl-utils STATIC ${opengl_utils_HEADERS} ${opengl_utils_SOURCES})

source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/include PREFIX "[headers]" FILES ${opengl_utils_HEADERS})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} PREFIX "[sources]" FILES ${opengl_utils_SOURCES})

target_include_directories(opengl-utils PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include ${GLM_DIR}/include)
target_include_directories(opengl-utils PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

smile_setup_common_flags(opengl-utils)
smile_setup_library_flags(opengl-utils)

if (ANDROID)
    target_link_libraries(opengl-utils PUBLIC smile-core EGL GLESv3)
else()
    if (WINDOWS)
        set(_glLib opengl32)
    else()
        set(_glLib GL)
    endif()
    target_link_libraries(opengl-utils PUBLIC smile-core glew glfw ${_glLib})
endif()
