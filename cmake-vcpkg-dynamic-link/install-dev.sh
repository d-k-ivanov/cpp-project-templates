#!/usr/bin/env bash

app_tmp_dir="/tmp/app-install"
rm -rf ${app_tmp_dir}
cmake --install build --prefix ${app_tmp_dir} --component app
