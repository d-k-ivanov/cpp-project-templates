if(MAKE_TESTS)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/tests)

    file(GLOB_RECURSE SRC
    "main.h"
    "main.cpp"
    )
    source_group("Main" FILES ${SRC})

    file(GLOB_RECURSE SRC_LIBS
    )
    source_group("Libs" FILES ${SRC_LIBS})

    file(GLOB_RECURSE SRC_TESTS
    )
    source_group("Tests" FILES ${SRC_TESTS})

    add_executable(tests ${SRC} ${SRC_LIBS} ${SRC_TESTS})
endif()

