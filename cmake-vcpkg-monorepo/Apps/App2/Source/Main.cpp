#include <Lib2/HelloWorld2.h>

#include <GLFW/glfw3.h>

#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#include <glm/mat4x4.hpp>
#include <glm/vec4.hpp>

#include <GL/glut.h>
#include <iostream>

namespace
{
void renderText()
{
    auto textGenerator = samples::HelloWorld2();
    glClear(GL_COLOR_BUFFER_BIT);

    glColor3f(1.0f, 1.0f, 1.0f);
    glRasterPos2f(-0.1f, 0.0f);

    const char* text = textGenerator.getHelloWorld2();
    for(const char* c = text; *c != '\0'; c++)
    {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, *c);
    }
}
}

int main()
{
    glm::mat4 matrix;
    glm::vec4 vec;
    auto      test = matrix * vec;

    int    argc = 0;
    char** argv = nullptr;
    glutInit(&argc, argv);

    glfwInit();

    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);

    GLFWwindow* window = glfwCreateWindow(800, 600, "App Window", nullptr, nullptr);
    glfwMakeContextCurrent(window);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    while(!glfwWindowShouldClose(window))
    {
        renderText();
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
