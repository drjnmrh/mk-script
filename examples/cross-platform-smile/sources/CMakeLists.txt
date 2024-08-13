cmake_minimum_required(VERSION 3.20)

option(VERBOSE "Set verbose mode" OFF)
option(APPLE_TEAM "Set Apple Dev team" OFF)
option(APPLE_SIGNID "Set Apple Sign Id" "Apple Development")
option(PNG_DIR "Set path to a static libPng prefix" OFF)
option(SDL2_DIR "Set path to prebuilt Unix x86_64 SDL2 library" OFF)
option(SUPPORT_VIM "Add Vim supporting steps" OFF)
option(GLM_DIR "Path to GLM headers-only library" OFF)
option(ANDROID_DIR "Path to Android SDK" OFF)
option(NDK_DIR "Path to Android NDK" OFF)
option(OSX_BUNDLE "Name of the iPhone or MacOSX app bundle" "smile")

if (NOT APPLE_SIGNID)
    set(APPLE_SIGNID "Apple Development")
endif()

if (NOT OSX_BUNDLE)
    set(OSX_BUNDLE "smile")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(smile LANGUAGES C CXX)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/../scripts")
include(Utils)
include(Platform)
smile_detect_platform(PLATFORM_NAME)

message(STATUS "Target platform: ${PLATFORM_NAME} ${ARCH}")
message(STATUS "Host platform  : ${CMAKE_HOST_SYSTEM}")

set(ASSETS_DIR "${CMAKE_SOURCE_DIR}/../assets")

add_subdirectory(smile)

if (APPLE)
    add_subdirectory(apple)
elseif (UNIX OR WINDOWS AND NOT ANDROID)
    find_package(Glew REQUIRED)
    add_glew_library(glew)

    find_package(Glfw REQUIRED)
    add_glfw_library(glfw)

    add_subdirectory(opengl)
    add_subdirectory(desktop)
elseif (ANDROID)
    add_subdirectory(opengl)
    add_subdirectory(android)
endif()

if (${SUPPORT_VIM})
    set_vim_ycm_settings(smile)
endif()
