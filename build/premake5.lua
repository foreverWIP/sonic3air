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

local get_msbuild_dependency_build_commands = function()
    return {
        "set _CL_=/MT",
        "{CHDIR} ../dependencies",
        -- sdl
        "{CHDIR} sdl2/VisualC",
        "\"" .. get_msbuild_path() .. "\" SDL.sln /target:SDL2 /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        "\"" .. get_msbuild_path() .. "\" SDL.sln /target:SDL2main /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        "{CHDIR} ../../",
        -- ogg-vorbis
        "{CHDIR} libogg/win32/VS2015",
        "\"" .. get_msbuild_path() .. "\" libogg.sln /target:libogg /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        "{CHDIR} ../../../libvorbis/win32/VS2010",
        "\"" .. get_msbuild_path() .. "\" vorbis_static.sln /target:libvorbis_static /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        "\"" .. get_msbuild_path() .. "\" vorbis_static.sln /target:libvorbisfile /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        "\"" .. get_msbuild_path() .. "\" vorbis_static.sln /target:vorbisdec /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        "{CHDIR} ../../../",
        -- curl
        "{CHDIR} curl/projects/Windows/VC14.10",
        "\"" .. get_msbuild_path() .. "\" curl-all.sln /target:libcurl /p:PlatformToolset=v142 /property:Configuration=\"LIB Release - DLL Windows SSPI\" /property:Platform=%{cfg.platform} /p:RuntimeLibrary=MT_StaticRelease -verbosity:minimal",
        -- "{CHDIR} ../../../../", why doesn't this work?!
        -- zlib
        -- "set _CL_=",
        -- "{CHDIR} ../../../../zlib/contrib/vstudio/vc14",
        -- "\"" .. get_msbuild_path() .. "\" zlibvc.sln /target:zlibvc /p:PlatformToolset=v142 /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        -- "\"" .. get_msbuild_path() .. "\" zlibvc.sln /target:minizip /p:PlatformToolset=v142 /p:ConfigurationType=StaticLibrary /property:Configuration=%{cfg.buildcfg} /property:Platform=%{cfg.platform} -verbosity:minimal",
        -- "{CHDIR} ../../../../",
    }
end

local get_msbuild_dependency_clean_commands = function()
    return {
        "{RMDIR} ../dependencies/curl/build",
        "{RMDIR} ../dependencies/libogg/win32/VS2015/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/libvorbis/win32/VS2010/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/libvorbis/win32/VS2010/libvorbis/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/libvorbis/win32/VS2010/libvorbisfile/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/libvorbis/win32/VS2010/vorbisdec/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/libvorbis/win32/VS2010/vorbisenc/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/sdl2/VisualC/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/sdl2/VisualC/SDL/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/sdl2/VisualC/SDLmain/%{cfg.platform}/%{cfg.buildcfg}",
        "{RMDIR} ../dependencies/sdl2/VisualC/SDLtest/%{cfg.platform}/%{cfg.buildcfg}",
        -- zlib?
        "{RMDIR} ../dependencies/zlib/contrib/vstudio/vc14/%{cfg.architecture}",
    }
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
    staticruntime "On"

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
            "rmxext_oggvorbis"
        }
        ignoredefaultlibraries { "LIBCMT" }
        links({
            "opengl32.lib",
            "setupapi.lib",
            "winmm.lib",
            "imm32.lib",
            "version.lib",
            "ws2_32.lib",
            "wldap32.lib",
            "crypt32.lib",
            "../dependencies/curl/build/%{cfg.platform}/VC14.10/LIB Release - DLL Windows SSPI/libcurl.lib",
            "../dependencies/sdl2/VisualC/%{cfg.platform}/%{cfg.buildcfg}/SDL2.lib",
            "../dependencies/sdl2/VisualC/%{cfg.platform}/%{cfg.buildcfg}/SDL2main.lib",
            "../dependencies/libogg/win32/VS2015/%{cfg.platform}/%{cfg.buildcfg}/libogg.lib",
            "../dependencies/libvorbis/win32/VS2010/%{cfg.platform}/%{cfg.buildcfg}/libvorbis_static.lib",
            "../dependencies/libvorbis/win32/VS2010/%{cfg.platform}/%{cfg.buildcfg}/libvorbisfile_static.lib",
            "../dependencies/minizip/%{cfg.platform}/%{cfg.buildcfg}/minizip.lib",
            "../dependencies/zlib/contrib/vstudio/vc14/%{cfg.platform}/%{cfg.buildcfg}/zlib.lib",
            "../dependencies/discord_game_sdk/%{cfg.platform}/%{cfg.buildcfg}/discord_game_sdk.lib",
            "../dependencies/discord_game_sdk/lib/%{cfg.architecture}/discord_game_sdk.dll.lib",
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
        postbuildcommands {
            "{COPY} ../dependencies/discord_game_sdk/lib/%{cfg.architecture}/discord_game_sdk.dll %{cfg.targetdir}"
        }
    
    project "oxygen"
        dependson {
            "lemonscript",
            "rmxmedia",
            "oxygen_netcore"
        }
        kind "StaticLib"
        cppdialect "C++17"
        filter "system:windows"
            characterset "MBCS"
        filter {}
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

    project "dependencies"
        kind "Makefile"
        dependson {
            "zlib",
            "minizip",
            "discord_game_sdk"
        }
        filter "system:windows"
            buildcommands(get_msbuild_dependency_build_commands())
            rebuildcommands(joined_command_lists(get_msbuild_dependency_clean_commands(), get_msbuild_dependency_build_commands()))
            cleancommands(get_msbuild_dependency_clean_commands())
        filter {}
    
    project "discord_game_sdk"
        kind "StaticLib"
        cppdialect "C++17"
        targetdir "../dependencies/discord_game_sdk/%{cfg.platform}/%{cfg.buildcfg}"
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
    
    project "zlib"
        kind "StaticLib"
        cdialect "C99"
        targetdir "../dependencies/zlib/contrib/vstudio/vc14/%{cfg.platform}/%{cfg.buildcfg}"
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
        targetdir "../dependencies/minizip/%{cfg.platform}/%{cfg.buildcfg}"
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
            "dependencies"
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
            "rmxmedia"
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