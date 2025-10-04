#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmake -B ${SCRIPT_DIR}/../build -G "Ninja Multi-Config" -S ${SCRIPT_DIR}/.. -DCMAKE_BUILD_TYPE=Release
cmake --build ${SCRIPT_DIR}/../build --config Release
