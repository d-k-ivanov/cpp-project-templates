#pragma once

#include <ostream>

namespace utils::logger
{
    enum LogLevel
    {
        NORMAL  = 0,
        VERBOSE = 1,
        DEBUG   = 2

    };

    class NoStreamBuf final : public std::streambuf {};

    inline LogLevel log_level = utils::logger::NORMAL;
    inline NoStreamBuf no_stream_buf;
    inline std::ostream no_out(&no_stream_buf);

    #define LOG_V(x) (((x) >= utils::logger::VERBOSE) ? std::cout                 : euler::logger::no_out)
    #define LOG_D(x) (((x) >= utils::logger::DEBUG)   ? std::cout << "\tDEBUG: "  : euler::logger::no_out)
}
