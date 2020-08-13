file(GLOB_RECURSE SRC
    "main.h"
    "main.cpp"
)
source_group("Main" FILES ${SRC})

file(GLOB_RECURSE SRC_LIBS
)
source_group("Libs" FILES ${SRC_LIBS})

add_executable(project-name ${SRC} ${SRC_LIBS})
target_include_directories(project-name PRIVATE ${CONAN_INCLUDE_DIRS})
target_link_libraries(project-name ${CONAN_LIBS})
