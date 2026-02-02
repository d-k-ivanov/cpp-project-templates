# ###############################################################################
# Qt-related helpers and options
# ###############################################################################

function(qt_automoc_properties)
    set(optionArgs "")
    set(oneValueArgs TARGET)
    set(multiValueArgs "")
    cmake_parse_arguments(this_func "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT DEFINED this_func_TARGET)
        message(FATAL_ERROR "set_automoc_properties requires TARGET")
    endif()

    set_property(TARGET ${this_func_TARGET} PROPERTY AUTOMOC ON)
    set_property(TARGET ${this_func_TARGET} PROPERTY AUTORCC ON)
    set_property(TARGET ${this_func_TARGET} PROPERTY AUTOUIC ON)
endfunction()

function(qt_deploy TARGET_NAME)
    if(WIN32)
        get_target_property(_qmake_executable Qt${QT_VERSION_MAJOR}::qmake IMPORTED_LOCATION)
        get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
        set(WINDEPLOYQT_EXECUTABLE "${_qt_bin_dir}/windeployqt.exe")
        set(WINDEPLOYQT_EXECUTABLE_DEBUG "${_qt_bin_dir}/windeployqt.debug.bat")

        if(EXISTS "${WINDEPLOYQT_EXECUTABLE}" AND EXISTS "${WINDEPLOYQT_EXECUTABLE_DEBUG}")
            get_filename_component(CMAKE_CXX_COMPILER_BINPATH ${CMAKE_CXX_COMPILER} DIRECTORY)
            add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E
                env PATH="${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/$<IF:$<CONFIG:Debug>,debug,>/bin"
                $<IF:$<CONFIG:Debug>,"${WINDEPLOYQT_EXECUTABLE_DEBUG}","${WINDEPLOYQT_EXECUTABLE}">
                $<IF:$<CONFIG:Debug>,--debug,--release>
                --verbose 0
                --dir "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                --no-translations
                \"$<TARGET_FILE:${TARGET_NAME}>\"
                COMMENT "Running windeployqt ... "
            )

            # Deploy again in to separate directory for install to pick up later
            add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E
                env PATH="${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/$<IF:$<CONFIG:Debug>,debug,>/bin"
                $<IF:$<CONFIG:Debug>,"${WINDEPLOYQT_EXECUTABLE_DEBUG}","${WINDEPLOYQT_EXECUTABLE}">
                $<IF:$<CONFIG:Debug>,--debug,--release>
                --verbose 0
                --dir "$<TARGET_FILE_DIR:${TARGET_NAME}>/winqt"
                --no-translations
                \"$<TARGET_FILE:${TARGET_NAME}>\"
                COMMENT "Running windeployqt [Installer] ... "
            )

            # DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/$<IF:$<CONFIG:Debug>,plugins,winqt>/"
            install(
                DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/winqt/"
                COMPONENT ${TARGET_NAME}
                DESTINATION "."
            )
        endif()
    elseif(UNIX AND NOT APPLE )
        set(_qt_lib_dir_release "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib")
        set(_qt_lib_dir_debug "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib")
        set(_qt_plugins_dir_release "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/Qt6/plugins")
        set(_qt_plugins_dir_debug "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/Qt6/plugins")

        set(_qt_plugins_list
            egldeviceintegrations           # EGL device integration plugins
            generic                         # Generic input support
            imageformats                    # Image format plugins (PNG, JPEG, etc.)
            networkinformation              # Network information plugins
            platforminputcontexts           # Platform input context plugins (IBus, etc.)
            platforms                       # Platform plugins (xcb for X11)
            platformthemes                  # Platform theme plugins (GTK, etc.)
            sqldrivers                      # SQL database drivers
            tls                             # TLS backend plugins
            xcbglintegrations               # XCB OpenGL integration
        )

        # Install Selected Qt Plugins
        foreach(_qt_plugin ${_qt_plugins_list})
            install(
                DIRECTORY "$<IF:$<CONFIG:Debug>,${_qt_plugins_dir_debug},${_qt_plugins_dir_release}>/${_qt_plugin}"
                DESTINATION "plugins"
                COMPONENT ${TARGET_NAME}
                FILES_MATCHING PATTERN "*.so*"
            )
        endforeach()

        # Install All Qt Plugins
        # install(
        #     DIRECTORY "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/Qt6/plugins/"
        #     DESTINATION "plugins"
        #     COMPONENT ${TARGET_NAME}
        #     FILES_MATCHING PATTERN "*"
        #     PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
        # )

        # Install libQt6XcbQpa library separately:
        install(CODE "
            set(_qt_lib_dir \"$<IF:$<CONFIG:Debug>,${_qt_lib_dir_debug},${_qt_lib_dir_release}>\")

            file(GLOB _qt_lib_files \"\${_qt_lib_dir}/libQt6XcbQpa.so\")
            if(_qt_lib_files)
                file(INSTALL
                    DESTINATION \"\${CMAKE_INSTALL_PREFIX}\"
                    TYPE SHARED_LIBRARY
                    FOLLOW_SYMLINK_CHAIN
                    FILES \${_qt_lib_files}
                )
            endif()
        " COMPONENT ${TARGET_NAME})

        # Fix RPATH for all installed dynamic libraries and handle missing dependencies
        install(CODE "
            file(GLOB INSTALLED_LIBS
                 \"\${CMAKE_INSTALL_PREFIX}/*.so*\")
            foreach(lib \${INSTALLED_LIBS})
                if(EXISTS \"\${lib}\" AND NOT IS_SYMLINK \"\${lib}\")
                    execute_process(
                        COMMAND \${CMAKE_COMMAND} -E echo \"Fixing RPATH for library: \${lib}\"
                    )
                    execute_process(
                        COMMAND patchelf --set-rpath \"\$ORIGIN\" \"\${lib}\"
                        RESULT_VARIABLE PATCHELF_RESULT
                        ERROR_QUIET
                    )
                    if(NOT PATCHELF_RESULT EQUAL 0)
                        execute_process(
                            COMMAND \${CMAKE_COMMAND} -E echo \"Warning: Failed to patch RPATH for \${lib}\"
                        )
                    endif()
                endif()
            endforeach()
        " COMPONENT ${TARGET_NAME})

        # Fix RPATH for all Qt plugin libraries to point to the application directory
        install(CODE "
            file(GLOB_RECURSE QT_PLUGINS
                 \"\${CMAKE_INSTALL_PREFIX}/plugins/*.so*\")
            foreach(plugin \${QT_PLUGINS})
                if(EXISTS \"\${plugin}\")
                    execute_process(
                        COMMAND \${CMAKE_COMMAND} -E echo \"Fixing RPATH for plugin: \${plugin}\"
                    )
                    execute_process(
                        COMMAND patchelf --set-rpath \"\$ORIGIN/..:$ORIGIN/../..:$ORIGIN\" \"\${plugin}\"
                        RESULT_VARIABLE PATCHELF_RESULT
                        ERROR_QUIET
                    )
                    if(NOT PATCHELF_RESULT EQUAL 0)
                        execute_process(
                            COMMAND \${CMAKE_COMMAND} -E echo \"Warning: Failed to patch RPATH for \${plugin}\"
                        )
                    endif()
                endif()
            endforeach()
        " COMPONENT ${TARGET_NAME})
    endif()

    # add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
    #     COMMAND "${CMAKE_COMMAND}" -E echo "[Platforms]"                        >  "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "WindowsArguments = dpiawareness=1"  >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo ""                                   >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "[Paths]"                            >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "Plugins = plugins"                  >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "Libraries = ."                      >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "Binaries = ."                       >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMENT "Creating qt.conf for development"
    # )

    # install(
    #     FILES "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMPONENT ${TARGET_NAME}
    #     DESTINATION "."
    # )

    # Install qt.conf
    install(
        FILES "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/qt.conf"
        COMPONENT ${TARGET_NAME}
        DESTINATION "."
        RENAME "qt.conf"
    )
endfunction(qt_deploy)


function(qt5_deploy TARGET_NAME)
    if(WIN32)
        get_target_property(_qmake_executable Qt${QT_VERSION_MAJOR}::qmake IMPORTED_LOCATION)
        get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
        set(WINDEPLOYQT_EXECUTABLE "${_qt_bin_dir}/windeployqt.exe")
        set(WINDEPLOYQT_EXECUTABLE_DEBUG "${_qt_bin_dir}/../debug/bin/windeployqt.exe")

        if(EXISTS "${WINDEPLOYQT_EXECUTABLE}" AND EXISTS "${WINDEPLOYQT_EXECUTABLE_DEBUG}")
            get_filename_component(CMAKE_CXX_COMPILER_BINPATH ${CMAKE_CXX_COMPILER} DIRECTORY)
            add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E
                env PATH="${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/$<IF:$<CONFIG:Debug>,debug,>/bin"
                $<IF:$<CONFIG:Debug>,"${WINDEPLOYQT_EXECUTABLE_DEBUG}","${WINDEPLOYQT_EXECUTABLE}">
                $<IF:$<CONFIG:Debug>,--debug,--release>
                --verbose 0
                --no-compiler-runtime
                --dir "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                --no-translations
                --no-angle
                \"$<TARGET_FILE:${TARGET_NAME}>\"
                COMMENT "Running windeployqt ... "
            )

            # Deploy again in to separate directory for install to pick up later
            add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E
                env PATH="${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/$<IF:$<CONFIG:Debug>,debug,>/bin"
                $<IF:$<CONFIG:Debug>,"${WINDEPLOYQT_EXECUTABLE_DEBUG}","${WINDEPLOYQT_EXECUTABLE}">
                $<IF:$<CONFIG:Debug>,--debug,--release>
                --verbose 0
                --no-compiler-runtime
                --dir "$<TARGET_FILE_DIR:${TARGET_NAME}>/winqt"
                --no-translations
                --no-angle
                \"$<TARGET_FILE:${TARGET_NAME}>\"
                COMMENT "Running windeployqt [Installer] ... "
            )

            # DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/$<IF:$<CONFIG:Debug>,plugins,winqt>/"
            install(
                DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/winqt/"
                COMPONENT ${TARGET_NAME}
                DESTINATION "."
            )
        endif()
    elseif(LINUX)
        set(_qt_lib_dir_release "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib")
        set(_qt_lib_dir_debug "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib")
        set(_qt_plugins_dir_release "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/plugins")
        set(_qt_plugins_dir_debug "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/plugins")

        set(_qt_plugins_list
            bearer                          # Network bearer plugins (deprecated)
            egldeviceintegrations           # EGL device integration plugins
            gamepads                        # Gamepad support plugins
            generic                         # Generic input support
            geometryloaders                 # 3D geometry file loaders
            iconengines                     # SVG icon engine support
            imageformats                    # Image format plugins (PNG, JPEG, etc.)
            platforminputcontexts           # Platform input context plugins (IBus, etc.)
            platforms                       # Platform plugins (xcb for X11)
            platformthemes                  # Platform theme plugins (GTK, etc.)
            qmltooling                      # QML debugging tools
            renderers                       # Qt3D renderers
            renderplugins                   # Qt3D render plugins
            sceneparsers                    # Qt3D scene parsers
            xcbglintegrations               # XCB OpenGL integration
        )

        # Install Selected Qt Plugins
        foreach(_qt_plugin ${_qt_plugins_list})
            install(
                DIRECTORY "$<IF:$<CONFIG:Debug>,${_qt_plugins_dir_debug},${_qt_plugins_dir_release}>/${_qt_plugin}"
                DESTINATION "plugins"
                COMPONENT ${TARGET_NAME}
                FILES_MATCHING PATTERN "*.so*"
            )
        endforeach()

        # Install All Qt Plugins
        # install(
        #     DIRECTORY "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/plugins/"
        #     DESTINATION "plugins"
        #     COMPONENT ${TARGET_NAME}
        #     FILES_MATCHING PATTERN "*"
        #     PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
        # )

        # Install libQt5XcbQpa library separately:
        install(CODE "
            set(_qt_lib_dir \"$<IF:$<CONFIG:Debug>,${_qt_lib_dir_debug},${_qt_lib_dir_release}>\")

            file(GLOB _qt_lib_files \"\${_qt_lib_dir}/libQt5XcbQpa.so\")
            if(_qt_lib_files)
                file(INSTALL
                    DESTINATION \"\${CMAKE_INSTALL_PREFIX}\"
                    TYPE SHARED_LIBRARY
                    FOLLOW_SYMLINK_CHAIN
                    FILES \${_qt_lib_files}
                )
            endif()
        " COMPONENT ${TARGET_NAME})

        # Fix RPATH for all installed dynamic libraries and handle missing dependencies
        install(CODE "
            file(GLOB INSTALLED_LIBS
                 \"\${CMAKE_INSTALL_PREFIX}/*.so*\")
            foreach(lib \${INSTALLED_LIBS})
                if(EXISTS \"\${lib}\" AND NOT IS_SYMLINK \"\${lib}\")
                    execute_process(
                        COMMAND \${CMAKE_COMMAND} -E echo \"Fixing RPATH for library: \${lib}\"
                    )
                    execute_process(
                        COMMAND patchelf --set-rpath \"\$ORIGIN\" \"\${lib}\"
                        RESULT_VARIABLE PATCHELF_RESULT
                        ERROR_QUIET
                    )
                    if(NOT PATCHELF_RESULT EQUAL 0)
                        execute_process(
                            COMMAND \${CMAKE_COMMAND} -E echo \"Warning: Failed to patch RPATH for \${lib}\"
                        )
                    endif()
                endif()
            endforeach()
        " COMPONENT ${TARGET_NAME})

        # Fix RPATH for all Qt plugin libraries to point to the application directory
        install(CODE "
            file(GLOB_RECURSE QT_PLUGINS
                 \"\${CMAKE_INSTALL_PREFIX}/plugins/*.so*\")
            foreach(plugin \${QT_PLUGINS})
                if(EXISTS \"\${plugin}\")
                    execute_process(
                        COMMAND \${CMAKE_COMMAND} -E echo \"Fixing RPATH for plugin: \${plugin}\"
                    )
                    execute_process(
                        COMMAND patchelf --set-rpath \"\$ORIGIN/..:$ORIGIN/../..:$ORIGIN\" \"\${plugin}\"
                        RESULT_VARIABLE PATCHELF_RESULT
                        ERROR_QUIET
                    )
                    if(NOT PATCHELF_RESULT EQUAL 0)
                        execute_process(
                            COMMAND \${CMAKE_COMMAND} -E echo \"Warning: Failed to patch RPATH for \${plugin}\"
                        )
                    endif()
                endif()
            endforeach()
        " COMPONENT ${TARGET_NAME})
    endif()

    # add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
    #     COMMAND "${CMAKE_COMMAND}" -E echo "[Platforms]"                        >  "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "WindowsArguments = dpiawareness=1"  >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo ""                                   >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "[Paths]"                            >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "Plugins = plugins"                  >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "Libraries = ."                      >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMAND "${CMAKE_COMMAND}" -E echo "Binaries = ."                       >> "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMMENT "Creating qt.conf for development"
    # )

    # install(
    #     FILES "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
    #     COMPONENT ${TARGET_NAME}
    #     DESTINATION "."
    # )

    install(
        FILES "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/qt.conf"
        COMPONENT ${TARGET_NAME}
        DESTINATION "."
        RENAME "qt.conf"
    )
endfunction(qt5_deploy)
