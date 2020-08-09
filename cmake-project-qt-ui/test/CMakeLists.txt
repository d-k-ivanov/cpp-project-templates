set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/tests)

if(QT_UI_APP_BUILD_TESTS)
    add_executable(unicode_test "unicode.cpp")
endif()

