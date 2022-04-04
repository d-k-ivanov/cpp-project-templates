cmake_minimum_required(VERSION 3.10)
project(InitQTUI LANGUAGES CXX VERSION 0.1.0.0)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(Policies)
include(Architecture)
include(CompilerFlags)
include(QtCommon)
include(Macros)

# Set PROJECT_VERSION_PATCH and PROJECT_VERSION_TWEAK to 0 if not present, needed by add_project_meta
fix_project_version()

# Set additional project information
set(COMPANY "Dmitry Ivanov")
set(COPYRIGHT "Copyright (c) 2021 Dmitry Ivanov. All rights reserved.")
set(IDENTIFIER "io.github.d-k-ivanov.InitQTUI")

#set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

set(OUTPUT_DIR ${ARCH_PREFIX}-${CMAKE_BUILD_TYPE})

set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE          "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG            "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE          "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG            "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE          "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG            "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
if(MSVC)
    set(CMAKE_PDB_OUTPUT_DIRECTORY                  "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
    set(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_RELEASE  "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
    set(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_DEBUG    "${CMAKE_BINARY_DIR}/_out/${OUTPUT_DIR}")
endif()

include(Debug)
cmake_get_cxx_compiler()
cmake_list_all_init_variables()
#cmake_list_all_variables()
#cmake_get_includes()

# Thirdparty
add_subdirectory(${CMAKE_SOURCE_DIR}/thirdparty)

# Application
init_os_bundle()
init_qt()
#add_subdirectory(${CMAKE_SOURCE_DIR}/src)
set(SOURCE_FILES
    src/main.cpp
    src/main_window.cpp
)

add_project_meta(META_FILES_TO_INCLUDE)

set(RESOURCE_FILES InitQTUI.qrc)

find_package(Qt5Widgets REQUIRED)

add_executable(${CMAKE_PROJECT_NAME} ${OS_BUNDLE}
    ${SOURCE_FILES} ${META_FILES_TO_INCLUDE} ${RESOURCE_FILES}
)

if (MSVC)
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE YES
        LINK_FLAGS "/ENTRY:mainCRTStartup"
    )
endif()

# Testing
option(QT_UI_APP_BUILD_TESTS "Set to ON to build tests" OFF)
add_subdirectory(${CMAKE_SOURCE_DIR}/test)

qt5_use_modules(${CMAKE_PROJECT_NAME} Widgets)
