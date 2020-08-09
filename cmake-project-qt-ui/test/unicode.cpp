#include <iostream>
#include <string>

#ifdef _WIN32
#include <windows.h>
#endif

int main()
{
    #ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    #endif
    std::string str = "Pa’s väi wöl Θέλει נחמדה いろはにほ 다람쥐 ā łódź Съешь Češće žušč เป็นมนุ بىشەم  中国智造 視野無限廣";
    std::cout << str << '\n';
    std::system("pause");
    return 0;
}
