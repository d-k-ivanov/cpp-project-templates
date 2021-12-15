file(GLOB_RECURSE SRC
    "main.h"
    "main.cpp"
)
source_group("Main" FILES ${SRC})

# file(GLOB_RECURSE SRC_LIBS
#     "../lib/types.h"
# )
# source_group("Libraries" FILES ${SRC_LIBS})

# file(GLOB_RECURSE SRC_TASKS
#     "tasks/1.cpp"
# )
# source_group("Tasks" FILES ${SRC_TASKS})

add_executable(project-name ${SRC} ${SRC_LIBS} ${SRC_TASKS})

if(NOT TARGET project-name)
    add_custom_target(project-name)
    add_dependencies(project-name project-name)
endif()
