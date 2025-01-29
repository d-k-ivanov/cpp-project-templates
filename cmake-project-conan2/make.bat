conan install . -pr:a=conan\windows-msvc-17-shared-debug-x64.ini          --output-folder=build --build=missing
conan install . -pr:a=conan\windows-msvc-17-shared-release-x64.ini        --output-folder=build --build=missing
conan install . -pr:a=conan\windows-msvc-17-shared-relwithdebinfo-x64.ini --output-folder=build --build=missing

cmake -G "Visual Studio 17 2022" -A x64 -B build -S . -DCMAKE_TOOLCHAIN_FILE=build\conan_toolchain.cmake
