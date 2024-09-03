cmake_minimum_required(VERSION 3.20)

option(VERBOSE "Sets the verbose mode" OFF)

enable_testing()

project(simple-cli-tool LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)

add_executable(simple-cli-tool ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

add_test(NAME test01 COMMAND simple-cli-tool --test 1)
add_test(NAME test02 COMMAND simple-cli-tool --test 2)
add_test(NAME test03 COMMAND simple-cli-tool --test 3)
add_test(NAME test04 COMMAND simple-cli-tool --test 4)

