/*
 * =====================================================================
 *      Project :  project-name
 *      File    :  main.cpp
 *      Created :  15.12.2021
 *      Author  :  Dmitry Ivanov
 * =====================================================================
 */

#include "main.h"

#include <functional>
#include <iostream>

#ifdef _WIN32
#include <Windows.h>
#endif

// Libraries
#include <fmt/core.h>
#include <spdlog/spdlog.h>

int main(int argc, char* argv[], char* env[])
{
    // To turn off messages about unused variables.
    ((void)argc );
    ((void)argv );
    ((void)env );

    #ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    #endif

    std::string s = fmt::format("The answer is {}.", 42);
    std::cout << s << std::endl;

    spdlog::info("Welcome to spdlog!");
    spdlog::error("Some error message with arg: {}", 1);

    spdlog::warn("Easy padding in numbers like {:08d}", 12);
    spdlog::critical("Support for int: {0:d};  hex: {0:x};  oct: {0:o}; bin: {0:b}", 42);
    spdlog::info("Support for floats {:03.2f}", 1.23456);
    spdlog::info("Positional args are {1} {0}..", "too", "supported");
    spdlog::info("{:<30}", "left aligned");

    spdlog::set_level(spdlog::level::debug); // Set global log level to debug
    spdlog::debug("This message should be displayed..");

    // change log pattern
    spdlog::set_pattern("[%H:%M:%S %z] [%n] [%^---%L---%$] [thread %t] %v");

    // Compile time log levels
    // define SPDLOG_ACTIVE_LEVEL to desired level
    SPDLOG_TRACE("Some trace message with param {}", 42);
    SPDLOG_DEBUG("Some debug message");

    std::system("pause");
    return 0;
}
