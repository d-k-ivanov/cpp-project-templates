-- General configuration
include "./Vendor/premake/conan.lua"
include "./Vendor/premake/projects.lua"
include "./Vendor/premake/premake_lib.lua"
include "./Vendor/premake/visual_studio.lua"

conan_debug          = include_conan "Vendor/conan_debug/conanbuildinfo.premake.lua"
conan_release        = include_conan "Vendor/conan_release/conanbuildinfo.premake.lua"
conan_relwithdebinfo = include_conan "Vendor/conan_relwithdebinfo/conanbuildinfo.premake.lua"

workspace "Solution"
    configurations { "RelWithDebInfo", "Release", "Debug" }
    platforms { "x64" }
    location "."

    targetdir "bin/%{prj.name}/%{cfg.architecture}-%{cfg.buildcfg}"
    debugdir "bin/%{prj.name}/%{cfg.architecture}-%{cfg.buildcfg}"
    objdir "bin-int/%{prj.name}/%{cfg.architecture}-%{cfg.buildcfg}"

    startproject "ProjectOne"
    include "ProjectOne"
    include "Modules/Utils"

    filter "configurations:RelWithDebInfo"
        conan_setup(conan_relwithdebinfo)

    filter "configurations:Release"
        conan_setup(conan_release)

    filter "configurations:Debug"
        conan_setup(conan_debug)

    -- Misc Stuff
    MiscProject("zOther")

