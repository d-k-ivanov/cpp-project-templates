#include "Main.h"

#include <Format.h>
#include <Logger.h>

#include <functional>
#include <iostream>

#ifdef _WIN32
#include <windows.h>
#endif

#include <cxxopts.h>


std::map<std::string, std::function<void()>> init(int argc, char* argv[])
{
    std::map<std::string, std::function<void()>> problems =
    {
        { printf("aaa"); }}
        // { "problem1", problem1},
        // { "problem2", problem2},
        // { "problem3", problem3}
    };

    cxxopts::Options options("project-one", "Description");
    options
        .positional_help("[optional args]")
        .show_positional_help();

    options.add_options()
        ("h,help", "Show help")
        ("d,debug", "Show debug output")
        ("v,verbose", "Show verbose output")
        ("s,separate", "Show separated numbers in output")
        ("p,problem", "Problem number", cxxopts::value<int>(), "N");

    options.custom_help("[-h] [-v] [-s]");

    try {
        options.parse_positional({ "help", "verbose", "debug", "separate" });
        const auto result = options.parse(argc, argv);

        if (result.count("help")) {
            std::cout << options.help() << '\n';
            std::system("pause");
            exit(1);
        }

        if (result.count("verbose")) {
            utils::logger::log_level = utils::logger::VERBOSE;
        }
        else if (result.count("debug"))
        {
            utils::logger::log_level = utils::logger::DEBUG;
        }

        if (result.count("separate")) {
            LOG_V(utils::logger::log_level) << "Thousands separator is enabled..." << std::endl;
            set_separator_thousands('\'');
        }

        if (result.count("problem"))
        {
            const auto problem_number = result["problem"].as<int>();
            if (problem_number > 3)
            {
                std::cout << "There are only three problems. Exiting...\n";
                exit(2);
            }
            LOG_V(utils::logger::log_level) << std::string(100, '-') << '\n';
            problems["problem" + std::to_string(problem_number)]();
            LOG_V(utils::logger::log_level) << std::string(100, '-') << '\n';

            exit(0);
        }
    }
    catch (const cxxopts::OptionException & e) {
        std::cout << "Error: " << e.what() << " Showing help message...\n";
        std::cout << options.help() << '\n';
        exit(99);
    }

    return problems;
}


int main(int argc, char* argv[], char* env[])
 {
    // To turn off messages about unused variables.
    ((void)env );

    #ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    #endif

    std::map<std::string, std::function<void()>> problems = init(argc, argv);

    for (std::pair<std::string, std::function<void()>> func: problems)
    {
        LOG_V(utils::logger::log_level) << std::string(100, '-') << '\n';
        func.second();
    }
    LOG_V(utils::logger::log_level) << std::string(100, '-') << '\n';

    // std::system("pause");
    return 0;
 }
