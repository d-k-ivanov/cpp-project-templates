cmake_minimum_required(VERSION 3.22)

option(VERBOSE_OUTPUT OFF)

set(PROJECT_NAME app)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_CXX_EXTENSIONS FALSE)

list(APPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

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
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/resources/app.rc.in" "${CMAKE_CURRENT_BINARY_DIR}/app.rc")

set(SOURCE_FILES

    # Main
    source/main.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/app.rc

    # Some sources
    # source/SomeSourceFile.cpp
    # source/SomeHeaderFile.h

    # Shaders
    # resources/Shaders/SomeFragmentShader.frag
    # resources/Shaders/VertexShader.vert
)
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${SOURCE_FILES})

get_property(isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

if(isMultiConfig)
    # dummy target to ensure that resources are up-to-date
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/dummy")
        message(FATAL_ERROR "\"${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/dummy\" exists, remove it!")
    endif()

    add_custom_target(
        always_run_target ALL
        DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/dummy" # fake! ensure we run!
    )

    add_custom_command(
        OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/dummy" # fake! ensure we run!
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/resources"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/resources"
        "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/resources"
    )
else()
    # dummy target to ensure that resources are up-to-date
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/dummy")
        message(FATAL_ERROR "\"${CMAKE_CURRENT_BINARY_DIR}/dummy\" exists, remove it!")
    endif()

    add_custom_target(
        always_run_target ALL
        DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/dummy" # fake! ensure we run!
    )

    add_custom_command(
        OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/dummy" # fake! ensure we run!
        "${CMAKE_CURRENT_BINARY_DIR}/resources"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/resources"
        "${CMAKE_CURRENT_BINARY_DIR}/resources"
    )
endif()

# Install resources directory
install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/resources/"
    DESTINATION "resources"
    COMPONENT ${PROJECT_NAME}
)

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

target_link_directories(${PROJECT_NAME} PUBLIC
    "$<$<CONFIG:Release>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib>"
    "$<$<CONFIG:RelWithDebInfo>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib>"
    "$<$<CONFIG:Debug>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib>"
)

target_link_directories(${PROJECT_NAME} PRIVATE
    "$<$<CONFIG:Release>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib>"
    "$<$<CONFIG:RelWithDebInfo>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib>"
    "$<$<CONFIG:Debug>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib>"
)

target_link_directories(${PROJECT_NAME} INTERFACE
    "$<$<CONFIG:Release>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib>"
    "$<$<CONFIG:RelWithDebInfo>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib>"
    "$<$<CONFIG:Debug>:${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib>"
)

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

# Platform-specific dynamic library deployment
if(WIN32)
    # Install PDB files
    if(MSVC)
        install(FILES $<TARGET_PDB_FILE:${PROJECT_NAME}> COMPONENT ${PROJECT_NAME} DESTINATION "." OPTIONAL)
    endif()

    # Install Visual C++ Redistributable libraries
    set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
    include(InstallRequiredSystemLibraries)

    # Copy system runtime libraries to build directory
    foreach(lib ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS})
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${lib}" "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
            COMMENT "Copying system runtime library: ${lib}"
        )
        install(FILES "${lib}" COMPONENT ${PROJECT_NAME} DESTINATION ".")
    endforeach()

    # Copy VCPKG dynamic libraries to build directory
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/$<IF:$<CONFIG:Debug>,debug,>/bin"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMENT "Copying VCPKG dynamic libraries to build directory"
    )

    # Install dynamic libraries using GET_RUNTIME_DEPENDENCIES
    install(CODE "set(TARGET_FILE \"$<TARGET_FILE:${PROJECT_NAME}>\")" COMPONENT ${PROJECT_NAME})
    install(
        CODE [[
            file(
                GET_RUNTIME_DEPENDENCIES
                RESOLVED_DEPENDENCIES_VAR RES_DEP
                UNRESOLVED_DEPENDENCIES_VAR UNRES_DEP
                CONFLICTING_DEPENDENCIES_PREFIX CONF_DEP
                PRE_EXCLUDE_REGEXES
                    "api-ms-*"
                    "ext-ms-*"
                POST_EXCLUDE_REGEXES
                    ".*system32.*\\.dll"
                    ".*SysWOW64.*\\.dll"
                    ".*Windows.*\\.dll"
                EXECUTABLES "${TARGET_FILE}"
                DIRECTORIES
                    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin"
                    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/bin"
            )

            # Copy resolved dependencies:
            foreach(dep ${RES_DEP})
                file(
                    INSTALL
                    DESTINATION "${CMAKE_INSTALL_PREFIX}"
                    TYPE SHARED_LIBRARY
                    FOLLOW_SYMLINK_CHAIN
                    FILES ${dep}
                )
            endforeach()

            # Report unresolved dependencies:
            foreach(dep ${UNRES_DEP})
                message(WARNING "Unresolved dependency: ${dep}")
            endforeach()

            # Report conflicting dependencies:
            foreach(dep ${CONF_DEP})
                message(WARNING "Conflicting dependency: ${dep}")
            endforeach()
        ]]
        COMPONENT ${PROJECT_NAME}
    )

elseif(UNIX AND NOT APPLE)
    # Copy VCPKG dynamic libraries to build directory
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/$<IF:$<CONFIG:Debug>,debug,>/lib"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMENT "Copying VCPKG dynamic libraries to build directory"
    )

    # Copy Qt plugins
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/Qt6/plugins"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/plugins"
        COMMENT "Copying Qt plugins to build directory"
    )

    # Wrapper script to set environment variables and run the app
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/resources/run_app.sh.in"
        "${CMAKE_CURRENT_BINARY_DIR}/run_app.sh"
        @ONLY
    )

    # Copy the wrapper script to the target directory and make it executable
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy
        "${CMAKE_CURRENT_BINARY_DIR}/run_app.sh"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/run_app.sh"
        COMMAND chmod +x "$<TARGET_FILE_DIR:${PROJECT_NAME}>/run_app.sh"
        COMMENT "Creating wrapper script for ${PROJECT_NAME}"
    )

    # Set RPATH for the executable to look for libraries in the same directory
    set_target_properties(${PROJECT_NAME} PROPERTIES
        # BUILD_RPATH "$ORIGIN"
        INSTALL_RPATH "$ORIGIN:$ORIGIN/lib:$ORIGIN/plugins"
        BUILD_RPATH_USE_ORIGIN TRUE
        INSTALL_RPATH_USE_LINK_PATH FALSE
        BUILD_WITH_INSTALL_RPATH FALSE
        SKIP_BUILD_RPATH FALSE
        CMAKE_SKIP_INSTALL_RPATH FALSE
    )

    set_property(TARGET ${PROJECT_NAME} PROPERTY BUILD_RPATH
        "$ORIGIN"
        "$ORIGIN/plugins"
    )

    if(EXISTS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib")
        set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY BUILD_RPATH "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib")
    endif()

    if(EXISTS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib")
        set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY BUILD_RPATH "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib")
    endif()


    get_target_property(QT_CORE_LIB Qt6::Core IMPORTED_LOCATION)
    if(QT_CORE_LIB)
        get_filename_component(QT_LIB_DIR "${QT_CORE_LIB}" DIRECTORY)
    endif()

    if(QT_LIB_DIR AND EXISTS "${QT_LIB_DIR}")
        set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY BUILD_RPATH "${QT_LIB_DIR}")
    endif()

    # Install Qt plugins
    install(
        DIRECTORY "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/Qt6/plugins/"
        DESTINATION "plugins"
        COMPONENT ${PROJECT_NAME}
        FILES_MATCHING PATTERN "*"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )

    # Install wrapper script
    install(
        FILES "${CMAKE_CURRENT_BINARY_DIR}/run_app.sh"
        DESTINATION "."
        COMPONENT ${PROJECT_NAME}
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )

    # Install dynamic libraries using GET_RUNTIME_DEPENDENCIES
    install(CODE "set(TARGET_FILE \"$<TARGET_FILE:${PROJECT_NAME}>\")" COMPONENT ${PROJECT_NAME})
    install(
        CODE [[
            file(
                GET_RUNTIME_DEPENDENCIES
                RESOLVED_DEPENDENCIES_VAR RES_DEP
                UNRESOLVED_DEPENDENCIES_VAR UNRES_DEP
                CONFLICTING_DEPENDENCIES_PREFIX CONF_DEP
                PRE_EXCLUDE_REGEXES
                    "ld-linux.*"
                    ".*libc\\.so.*"
                    ".*libm\\.so.*"
                    ".*libdl\\.so.*"
                    ".*libpthread\\.so.*"
                    ".*librt\\.so.*"
                    ".*libgcc_s\\.so.*"
                    ".*libstdc\\+\\+\\.so.*"
                    ".*linux-vdso\\.so.*"
                POST_EXCLUDE_REGEXES
                    ".*/lib(64)?/.*"
                    ".*/usr/lib(64)?/.*"
                    ".*/lib/x86_64-linux-gnu/.*"
                EXECUTABLES "${TARGET_FILE}"
                DIRECTORIES
                    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib"
                    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib"
            )

            # Copy resolved dependencies:
            foreach(dep ${RES_DEP})
                file(
                    INSTALL
                    DESTINATION "${CMAKE_INSTALL_PREFIX}"
                    TYPE SHARED_LIBRARY
                    FOLLOW_SYMLINK_CHAIN
                    FILES "${dep}"
                )
            endforeach()

            # Report unresolved dependencies:
            foreach(dep ${UNRES_DEP})
                message(WARNING "Unresolved dependency: ${dep}")
            endforeach()

            # Report conflicting dependencies:
            foreach(dep ${CONF_DEP})
                message(WARNING "Conflicting dependency: ${dep}")
            endforeach()
        ]]
        COMPONENT ${PROJECT_NAME}
    )
endif()

add_subdirectory(cpack)

if(VERBOSE_OUTPUT)
    cmake_list_all_variables()
endif()
