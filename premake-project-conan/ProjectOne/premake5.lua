project "ProjectOne"
    kind "ConsoleApp"
    language "C++"
    cppdialect "C++20"

    files
    {
        "**.h",
        "**.cpp",
    }

    vpaths {
        ["Headers/*"] = { "**.h", "**.hpp" },
        ["Sources/*"] = {"**.c", "**.cpp"}
    }

    filter ({})
