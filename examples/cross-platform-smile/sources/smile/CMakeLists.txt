set(smile_core_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/include/smile/log.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/include/smile/logging.h
    ${CMAKE_CURRENT_SOURCE_DIR}/include/smile/smile.h
)

if (APPLE)
    set(_loggingSrc apple/logging.m)
elseif (ANDROID)
    set(_loggingSrc android/logging.cpp)
else ()
    set(_loggingSrc desktop/logging.cpp)
endif()

set(smile_core_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/smile.cpp

    ${CMAKE_CURRENT_SOURCE_DIR}/imageutils.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/imageutils.cpp

    ${CMAKE_CURRENT_SOURCE_DIR}/${_loggingSrc}
)

add_library(smile-core STATIC ${smile_core_SOURCES} ${smile_core_HEADERS})

source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/include/smile PREFIX "[headers]" FILES ${smile_core_HEADERS})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} PREFIX "[sources]" FILES ${smile_core_SOURCES})

target_include_directories(smile-core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_include_directories(smile-core PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

smile_setup_common_flags(smile-core)
smile_setup_library_flags(smile-core)

find_package(Png REQUIRED)
add_png_library(png)

target_link_libraries(smile-core PRIVATE png)

if (APPLE)
    target_link_libraries(smile-core PUBLIC "-framework Foundation")
endif()

