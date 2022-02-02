project "ProjectOne"
    kind "ConsoleApp"
    language "C"
    cdialect  "C17"

    files
    {
        "**.c",
        "**.cc",
        "**.cpp",
        "**.cxx",
        "**.h",
        "**.hpp",
        "**.hxx",
        "**.lua",
        "**.md",
    }

    vpaths
    {
        ["Archive/*"]   = {"**.md"},
        ["Build/*"]     = {"**.lua"},
        ["Headers/*"]   = { "**.h", "**.hpp" },
        ["Sources/*"]   = {"**.c", "**.cpp"},
    }

    filter ({})
