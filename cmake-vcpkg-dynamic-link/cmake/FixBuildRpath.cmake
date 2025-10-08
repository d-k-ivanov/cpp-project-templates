# FixBuildRpath.cmake
# Script to fix RPATH for copied dynamic libraries in the build directory

# Check if patchelf is available
find_program(PATCHELF_EXECUTABLE patchelf)

if(NOT PATCHELF_EXECUTABLE)
    message(WARNING "patchelf not found. Cannot fix RPATH for copied libraries. Install patchelf with: sudo apt-get install patchelf")
    return()
endif()

# Get the build directory (where the executable is located)
get_filename_component(BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}" ABSOLUTE)

message(STATUS "Fixing RPATH for libraries in: ${BUILD_DIR}")

# Find all shared libraries in the build directory (excluding the executable)
file(GLOB SHARED_LIBS "${BUILD_DIR}/*.so*")

# Also check for any libraries that might be in subdirectories
file(GLOB_RECURSE PLUGIN_LIBS "${BUILD_DIR}/plugins/*.so*")

# Combine both lists
set(ALL_LIBS ${SHARED_LIBS})

foreach(lib ${ALL_LIBS})
    # Skip symlinks and process only actual library files
    if(EXISTS "${lib}" AND NOT IS_SYMLINK "${lib}")
        # Skip the main executable
        get_filename_component(LIB_NAME "${lib}" NAME)

        if(LIB_NAME MATCHES "^app$")
            continue()
        endif()

        message(STATUS "Fixing RPATH for library: ${lib}")

        # Use patchelf to set the RPATH to $ORIGIN so libraries can find each other
        execute_process(
            COMMAND "${PATCHELF_EXECUTABLE}" --set-rpath "$ORIGIN" "${lib}"
            RESULT_VARIABLE PATCHELF_RESULT
            ERROR_VARIABLE PATCHELF_ERROR
            OUTPUT_QUIET
        )

        if(NOT PATCHELF_RESULT EQUAL 0)
            message(WARNING "Failed to patch RPATH for ${lib}: ${PATCHELF_ERROR}")
        else()
            message(STATUS "Successfully set RPATH to $ORIGIN for ${lib}")
        endif()
    endif()
endforeach()

# Handle Qt plugins specifically to ensure they can find libraries in the parent directory
file(GLOB_RECURSE QT_PLUGINS "${BUILD_DIR}/plugins/*.so*")

foreach(plugin ${QT_PLUGINS})
    if(EXISTS "${plugin}" AND NOT IS_SYMLINK "${plugin}")
        message(STATUS "Fixing RPATH for Qt plugin: ${plugin}")

        # Qt plugins need to find libraries in both the parent directory and two levels up
        execute_process(
            COMMAND "${PATCHELF_EXECUTABLE}" --set-rpath "$ORIGIN/..:$ORIGIN/../..:$ORIGIN" "${plugin}"
            RESULT_VARIABLE PATCHELF_RESULT
            ERROR_VARIABLE PATCHELF_ERROR
            OUTPUT_QUIET
        )

        if(NOT PATCHELF_RESULT EQUAL 0)
            message(WARNING "Failed to patch RPATH for Qt plugin ${plugin}: ${PATCHELF_ERROR}")
        else()
            message(STATUS "Successfully set RPATH for Qt plugin ${plugin}")
        endif()
    endif()
endforeach()

message(STATUS "RPATH fixing completed")
