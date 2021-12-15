/*
 * =====================================================================
 *      Project :  project-name
 *      File    :  main.cpp
 *      Created :  15.12.2021
 *      Author  :  Dmitry Ivanov
 * =====================================================================
 */

#include "main.h"

#include <functional>
#include <iostream>

#ifdef _WIN32
#include <Windows.h>
#endif

int main(int argc, char* argv[], char* env[])
 {
    // To turn off messages about unused variables.
    ((void)argc );
    ((void)argv );
    ((void)env );

    #ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    #endif

    std::cout << "Hello World!" << std::endl;

    // std::system("pause");
    return 0;
 }
