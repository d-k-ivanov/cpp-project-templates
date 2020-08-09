file(GLOB_RECURSE SRC
    "main.h"
    "main.cpp"
)
source_group("Main" FILES ${SRC})

file(GLOB_RECURSE SRC_LIBS
)
source_group("Libs" FILES ${SRC_LIBS})

add_executable(project-name ${SRC} ${SRC_LIBS})

if(NOT TARGET project-name)
    add_custom_target(project-name)
    add_dependencies(project-name project-name)
endif()
