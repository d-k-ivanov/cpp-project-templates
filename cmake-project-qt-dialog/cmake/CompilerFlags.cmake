#-----------------------------------------------------------------------------
# C++ language version and compilation flags
#-----------------------------------------------------------------------------
if (CMAKE_VERSION VERSION_LESS "3.1")
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
    endif ()
else ()
    set(CMAKE_CXX_STANDARD 17)
endif ()

set(CMAKE_CXX_STANDARD_REQUIRED on)
set(CMAKE_CXX_EXTENSIONS off)

message("+++> Require C++${CMAKE_CXX_STANDARD}")

if(MSVC)
    set(MSVC_INCREMENTAL_DEFAULT on)
    add_definitions(
        /D_UNICODE
        /DWIN32_LEAN_AND_MEAN
        /D_CRT_NONSTDC_NO_DEPRECATE
        /D_CRT_SECURE_NO_WARNINGS
        /D_SCL_SECURE_NO_WARNINGS
        /D_NOMINMAX
        /D_ENABLE_EXTENDED_ALIGNED_STORAGE #https://developercommunity.visualstudio.com/comments/279328/view.html
    )
    add_compile_options(
        /MP # Enable multi-processor compilation
        /W4
        /bigobj
        /FC # Need absolute path for __FILE__ used in tests
    )
    if(NOT WINDOWS_STORE)
        # Statically link the run-time library
        # https://docs.microsoft.com/bg-bg/cpp/build/reference/md-mt-ld-use-run-time-library
        # https://cmake.org/Wiki/CMake_FAQ#How_can_I_build_my_MSVC_application_with_a_static_runtime.3F
        foreach(flag_var
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            if(${flag_var} MATCHES "/MD")
                string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
            endif()
        endforeach()
    endif()

    # https://cmake.org/pipermail/cmake/2018-December/068716.html
    string(REGEX REPLACE "/W3" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
    string(REGEX REPLACE "-W3" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
endif()

if(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang" OR ${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    add_compile_options(
        -Wall
        -Wconversion
        -Wextra
        -Wfloat-equal
        -Wsign-promo
        -Wstrict-aliasing
        -Wunused-parameter
        -Wno-missing-field-initializers
        -Wempty-body
        -Wparentheses
        -Wunknown-pragmas
        -Wunreachable-code
        -DREALM_HAVE_CONFIG
        -fstrict-aliasing
        -pedantic
    )
endif()

if(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
    add_compile_options(
        -Wassign-enum
        -Wbool-conversion
        -Wconditional-uninitialized
        -Wconstant-conversion
        -Wenum-conversion
        -Wint-conversion
        -Wmissing-prototypes
        -Wnewline-eof
        -Wshorten-64-to-32
        -Wimplicit-fallthrough
    )
endif()

if(${CMAKE_GENERATOR} STREQUAL "Ninja")
    if(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcolor-diagnostics")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcolor-diagnostics")
    elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fdiagnostics-color=always")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdiagnostics-color=always")
    endif()
endif()
