cmake_minimum_required(VERSION 3.20)

option(VERBOSE "Verbose mode flag" OFF)

enable_testing()

project(test_toolchain_option LANGUAGES CXX)

add_executable(main ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

if (WITH_TOOLCHAIN)
    target_compile_definitions(main PRIVATE WITH_TOOLCHAIN)
endif()

target_compile_options(main PRIVATE "-std=c++20")

add_test(NAME test-toolchain-option COMMAND main)

