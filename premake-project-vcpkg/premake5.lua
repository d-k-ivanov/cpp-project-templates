require('vstudio')

premake.api.register {
    name = "solution_items",
    scope = "workspace",
    kind = "list:string",
}

premake.override(premake.vstudio.sln2005, "projects", function(base, wks)
    if wks.solution_items and #wks.solution_items > 0 then
        local solution_folder_GUID = "{2150E333-8FDC-42A3-9474-1A3956D46DE8}" -- See https://www.codeproject.com/Reference/720512/List-of-Visual-Studio-Project-Type-GUIDs
        premake.push("Project(\"" .. solution_folder_GUID .. "\") = \"Solution Items\", \"Solution Items\", \"{" .. os.uuid("Solution Items:" .. wks.name) .. "}\"")
        premake.push("ProjectSection(SolutionItems) = preProject")

        for _, path in ipairs(wks.solution_items) do
            premake.w(path .. " = " .. path)
        end

        premake.pop("EndProjectSection")
        premake.pop("EndProject")
    end
    base(wks)
end)


workspace "Solution"
    startproject "ProjectOne"

    configurations { "Debug", "Release", "RelDebug" }
    platforms { "x64", "x86"}
    warnings "Extra"

    flags {"MultiProcessorCompile", "ShadowedVariables", "UndefinedIdentifiers"}

    targetdir ("bin/%{prj.name}/%{cfg.buildcfg}-%{cfg.architecture}")
    debugdir ("bin/%{prj.name}/%{cfg.buildcfg}-%{cfg.architecture}")
    objdir ("bin-int/%{prj.name}/%{cfg.buildcfg}-%{cfg.architecture}")

    -- targetdir "%{prj.location}/%{cfg.architecture}/%{cfg.buildcfg}"
    -- debugdir "%{prj.location}/%{cfg.architecture}/%{cfg.buildcfg}"
    -- objdir "!%{prj.location}/%{cfg.architecture}/%{cfg.buildcfg}/intermediate/%{prj.name}"

    filter "platforms:x86"
        architecture "x86"

    filter "platforms:x64"
        architecture "x86_64"

    filter({"platforms:x86","system:windows"})
        defines({"COMPILER_MSVC32","WIN32"})

    filter({"platforms:x86_64","system:windows"})
        defines({"COMPILER_MSVC64","WIN64"})

    filter "configurations:RelDebug"
        defines "NDEBUG"
        optimize "Debug"
        runtime "Release"
        symbols "On"

    filter "configurations:Release"
        defines "NDEBUG"
        flags "LinkTimeOptimization"
        optimize "Full"
        runtime "Release"
        symbols "Off"

    filter "configurations:Debug"
        defines {"DEBUG", "_DEBUG"}
        optimize "Off"
        runtime "Debug"
        symbols "On"


    filter { "system:windows", "configurations:Debug" }
        libdirs {
            "vcpkg/installed/x64-windows/lib",
            "vcpkg/installed/x64-windows-static/lib",
        }

    filter { "system:windows", "configurations:Release" }
        libdirs {
            "vcpkg/installed/x64-windows/debug/lib",
            "vcpkg/installed/x64-windows-static/debug/lib",
        }

    filter { "system:linux", "configurations:Debug" }
        libdirs {
            "vcpkg/installed/x64-linux/lib",
            "vcpkg/installed/x64-linux-static/lib",
        }

    filter { "system:linux", "configurations:Release" }
        libdirs {
            "vcpkg/installed/x64-linux/debug/lib",
            "vcpkg/installed/x64-linux-static/debug/lib",
        }

    filter "system:windows"
        cdialect "C17"
        cppdialect "C++20"
        debuggertype "NativeOnly"
        defaultplatform "x64"
        defines {"_CRT_NONSTDC_NO_WARNINGS", "_CRT_SECURE_NO_WARNINGS", "STRICT", "COMPILER_MSVC" }
        staticruntime "On"

    filter "system:linux"
        cdialect "gnu17"
        cppdialect "gnu++20"
        staticruntime "Off"
        defaultplatform "x64"
        linkoptions "-Wl,--no-undefined"
        defines({ "LINUX", "_LINUX", "COMPILER_GCC", "POSIX" })

    filter "files:**.cpp or **.cxx or **.cc"
        strictaliasing "Level3"

    filter({})

include "ProjectOne"

project "Other"
    kind "None"

    files
    {
        ".editorconfig",
        ".gitignore",
        "commit_now.ps1",
        "gen_solution.bat",
        "premake5.lua"
    }
