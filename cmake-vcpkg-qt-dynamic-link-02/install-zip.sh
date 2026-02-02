#!/usr/bin/env bash

rm -rf app.zip _CPack_Packages
cpack -C Release --config build/CPackConfig_app.cmake -G ZIP -V
