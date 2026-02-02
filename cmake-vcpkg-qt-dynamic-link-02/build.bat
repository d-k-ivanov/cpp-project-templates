@echo off
rd /s /q build
cmake -A x64 -B build -S .
cmake --build build --config Release
