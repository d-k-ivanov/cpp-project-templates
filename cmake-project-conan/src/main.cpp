/*
 * =====================================================================
 *      Project :  project-name
 *      File    :  main.cpp
 *      Created :  01.01.2001 12:12:00 +0300
 *      Author  :  Dmitry Ivanov
 *      Company :  Company Name
 * =====================================================================
 */

#include "main.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <fmt/format.h>

#include <memory>
#include <iostream>
#include <string>

#ifdef _WIN32
#include <windows.h>
#endif

#include <filesystem>
namespace fs = std::filesystem;

int main(int argc, char* argv[], char* env[])
 {
    // To turn off messages about unused variables.
    ((void)argc );
    // ((void)argv );
    ((void)env );

    #ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    #endif

    fs::path app_path = argv[0];

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

    // Set the default logger to file logger
    std::string log_path = app_path.remove_filename().string() + app_path.filename().replace_extension("log").string();
    auto logger = spdlog::basic_logger_mt("basic_logger", log_path);

    spdlog::set_default_logger(logger);

    std::cout << "\n------------------------------\n" << std::endl;

    int a = 100;
    int b = 20;

    logger->debug("times called with ({}, {})", a, b);
    int result = a * b;
    logger->debug("Result is {}", result);
    std::cout << result << std::endl;

    std::cout << "\n------------------------------\n" << std::endl;

    std::string message = fmt::format("The answer is {}", 42);
    std::cout<<message<<"\n";

    return 0;
}
