@echo off
pushd %~dp0\..

git clone https://github.com/microsoft/vcpkg ./Tools/vcpkg
call .\Tools\vcpkg\bootstrap-vcpkg.bat -disableMetrics 
.\Tools\vcpkg\vcpkg install glfw3 --triplet=x64-windows-static
premake5 vs2019 -f premake5.lua

popd
pause