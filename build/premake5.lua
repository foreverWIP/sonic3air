local dependencies_out_dir = "%{wks.location}/../dependencies/out/%{cfg.platform}/%{cfg.buildcfg}/"
local ensure_out_dir_exists = "{MKDIR} " .. dependencies_out_dir

local joined_command_lists = function(list_1, list_2)
    local ret_table = {}
    for k,v in ipairs(list_1) do
        table.insert(ret_table, v)
    end
    for k,v in ipairs(list_2) do
        table.insert(ret_table, v)
    end
    return ret_table
end

local get_msbuild_path = function()
    if _TARGET_OS == "windows" then
        local msbuild_path = "C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/MSBuild.exe"
        local msbuild_handle = io.open(msbuild_path, "r")
        if msbuild_handle == nil then
            msbuild_path = "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/MSBuild/Current/Bin/MSBuild.exe"
            msbuild_handle = io.open(msbuild_path, "r")
            if msbuild_handle == nil then
                error("Can't find MSBuild! Make sure you have either Visual Studio 2019 or 2022 installed.")
            else
                msbuild_handle:close()
                return msbuild_path
            end
        else
            msbuild_handle:close()
            return msbuild_path
        end
    else
        error("amy this shouldn't happen")
    end
end

local common_dependency_includes = function()
    includedirs {
        "../dependencies/curl/include",
        "../dependencies/libogg/include",
        "../dependencies/libvorbis/include",
        "../dependencies/sdl2/include",
        "../dependencies/zlib",
        "../dependencies/zlib/contrib/minizip",
        "../dependencies"
    }
end

local common_config_options = function()
    filter "configurations:Debug"
        symbols "On"
        runtime "Debug"
        optimize "Off"
        filter "system:windows"
            defines { "DEBUG" }
        filter {}
    filter {}
    filter "configurations:not Debug"
        symbols "Off"
        runtime "Release"
        optimize "Speed"
        flags { "LinkTimeOptimization" }
    filter {}
    staticruntime "On"
end

workspace "sonic3air"
    startproject "sonic3air"

    configurations { "Debug", "Release", "Release-Enduser" }
    filter "system:windows"
        platforms { "Win32", "x64" }
    filter {}
    filter "system:not windows"
        platforms { "x86", "x64" }
    filter {}
    filter "platforms:not x64"
        architecture "x86"
    filter {}
    filter "platforms:x64"
        architecture "x64"
    filter {}

    project "sonic3air"
        dependson {
            "oxygen",
            "rmxext_oggvorbis",
            "discord_game_sdk"
        }
        filter "configurations:Debug"
        ignoredefaultlibraries { "LIBCMT" }
        filter {}
        links({
            "opengl32.lib",
            "setupapi.lib",
            "winmm.lib",
            "imm32.lib",
            "version.lib",
            "ws2_32.lib",
            "wldap32.lib",
            "crypt32.lib",
            dependencies_out_dir .. "libcurl.lib",
            dependencies_out_dir .. "SDL2.lib",
            dependencies_out_dir .. "SDL2main.lib",
            dependencies_out_dir .. "libogg.lib",
            dependencies_out_dir .. "libvorbis_static.lib",
            dependencies_out_dir .. "libvorbisfile_static.lib",
            dependencies_out_dir .. "minizip.lib",
            dependencies_out_dir .. "zlib.lib",
            dependencies_out_dir .. "discord_game_sdk.lib",
            dependencies_out_dir .. "discord_game_sdk.dll.lib",
            "../lemonscript/out/lemonscript.lib",
            "../oxygenengine/out/oxygen.lib",
            "../oxygenengine/out/oxygen_netcore.lib",
            "../librmx/out/rmxbase.lib",
            "../librmx/out/rmxmedia.lib",
            "../librmx/out/rmxext_oggvorbis.lib",
            "../lemonscript/out/lemonscript.lib",
        })
        kind "WindowedApp"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
        targetdir "../sonic3air"
        common_config_options()
        pchheader "sonic3air/pch.h"
        pchsource "../sonic3air/source/sonic3air/pch.cpp"
        filter "system:windows"
            defines {
                "MAXPATHLEN=256",
                "_CRT_SECURE_NO_WARNINGS"
            }
        filter {}
        common_dependency_includes()
        includedirs {
            "../sonic3air/source",
            "../librmx/source",
            "../lemonscript/source",
            "../oxygenengine/source"
        }
        files {
            "../sonic3air/source/**.h",
            "../sonic3air/source/**.cpp",
        }
    
    project "oxygen"
        dependson {
            "lemonscript",
            "rmxmedia",
            "oxygen_netcore",
            "curl"
        }
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
        ignoredefaultlibraries { "LIBCMT" }
        targetdir "../oxygenengine/out"
        pchheader "oxygen/pch.h"
        pchsource "../oxygenengine/source/oxygen/pch.cpp"
        filter "system:windows"
            defines {
                "MAXPATHLEN=256",
                "_CRT_SECURE_NO_WARNINGS"
            }
        filter {}
        filter "configurations:not Debug"
            intrinsics "on"
        filter {}
        common_config_options()
        common_dependency_includes()
        includedirs {
            "../librmx/source",
            "../lemonscript/source",
            "../oxygenengine/source"
        }
        files {
            "../oxygenengine/source/oxygen/**.h",
            "../oxygenengine/source/oxygen/**.cpp"
        }
    
    project "ogg-vorbis"
        local ogg_vorbis_build_commands = {
            ensure_out_dir_exists,
            "set _CL_=/MT",
            "{CHDIR} ../dependencies/libogg/win32/VS2015",
            "\"" .. get_msbuild_path() .. "\" libogg.sln /target:libogg /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
            "{COPYFILE} %{cfg.platform}/%{cfg.buildcfg}/libogg.lib " .. dependencies_out_dir,
            "{CHDIR} ../../../libvorbis/win32/VS2010",
            "\"" .. get_msbuild_path() .. "\" vorbis_static.sln /target:libvorbis_static /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
            "\"" .. get_msbuild_path() .. "\" vorbis_static.sln /target:libvorbisfile /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
            "{COPYFILE} %{cfg.platform}/%{cfg.buildcfg}/libvorbis_static.lib " .. dependencies_out_dir,
            "{COPYFILE} %{cfg.platform}/%{cfg.buildcfg}/libvorbisfile_static.lib " .. dependencies_out_dir
        }

        local ogg_vorbis_clean_commands = {
            "{DELETE} ".. dependencies_out_dir .. "libogg.lib",
            "{DELETE} ".. dependencies_out_dir .. "libvorbis_static.lib",
            "{DELETE} ".. dependencies_out_dir .. "libvorbisfile_static.lib",
        }
        kind "Makefile"
        filter "system:windows"
            buildcommands(ogg_vorbis_build_commands)
            rebuildcommands(joined_command_lists(ogg_vorbis_clean_commands, ogg_vorbis_build_commands))
            cleancommands(ogg_vorbis_clean_commands)
        filter {}
    
    project "sdl2"
        local sdl2_build_commands = {
            ensure_out_dir_exists,
            "set _CL_=/MT",
            "{CHDIR} ../dependencies/sdl2/VisualC",
            "\"" .. get_msbuild_path() .. "\" SDL.sln /target:SDL2 /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
            "\"" .. get_msbuild_path() .. "\" SDL.sln /target:SDL2main /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
            "{COPYFILE} %{cfg.platform}/%{cfg.buildcfg}/SDL2.lib " .. dependencies_out_dir,
            "{COPYFILE} %{cfg.platform}/%{cfg.buildcfg}/SDL2main.lib " .. dependencies_out_dir
        }

        local sdl2_clean_commands = {
            "{DELETE} ".. dependencies_out_dir .. "SDL2.lib",
            "{DELETE} ".. dependencies_out_dir .. "SDL2main.lib",
        }
        kind "Makefile"
        filter "system:windows"
            buildcommands(sdl2_build_commands)
            rebuildcommands(joined_command_lists(sdl2_clean_commands, sdl2_build_commands))
            cleancommands(sdl2_clean_commands)
        filter {}
    
    project "curl"
        local curl_build_commands = {
            ensure_out_dir_exists,
            "set _CL_=/MT",
            "{CHDIR} ../dependencies/curl/projects/Windows/VC14.10",
            "\"" .. get_msbuild_path() .. "\" curl-all.sln /target:libcurl /p:PlatformToolset=v142 /property:Configuration=\"LIB Release - DLL Windows SSPI\" /property:Platform=%{cfg.platform} /p:RuntimeLibrary=MT_StaticRelease -verbosity:minimal",
            "{COPYFILE} \"../../../build/%{cfg.platform}/VC14.10/LIB Release - DLL Windows SSPI/libcurl.lib\" " .. dependencies_out_dir
        }

        local curl_clean_commands = {
            "{DELETE} ".. dependencies_out_dir .. "libcurl.lib",
        }
        kind "Makefile"
        filter "system:windows"
            buildcommands(curl_build_commands)
            rebuildcommands(joined_command_lists(curl_clean_commands, curl_build_commands))
            cleancommands(curl_clean_commands)
        filter {}
    
    project "discord_game_sdk"
        kind "StaticLib"
        cppdialect "C++17"
        targetdir(dependencies_out_dir)
        common_config_options()
        common_dependency_includes()
        conformancemode "true"
        includedirs {
            "../dependencies/discord_game_sdk/cpp"
        }
        files {
            "../dependencies/discord_game_sdk/cpp/**.h",
            "../dependencies/discord_game_sdk/cpp/**.cpp"
        }
        postbuildcommands({
            "{COPY} ../dependencies/discord_game_sdk/lib/%{cfg.architecture}/discord_game_sdk.dll " .. dependencies_out_dir,
            "{COPY} ../dependencies/discord_game_sdk/lib/%{cfg.architecture}/discord_game_sdk.dll.lib " .. dependencies_out_dir
        })
        cleancommands({
            "{DELETE} " .. dependencies_out_dir .. "discord_game_sdk.dll",
            "{DELETE} " .. dependencies_out_dir .. "discord_game_sdk.dll.lib"
        })
    
    project "zlib"
        kind "StaticLib"
        cdialect "C99"
        targetdir(dependencies_out_dir)
        filter "system:windows"
            characterset "MBCS"
        filter {}
        common_config_options()
        common_dependency_includes()
        defines {
            "WINAPI_FAMILY=100",
            "_CRT_SECURE_NO_WARNINGS"
        }
        includedirs {
            "../dependencies/zlib"
        }
        files {
            "../dependencies/zlib/*.h",
            "../dependencies/zlib/*.c"
        }
    
    project "minizip"
        kind "StaticLib"
        cdialect "C99"
        targetdir(dependencies_out_dir)
        filter "system:windows"
            characterset "MBCS"
        filter {}
        common_config_options()
        common_dependency_includes()
        defines {
            "_CRT_SECURE_NO_WARNINGS"
        }
        includedirs {
            "../dependencies/zlib/contrib/minizip"
        }
        files {
            "../dependencies/zlib/contrib/minizip/*.h",
            "../dependencies/zlib/contrib/minizip/*.c"
        }
        removefiles {
            "../dependencies/zlib/contrib/minizip/minizip.c"
        }

    project "lemonscript"
        dependson {
            "rmxbase"
        }
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
        ignoredefaultlibraries { "LIBCMT" }
        targetdir "../lemonscript/out"
        pchheader "lemon/pch.h"
        pchsource "../lemonscript/source/lemon/pch.cpp"
        common_config_options()
        common_dependency_includes()
        includedirs {
            "../librmx/source",
            "../lemonscript/source"
        }
        files {
            "../lemonscript/source/lemon/**.h",
            "../lemonscript/source/lemon/**.cpp",
        }

    project "oxygen_netcore"
        kind "StaticLib"
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
        ignoredefaultlibraries { "LIBCMT" }
        targetdir "../oxygenengine/out"
        pchheader "oxygen_netcore/pch.h"
        pchsource "../oxygenengine/source/oxygen_netcore/pch.cpp"
        common_config_options()
        common_dependency_includes()
        includedirs {
            "../oxygenengine/source",
            "../librmx/source"
        }
        files {
            "../oxygenengine/source/oxygen_netcore/**.h",
            "../oxygenengine/source/oxygen_netcore/**.cpp",
        }

    project "rmxbase"
        dependson {
            "zlib",
            "minizip"
        }
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
        targetdir "../librmx/out"
        pchheader "rmxbase.h"
        pchsource "../librmx/source/rmxbase/rmxbase.cpp"
        filter "files:../librmx/source/_jsoncpp/**.cpp"
            pchheader ""
            pchsource ""
        filter {}
        common_config_options()
        common_dependency_includes()
        includedirs {
            "../librmx/source"
        }
        files {
            "../librmx/source/rmxbase.h",
            "../librmx/source/rmxbase/**.h",
            "../librmx/source/rmxbase/**.cpp",
        }
        removefiles {
            "../librmx/source/rmxbase/_jsoncpp/**.cpp",
        }
        files {
            "../librmx/source/rmxbase/_jsoncpp/json_amalgamated.cpp"
        }

    project "rmxmedia"
        dependson {
            "sdl2"
        }
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
        targetdir "../librmx/out"
        pchheader "rmxmedia.h"
        pchsource "../librmx/source/rmxmedia/rmxmedia.cpp"
        defines { "GLEW_STATIC" }
        common_config_options()
        common_dependency_includes()
        includedirs {
            "../librmx/source",
            "../librmx/source/rmxmedia/_glew"
        }
        files {
            "../librmx/source/rmxmedia.h",
            "../librmx/source/rmxmedia/**.h",
            "../librmx/source/rmxmedia/**.cpp"
        }

    project "rmxext_oggvorbis"
        dependson {
            "rmxmedia",
            "ogg-vorbis"
        }
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        targetdir "../librmx/out"
        common_config_options()
        common_dependency_includes()
        includedirs {
            "../librmx/source"   
        }
        files {
            "../librmx/source/rmxmedia.h",
            "../librmx/source/rmxext_oggvorbis.h",
            "../librmx/source/rmxext_oggvorbis/**.h",
            "../librmx/source/rmxext_oggvorbis/**.cpp"
        }