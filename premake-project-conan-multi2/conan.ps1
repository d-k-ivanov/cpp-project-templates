if (-Not (Get-Command conan -ErrorAction SilentlyContinue | Test-Path))
{
    Write-Host "Conan not found. Please install it first. Exiting..." -ForegroundColor Red
    exit 1
}

conan install "${PSScriptRoot}" `
    -pr "${PSScriptRoot}\Vendor\conan\windows-msvc-17-shared-debug-x64.ini" `
    --build=missing -if "${PSScriptRoot}\Vendor\conan_debug"

conan install "${PSScriptRoot}" `
    -pr "${PSScriptRoot}\Vendor\conan\windows-msvc-17-shared-release-x64.ini" `
    --build=missing -if "${PSScriptRoot}\Vendor\conan_release"

conan install "${PSScriptRoot}" `
    -pr "${PSScriptRoot}\Vendor\conan\windows-msvc-17-shared-relwithdebinfo-x64.ini" `
    --build=missing -if "${PSScriptRoot}\Vendor\conan_relwithdebinfo"
