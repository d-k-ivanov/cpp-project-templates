cmake_minimum_required(VERSION 3.22)

option(VERBOSE_OUTPUT OFF)

set(PROJECT_NAME MyApp)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_CXX_EXTENSIONS FALSE)

list(APPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_LIST_DIR}/CMake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMake")

include(InitVCPKG)
include(Functions)
include(ToolchainUpdate)
include(GitVersion)
include(QtOptions)

# Git Version implementation for CMake
get_version_info("APP_NAME")

# Initialize Date and Time variables
init_time_and_date_variables()

project(${PROJECT_NAME} VERSION ${APP_NAME_VERSION_MAJOR}.${APP_NAME_VERSION_MINOR}.${APP_NAME_VERSION_PATCH}.${APP_NAME_VERSION_TWEAK} LANGUAGES CXX)

set(EXE_PLATFORM_KEYWORD "")

if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(EXE_PLATFORM_KEYWORD "")
elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    set(EXE_PLATFORM_KEYWORD "MACOSX_BUNDLE")
endif()

# Resource file
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Resources/App.rc.in" "${CMAKE_CURRENT_BINARY_DIR}/App.rc")

set(SOURCE_FILES

    # Main
    Source/Main.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/App.rc

    # Some sources
    # Source/SomeSourceFile.cpp
    # Source/SomeHeaderFile.h

    # Shaders
    # Resources/Shaders/SomeFragmentShader.frag
    # Resources/Shaders/VertexShader.vert
)
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${SOURCE_FILES})

get_property(isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

if(isMultiConfig)
    # Dummy target to ensure that resources are up-to-date
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Dummy")
        message(FATAL_ERROR "\"${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Dummy\" exists, remove it!")
    endif()

    add_custom_target(
        always_run_target ALL
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
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}//Dummy")
        message(FATAL_ERROR "\"${CMAKE_CURRENT_BINARY_DIR}/Dummy\" exists, remove it!")
    endif()

    add_custom_target(
        always_run_target ALL
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

find_package(Qt6Core CONFIG REQUIRED)
find_package(Qt6Gui CONFIG REQUIRED)
find_package(Qt6Widgets CONFIG REQUIRED)

add_executable(${PROJECT_NAME} ${SOURCE_FILES})
add_dependencies(${PROJECT_NAME} always_run_target)

# Use WinMain as a default endpoint on Windows
if(WIN32)
    set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE "$<IF:$<CONFIG:Release>,TRUE,${CMAKE_WIN32_EXECUTABLE}>")
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
endif()

qt_automoc_properties(TARGET ${PROJECT_NAME})
qt_deploy(${PROJECT_NAME})

# Enable PDB files in the Release configuration and a couple of useful flags
if(MSVC)
    target_compile_options(${PROJECT_NAME} PUBLIC "/Zc:__cplusplus")
    target_compile_options(${PROJECT_NAME} PUBLIC "$<$<CONFIG:Release>:/Zi>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<CONFIG:Release>:/DEBUG:FASTLINK>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<CONFIG:Release>:/OPT:REF>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<CONFIG:Release>:/OPT:ICF>")
    target_compile_options(${PROJECT_NAME} PUBLIC "/MP")
endif()

# Get the right link directories.
# target_link_directories(${PROJECT_NAME} PUBLIC
# "$<$<CONFIG:Release>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/lib>"
# "$<$<CONFIG:RelWithDebInfo>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/lib>"
# "$<$<CONFIG:Debug>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/debug/lib>"
# )

# target_link_directories(${PROJECT_NAME} PRIVATE
# "$<$<CONFIG:Release>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/lib>"
# "$<$<CONFIG:RelWithDebInfo>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/lib>"
# "$<$<CONFIG:Debug>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/debug/lib>"
# )

# target_link_directories(${PROJECT_NAME} INTERFACE
# "$<$<CONFIG:Release>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/lib>"
# "$<$<CONFIG:RelWithDebInfo>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/lib>"
# "$<$<CONFIG:Debug>:${VCPKG_EXPORT_PATH}/installed/${VCPKG_TARGET_TRIPLET}/debug/lib>"
# )
target_link_libraries(
    ${PROJECT_NAME}
    Qt::Core
    Qt::Gui
    Qt::Widgets
)

install(
    TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    COMPONENT ${PROJECT_NAME}
    LIBRARY DESTINATION "."
    ARCHIVE DESTINATION "."
    RUNTIME DESTINATION "."
)

if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${PROJECT_NAME}> COMPONENT ${PROJECT_NAME} DESTINATION ".")
    set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
    include(InstallRequiredSystemLibraries)
    install(CODE "set(TARGET_FILE \"$<TARGET_FILE:${PROJECT_NAME}>\")" COMPONENT ${PROJECT_NAME})

    foreach(lib ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS})
        get_filename_component(filename "${lib}" NAME)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${lib}" \"$<TARGET_FILE_DIR:${PROJECT_NAME}>\"
        )
        install(FILES "${lib}" COMPONENT ${PROJECT_NAME} DESTINATION ".")
    endforeach()

    install(
        CODE [[
            file(
                GET_RUNTIME_DEPENDENCIES
                RESOLVED_DEPENDENCIES_VAR RES_DEP
                UNRESOLVED_DEPENDENCIES_VAR UNRES_DEP
                CONFLICTING_DEPENDENCIES_PREFIX CONF_DEP
                PRE_EXCLUDE_REGEXES "api-ms-*"
                POST_EXCLUDE_REGEXES ".*system32.*\\.dll"
                EXECUTABLES "${TARGET_FILE}"
            )
            foreach(dep ${RES_DEP})
                file(
                    INSTALL
                    DESTINATION "${CMAKE_INSTALL_PREFIX}"
                    TYPE SHARED_LIBRARY
                    FOLLOW_SYMLINK_CHAIN
                    FILES ${dep}
                )
            endforeach()

            foreach(dep ${UNRES_DEP})
                message(WARNING "Dependency not found: ${dep}")
            endforeach()
        ]]
        COMPONENT ${PROJECT_NAME}
    )
endif()

add_subdirectory(CPack)

if(VERBOSE_OUTPUT)
    cmake_list_all_variables()
endif()
