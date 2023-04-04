-- Clean Action Implementation
newaction {
    trigger = "clean",
    description = "Remove all binaries and intermediate binaries, and vs files.",
    execute = function()
        print("Removing binaries")
        os.rmdir("./build")
        print("Removing Visual Studio folder")
        os.rmdir("./.vs")

        print("Removing Conan files")
        os.rmdir("./Vendor/conan_debug")
        os.rmdir("./Vendor/conan_release")
        os.rmdir("./Vendor/conan_relwithdebinfo")

        print("Removing project files")
        os.remove("**.sln")
        os.remove("**.vcxproj")
        os.remove("**.vcxproj.filters")
        os.remove("**.vcxproj.user")
        print("Done")
    end
}
