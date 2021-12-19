#include <iostream>
#include <GLFW/glfw3.h>

int main()
{
    glfwInit();

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    const auto window = glfwCreateWindow(800, 600, "Hello World!", nullptr, nullptr);
    glfwMakeContextCurrent(window);

    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents();
        glfwSwapBuffers(window);
    }

    auto monitor_counter = 0;
    const auto monitors = glfwGetMonitors(&monitor_counter);

    for (auto i = 0; i < monitor_counter; ++i)
    {
        const auto name = glfwGetMonitorName(monitors[i]);
        int x, y;
        glfwGetMonitorPhysicalSize(monitors[i], &x, &y);
        std::cout << name << '\n';
        std::cout << x << 'x' << y << '\n';
        std::cout << '\n';
    }

    glfwDestroyWindow(window);
    glfwTerminate();
}
