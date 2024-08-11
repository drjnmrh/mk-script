cmake_minimum_required(VERSION 3.20)

option(VERBOSE "Verbose script flag" OFF)

enable_testing()

project(main LANGUAGES C CXX)

add_executable(main ${CMAKE_SOURCE_DIR}/main.cpp)
target_compile_options(main PRIVATE "-std=c++20")

add_test(NAME test-source-option COMMAND main)

