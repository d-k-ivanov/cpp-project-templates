cmake_minimum_required(VERSION 3.22)

set(PROJECT_NAME Lib2)
project(${PROJECT_NAME} VERSION ${CMAKE_PROJECT_VERSION} LANGUAGES CXX)

# Resource file
set(HEADER_FILES
    Include/Lib2/HelloWorld2.h
)

set(SOURCE_FILES
    Source/HelloWorld2.cpp
)

# Combine all files for the target
set(ALL_FILES ${SOURCE_FILES} ${HEADER_FILES})

# Organize source files in IDE
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${ALL_FILES})

get_property(isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

add_library(${PROJECT_NAME} ${ALL_FILES})
add_library(sample::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

set_target_properties(${PROJECT_NAME} PROPERTIES FOLDER Libs/Lib1)
set_target_properties(${PROJECT_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${HEADER_FILES}")

target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>")
target_include_directories(${PROJECT_NAME} PRIVATE "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_NAME}>")
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC "$<INSTALL_INTERFACE:include/>")
target_include_directories(${PROJECT_NAME} PRIVATE "$<INSTALL_INTERFACE:include/${PROJECT_NAME}>")

# Use WinMain as a default endpoint on Windows
if(WIN32)
    set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE "$<IF:$<CONFIG:Release>,TRUE,${CMAKE_WIN32_EXECUTABLE}>")
endif()

# Enable PDB files in the Release configuration and a couple of useful flags
if(MSVC)
    target_compile_options(${PROJECT_NAME} PUBLIC "/Zc:__cplusplus")
    target_compile_options(${PROJECT_NAME} PUBLIC "$<$<CONFIG:Release>:/Zi>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<CONFIG:Release>:/DEBUG:FASTLINK>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<CONFIG:Release>:/OPT:REF>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<CONFIG:Release>:/OPT:ICF>")
    target_compile_options(${PROJECT_NAME} PUBLIC "/MP")
endif()

target_link_libraries(
    ${PROJECT_NAME}
)

sbom_generate(
    OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.spdx.json"
    DOCUMENT_NAME "${PROJECT_NAME}-SBOM"
    DOCUMENT_NAMESPACE "https://github.com/d-k-ivanov/cpp-project-templates/spdxdocs/${PROJECT_NAME}-v${CMAKE_PROJECT_VERSION}"

    # Main package information
    PACKAGE_NAME "${PROJECT_NAME}"
    PACKAGE_VERSION "${CMAKE_PROJECT_VERSION}"
    PACKAGE_DOWNLOAD_LOCATION "https://github.com/d-k-ivanov/cpp-project-templates"
    PACKAGE_HOMEPAGE "https://github.com/d-k-ivanov/cpp-project-templates"
    PACKAGE_SUPPLIER "Individual: Dmitry Ivanov"
    PACKAGE_LICENSE_CONCLUDED "NOASSERTION"
    PACKAGE_LICENSE_DECLARED "NOASSERTION"
    PACKAGE_COPYRIGHT "Copyright 2025-${CMAKE_DATE_YEAR} Dmitry Ivanov"
    PACKAGE_SUMMARY "${PROJECT_NAME} library"
    PACKAGE_DESCRIPTION "${PROJECT_NAME} library"
    PACKAGE_PURPOSE "LIBRARY"

    # Creation information
    CREATORS "Tool: CMake-${CMAKE_VERSION}" "Individual: Dmitry Ivanov"

    # Include CMake targets automatically
    TARGETS ${PROJECT_NAME}

    # Include additional files
    FILES ${ALL_FILES}

    # External references (optional)
    PACKAGE_EXTERNAL_REFS
    "{\"referenceCategory\": \"SECURITY\", \"referenceType\": \"cpe23Type\", \"referenceLocator\": \"cpe:2.3:a:d-k-ivanov:${PROJECT_NAME}:${CMAKE_PROJECT_VERSION}:*:*:*:*:*:*:*\"}"
    "{\"referenceCategory\": \"PACKAGE-MANAGER\", \"referenceType\": \"purl\", \"referenceLocator\": \"pkg:generic/${PROJECT_NAME}@${CMAKE_PROJECT_VERSION}\"}"
)
