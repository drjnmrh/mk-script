if (NOT UNIX AND NOT WINDOWS)
    message(FATAL_ERROR "This script is only for unix or windows systems!")
endif()

set(smile_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
)

add_executable(smile
    ${smile_SOURCES}
)

smile_setup_common_flags(smile)

target_include_directories(smile PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(smile PUBLIC
    smile-core opengl-utils glfw glew
)

add_custom_command(TARGET smile POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:smile>/assets/shaders)

add_custom_command(TARGET smile POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/shaders $<TARGET_FILE_DIR:smile>/assets/shaders)

add_custom_command(TARGET smile POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/../assets $<TARGET_FILE_DIR:smile>/assets)

if (WINDOWS)
    set_property(DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT smile)

    set_target_properties(smile PROPERTIES
        VS_DEBUGGER_WORKING_DIRECTORY "$<TARGET_FILE_DIR:smile>"
    )

    add_custom_command(TARGET smile POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${Png_LIBRARY} $<TARGET_FILE_DIR:smile>)
endif()
