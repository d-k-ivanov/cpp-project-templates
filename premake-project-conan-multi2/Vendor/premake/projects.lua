-- Project functions
function ConsoleProject(projectName, source_dir)
    if source_dir == nil then
        source_dir = projectName
    end

    project(projectName)
        kind "ConsoleApp"
        language "C++"
        cppdialect "C++20"

        location("%{wks.location}/" .. source_dir)

        files {
            -- Headers
            "%{prj.location}/**.h",
            "%{prj.location}/**.hh",
            "%{prj.location}/**.hpp",
            "%{prj.location}/**.hxx",

            -- Sources
            "%{prj.location}/**.c",
            "%{prj.location}/**.cc",
            "%{prj.location}/**.cpp",
            "%{prj.location}/**.cxx",

            -- Misc
            "%{prj.location}/**.lua",
            "%{prj.location}/**.md",
        }

        vpaths {
            ["Docs/*"]   = {"**.md"},
            ["Build/*"]     = {"**.lua"},
            ["Headers/*"]   = { "**.h", "**.hpp" },
            ["Sources/*"]   = {"**.c", "**.cpp"},
        }

        flags {"MultiProcessorCompile"}

        filter "platforms:x64"
            architecture "x86_64"

        filter({"platforms:x86_64","system:windows"})
            defines({"COMPILER_MSVC64","WIN64"})

        filter "configurations:RelWithDebInfo"
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

        filter "files:**.c or **.cc or **.cpp or **.cxx"
            strictaliasing "Level3"

    filter({})
end

function MiscProject(projectName, source_dir)
    if source_dir == nil then
        source_dir = "%{wks.location}"
    end

    project(projectName)
        kind "None"

        files {
            "%{wks.location}/.gitignore",
            "%{wks.location}/.editorconfig",
            "%{wks.location}/conan.ps1",
            "%{wks.location}/conanfile.txt",
            "%{wks.location}/Vendor/**/*.lua",
            "%{wks.location}/Vendor/**/*.ini",
            "%{wks.location}/gen.bat",
            "%{wks.location}/premake5.lua"
        }

        filter ({})
end

function SetWarningLevelHigh()
    warnings "Extra"
    flags {"FatalWarnings", "ShadowedVariables", "UndefinedIdentifiers"}
end

function SharedLib()
    kind "SharedLib"
end
