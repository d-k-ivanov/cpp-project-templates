cmake_minimum_required(VERSION 3.22)

set(PROJECT_NAME App1)
project(${PROJECT_NAME} VERSION ${CMAKE_PROJECT_VERSION} LANGUAGES CXX)

# Resource file
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Resources/App.rc.in" "${CMAKE_CURRENT_BINARY_DIR}/App.rc")

set(SOURCE_FILES
    Source/Main.cpp
)

set(GENERATED_FILES
    ${CMAKE_CURRENT_BINARY_DIR}/App.rc
)

# Organize source files in IDE
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${SOURCE_FILES})
source_group("Generated Files" FILES ${GENERATED_FILES})

# Combine all files for the target
set(ALL_FILES ${SOURCE_FILES} ${GENERATED_FILES})

get_property(isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

if(isMultiConfig)
    # Dummy target to ensure that resources are up-to-date
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Dummy")
        message(FATAL_ERROR "\"${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Dummy\" exists, remove it!")
    endif()

    add_custom_target(
        always_run_target1 ALL
        DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Dummy" # fake! ensure we run!
    )

    add_custom_command(
        OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Dummy" # fake! ensure we run!
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Resources"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/Resources"
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Resources"
    )
else()
    # Dummy target to ensure that resources are up-to-date
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/Dummy")
        message(FATAL_ERROR "\"${CMAKE_CURRENT_BINARY_DIR}/Dummy\" exists, remove it!")
    endif()

    add_custom_target(
        always_run_target1 ALL
        DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/Dummy" # fake! ensure we run!
    )

    add_custom_command(
        OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/Dummy" # fake! ensure we run!
        "${CMAKE_CURRENT_BINARY_DIR}/Resources"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/Resources"
        "${CMAKE_CURRENT_BINARY_DIR}/Resources"
    )
endif()

find_package(glfw3 CONFIG REQUIRED)
find_package(glm CONFIG REQUIRED)
find_package(GLUT REQUIRED)

add_executable(${PROJECT_NAME} ${ALL_FILES})
add_executable(sample::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

add_dependencies(${PROJECT_NAME} always_run_target1)

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
    sample::Lib1
    glfw
    glm::glm-header-only
    GLUT::GLUT
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
    PACKAGE_SUMMARY "${PROJECT_NAME} application"
    PACKAGE_DESCRIPTION "${PROJECT_NAME} application"
    PACKAGE_PURPOSE "APPLICATION"

    # Creation information
    CREATORS "Tool: CMake-${CMAKE_VERSION}" "Individual: Dmitry Ivanov"

    # Include CMake targets automatically
    TARGETS ${PROJECT_NAME} sample::Lib1 glfw glm::glm-header-only GLUT::GLUT

    # Include additional files
    FILES ${ALL_FILES}

    # External references (optional)
    PACKAGE_EXTERNAL_REFS
    "{\"referenceCategory\": \"SECURITY\", \"referenceType\": \"cpe23Type\", \"referenceLocator\": \"cpe:2.3:a:d-k-ivanov:${PROJECT_NAME}:${CMAKE_PROJECT_VERSION}:*:*:*:*:*:*:*\"}"
    "{\"referenceCategory\": \"PACKAGE-MANAGER\", \"referenceType\": \"purl\", \"referenceLocator\": \"pkg:generic/${PROJECT_NAME}@${CMAKE_PROJECT_VERSION}\"}"
)
