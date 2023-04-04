#pragma once

#include <iostream>
#include <iomanip>
#include <sstream>

namespace utils::format
{
    inline char separator;

    inline void set_separator_thousands(const char sep)
    {
        utils::format::separator = sep;
        struct separate_thousands : std::numpunct<char> {
            char_type do_thousands_sep() const override { return separator; }
            string_type do_grouping() const override { return "\3"; }
        };
        auto thousands = std::make_unique<separate_thousands>();
        std::cout.imbue(std::locale(std::cout.getloc(), thousands.release()));

    }

    inline void reset_separator()
    {
        std::cout.imbue(std::locale("C"));
    }
}
