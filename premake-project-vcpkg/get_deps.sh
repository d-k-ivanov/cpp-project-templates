#!/usr/bin/env bash
git clone https://github.com/microsoft/vcpkg ./Tools/vcpkg
./Tools/vcpkg/bootstrap-vcpkg.sh -disableMetrics
./Tools/vcpkg/vcpkg install glm spdlog yaml-cpp entt glfw3 libzip shaderc spirv-cross --triplet=x64-linux
premake5 gmake2 -f premake5.lua
