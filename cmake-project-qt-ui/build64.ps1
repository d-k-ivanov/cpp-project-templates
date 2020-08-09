$old_dir = Get-Location
New-Item build -ItemType Directory -ErrorAction SilentlyContinue
Set-Location build

$command = {
    function Set-VC-Vars-All {
        [CmdletBinding()]

        param (
            [ValidateNotNullOrEmpty()]
            [string]$Arch   = "x64",
            [string]$SDK,
            [string]$Platform,
            [string]$VC,
            [switch]$Spectre
        )

        $VC_Distros = @(
            'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community'
            'C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools'
            'C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional'
            'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise'
            'C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview'
            'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community'
            'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools'
            'C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional'
            'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'
        )

        $cmd_string = "cmd /c "

        foreach($distro in $VC_Distros) {
            $vars_file = $distro + "\VC\Auxiliary\Build\vcvarsall.bat"
            if (Test-Path "$vars_file") {
                $cmd_string += "`'`"" + $vars_file + "`" " + $Arch
                break
            }
        }

        If ($Arch -eq "x64" -Or $Arch -eq "x64_x86"){
            Set-Item -Path Env:PreferredToolArchitecture -Value "x64"
        }

        if ($Platform) {
            $cmd_string += " " + $Platform
        }

        if ($SDK) {
            $cmd_string += " " + $SDK
        }

        if ($VC) {
            $cmd_string += " -vcvars_ver=" + $VC
        }

        if ($Spectre) {
            $cmd_string += " -vcvars_spectre_libs=spectre"
        }

        $cmd_string += "` & set'"

        Write-Host "$cmd_string"

        Invoke-Expression $cmd_string |
        ForEach-Object {
            if ($_ -match "=") {
                $v = $_.split("="); set-item -force -path "ENV:\$($v[0])" -value "$($v[1])"
            }
        }
    }

    function Set-QT {
        if ($env:QTDIR) {
            Remove-Item Env:QTDIR
        }
        if ($env:QMAKESPEC) {
            Remove-Item Env:QMAKESPEC
        }
        if ($env:QMAKE_TARGET.arch) {
            Remove-Item Env:QMAKE_TARGET.arch
        }

        Set-Item -Path Env:QTDIR -Value "C:\Qt\Qt5.12.1\5.12.1\msvc2017_64"
        Set-Item -Path Env:QMAKESPEC -Value "C:\Qt\Qt5.12.1\5.12.1\msvc2017_64\mkspecs\win32-msvc"
        Set-Item -Path Env:QMAKE_TARGET.arch -Value "x64"
    }

    function build {
        Set-QT
        Set-Item -Path Env:PATH -Value "${Env:QTDIR}\bin;${Env:PATH}"
        Set-VC-Vars-All x64

        if (
            (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools")      -Or
            (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community")       -Or
            (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise")      -Or
            (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview")         -Or
            (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional")) {
                Write-Output "Unsing VS2019 Generator"
                cmake -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE="Release" ..
        } elseif (
            (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools')      -Or
            (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community')       -Or
            (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise')      -Or
            (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Preview')         -Or
            (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional')
            ){
                Write-Output "Unsing VS2017 Generator"
                cmake -G "Visual Studio 15 2017" -A x64 -DCMAKE_BUILD_TYPE="Release" ..
        } else {
            Write-Output "Unsing CMake Default Generator"
            $DefaultGenerator = $true
            cmake ..
        }

        if ($DefaultGenerator) {
            cmake --build .
        } else {
            cmake --build . --config "Release"
        }
    }

    build
}

PowerShell.exe -NoLogo -NoProfile -NonInteractive ${command}

Set-Location ${old_dir}
Remove-Item -Recurse -Force ./build
