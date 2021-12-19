@echo off
git clone https://github.com/microsoft/vcpkg.git
call .\vcpkg\bootstrap-vcpkg.bat -disableMetrics
.\vcpkg\vcpkg install glfw3 --triplet=x64-windows-static
