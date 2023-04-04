-- Conan functions
function include_conan(filename)
    include(filename)
    local buildinfo = { }
    local prefix = 'conan_'
    for k, v in pairs(_G) do
        if k:sub(1, #prefix) == prefix then
            buildinfo[k:sub(#prefix + 1)] = v
        end
    end
    return buildinfo
end

function conan_setup(include_conan)
    includedirs { include_conan.includedirs }
    libdirs     { include_conan.libdirs }
    links       { include_conan.libs }
    links       { include_conan.system_libs }
    links       { include_conan.frameworks }
    defines     { include_conan.defines }
    bindirs     { include_conan.bindirs }
end
