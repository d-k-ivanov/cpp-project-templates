#include "Main.h"
#include <iostream>

#ifdef _WIN32
#include <Windows.h>
#endif

#include <fmt/core.h>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>


int main()
{
    std::string s = fmt::format("The answer is {}.", 42);
    std::cout << s << std::endl;

    // Log to console
    spdlog::set_level(spdlog::level::info);
    spdlog::info("Welcome to spdlog!");
    spdlog::error("Some error message with arg: {}", 1);
    spdlog::warn("Easy padding in numbers like {:08d}", 12);
    spdlog::critical("Support for int: {0:d};  hex: {0:x};  oct: {0:o}; bin: {0:b}", 42);
    spdlog::info("Support for floats {:03.2f}", 1.23456);
    spdlog::info("Positional args are {1} {0}..", "too", "supported");
    spdlog::info("{:<30}", "left aligned");
    spdlog::set_level(spdlog::level::debug); // Set global log level to debug
    spdlog::debug("This message should be displayed..");

    // Log to file
    std::shared_ptr<spdlog::logger> logger;
    logger = spdlog::basic_logger_mt("logger", "cpp-series-one-tests.log");
    logger->set_level(spdlog::level::info);
    logger->info("Welcome to spdlog!");

    logger->error("Some error message with arg: {}", 1);

    logger->warn("Easy padding in numbers like {:08d}", 12);
    logger->critical("Support for int: {0:d};  hex: {0:x};  oct: {0:o}; bin: {0:b}", 42);
    logger->info("Support for floats {:03.2f}", 1.23456);
    logger->info("Positional args are {1} {0}..", "too", "supported");
    logger->info("{:<30}", "left aligned");

    logger->set_level(spdlog::level::debug); // Set global log level to debug
    logger->debug("This message should be displayed..");

    spdlog::drop_all();
    return 0;
}
