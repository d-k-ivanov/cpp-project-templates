conan install . --output-folder=build --build=missing --settings=build_type=Debug
conan install . --output-folder=build --build=missing --settings=build_type=Release
conan install . --output-folder=build --build=missing --settings=build_type=RelWithDebInfo

cmake -G "Visual Studio 17 2022" -A x64 -B build -S . -DCMAKE_TOOLCHAIN_FILE=build\conan_toolchain.cmake
