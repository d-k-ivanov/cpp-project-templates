conan install "${PSScriptRoot}" -pr "${Env:USERPROFILE}\.conan\profiles\windows-msvc-17-static-debug-x64"          --build=missing -if ./conan_debug
conan install "${PSScriptRoot}" -pr "${Env:USERPROFILE}\.conan\profiles\windows-msvc-17-static-release-x64"        --build=missing -if ./conan_release
conan install "${PSScriptRoot}" -pr "${Env:USERPROFILE}\.conan\profiles\windows-msvc-17-static-relwithdebinfo-x64" --build=missing -if ./conan_relwithdebinfo
