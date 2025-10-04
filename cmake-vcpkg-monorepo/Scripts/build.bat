!@echo off

cmake -A x64 -B %~dp0/../build -S .
cmake --build %~dp0/../build --config Release
