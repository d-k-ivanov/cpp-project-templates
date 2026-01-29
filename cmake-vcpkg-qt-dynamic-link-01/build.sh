#!/usr/bin/env bash

rm -rf build
cmake -B build -G "Ninja" -S .
cmake --build build --config Release
