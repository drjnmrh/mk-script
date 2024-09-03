cmake_minimum_required(VERSION 3.20)

option(VERBOSE "Sets verbose mode flag" OFF)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(cross-compile LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)

add_executable(cross-compile ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

