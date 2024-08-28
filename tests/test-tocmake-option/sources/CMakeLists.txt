cmake_minimum_required(VERSION 3.20)

option(VERBOSE "Verbose script flag" OFF)
option(CUSTOM_OPTION "Custom option" OFF)

enable_testing()

project(main LANGUAGES C CXX)

add_executable(main ${CMAKE_SOURCE_DIR}/main.cpp)
target_compile_options(main PRIVATE "-std=c++20")
if (${CUSTOM_OPTION})
    target_compile_definitions(main PRIVATE CUSTOM_OPTION)
endif()

add_test(NAME test-default-run COMMAND main)
