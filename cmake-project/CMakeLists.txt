cmake_minimum_required(VERSION 3.10)
project(ProjectName LANGUAGES CXX VERSION 1.0.0.0)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(Common)
include(Policies)
include(Architecture)
include(CompilerFlags)
include(Macros)

# Set basic variables: output paths, install paths, lib paths, etc.
set_base_vars()

# Set PROJECT_VERSION_PATCH and PROJECT_VERSION_TWEAK to 0 if not present, needed by add_project_meta
fix_project_version()

# Set additional project information
set(COMPANY "Dmitriy Ivanov")
set(COPYRIGHT "Copyright (c) 2020 Dmitriy Ivanov. All rights reserved.")
set(IDENTIFIER "com.pupupon.dev.project-name")

include(Debug)
cmake_get_cxx_compiler()
cmake_list_all_init_variables()
#cmake_list_all_variables()
#cmake_get_includes()

file(WRITE  ${OUTPUT_DIR_MAIN}/about.txt "${COPYRIGHT}\n")
file(APPEND ${OUTPUT_DIR_MAIN}/about.txt "--------------------------------------------------------------------------------\n")
file(APPEND ${OUTPUT_DIR_MAIN}/about.txt "Application Name: ${CMAKE_PROJECT_NAME}\n")
file(APPEND ${OUTPUT_DIR_MAIN}/about.txt "Application Version: ${CMAKE_PROJECT_VERSION}\n")
file(APPEND ${OUTPUT_DIR_MAIN}/about.txt "Company: ${COMPANY}\n")
file(APPEND ${OUTPUT_DIR_MAIN}/about.txt "Identifier: ${IDENTIFIER}\n")

include_directories(SYSTEM ${CMAKE_SOURCE_DIR}/lib)
add_subdirectory("src")

# Testing
option(MAKE_TESTS "Set to ON to build tests" ON)
add_subdirectory(${CMAKE_SOURCE_DIR}/test)
