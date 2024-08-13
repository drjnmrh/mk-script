set(native_lib_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/app/src/main/cpp/native-lib.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/app/src/main/cpp/shaders.glsl.h
)

add_library(smile SHARED ${native_lib_SOURCES})
smile_setup_common_flags(smile)

target_include_directories(smile PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/app/src/main/cpp
)

target_link_libraries(smile smile-core opengl-utils android log)

