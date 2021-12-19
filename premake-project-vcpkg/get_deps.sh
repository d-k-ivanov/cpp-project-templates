#!/usr/bin/env bash
git clone https://github.com/microsoft/vcpkg.git
./vcpkg/bootstrap-vcpkg.sh -disableMetrics
./vcpkg/vcpkg install glm spdlog yaml-cpp entt glfw3 libzip shaderc spirv-cross --triplet=x64-linux
