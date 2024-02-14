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
                --no-compiler-runtime
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
                --no-compiler-runtime
                --dir "$<TARGET_FILE_DIR:${TARGET_NAME}>/winqt"
                --no-translations
                \"$<TARGET_FILE:${TARGET_NAME}>\"
                COMMENT "Running windeployqt [Installer] ... "
            )

            # DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/$<IF:$<CONFIG:Debug>,plugins,winqt>/"
            install(
                DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/winqt/"
                COMPONENT ${TARGET_NAME}
                DESTINATION "${CMAKE_INSTALL_BINDIR}"
            )

            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/qt.conf"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
            )

            install(
                DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
                COMPONENT ${TARGET_NAME}
                DESTINATION "${CMAKE_INSTALL_BINDIR}"
            )
        endif()
    endif(WIN32)
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
                DESTINATION "${CMAKE_INSTALL_BINDIR}"
            )

            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/qt.conf"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
            )

            install(
                DIRECTORY "$<TARGET_FILE_DIR:${TARGET_NAME}>/qt.conf"
                COMPONENT ${TARGET_NAME}
                DESTINATION "${CMAKE_INSTALL_BINDIR}"
            )
        endif()
    endif(WIN32)
endfunction(qt5_deploy)
