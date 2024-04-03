luatos_root = os.scriptdir().."/../LuatOS"
LUAT_BSP_VERSION = "V2000"

package("gnu_rm")
    set_kind("toolchain")
    set_homepage("https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm")
    set_description("GNU Arm Embedded Toolchain")

    if is_host("windows") then
        set_urls("http://cdndownload.openluat.com/xmake/toolchains/gcc-arm/gcc-arm-none-eabi-10-2020-q4-major-win32.zip")
        add_versions("ec7xx", "90057b8737b888c53ca5aee332f1f73c401d6d3873124d2c2906df4347ebef9e")
    elseif is_host("linux") then
        set_urls("http://cdndownload.openluat.com/xmake/toolchains/gcc-arm/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2")
        add_versions("ec7xx", "21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618")
    elseif is_host("macosx") then
        set_urls("http://cdndownload.openluat.com/xmake/toolchains/gcc-arm/gcc-arm-none-eabi-10-2020-q4-major-mac.tar.bz2")
        add_versions("ec7xx", "bed12de3565d4eb02e7b58be945376eaca79a8ae3ebb785ec7344e7e2db0bdc0")
    end
    on_install("@windows", "@linux", "@macosx", function (package)
        os.vcp("*", package:installdir())
    end)
package_end()

csdk_root = os.scriptdir()

function description_common()
    set_project("EC7XX")
    set_xmakever("2.8.9")
    add_rules("mode.debug", "mode.release")
    set_defaultmode("debug")
    
    add_requires("gnu_rm ec7xx")
    set_toolchains("gnu-rm@gnu_rm")

    set_plat("cross")
    set_arch("arm")
    set_languages("gnu11", "cxx11")
    set_warnings("all")
    set_optimize("smallest")

    set_values("project_dir", project_dir)
    set_values("project_name", project_name)
    set_values("csdk_root", csdk_root)
    set_values("luatos_root", luatos_root)

	option("chip_target", {default = "ec718p", showmenu = true, values={"ec716e","ec716s","ec718s","ec718e","ec718p","ec718pv"},description = "chip target"})
    add_options("chip_target")
    if has_config("chip_target") then chip_target = get_config("chip_target") end

	option("lspd_mode",function()
        add_deps("chip_target")
		set_default(true)
		set_showmenu(true)
        chip_target = get_config("chip_target")
        -- 先统一显示出来,后面支持动态显示在调整
        set_description("lspd mode. enable can get more memory.ec718pv always enable, no need config. ec716e/ec716s/ec718s disable can get sms,wifi,hib power mode, enable can get rndis")

		-- if chip_target ~= "ec718p" and chip_target ~= "ec718pv" and chip_target ~= "ec718e" then
		-- 	set_description("lspd mode. enable can get sms,wifi,hib power mode, disable can get rndis")
		-- elseif chip_target == "ec718pv" then
		-- 	set_description("lspd mode. always enable, no need config")
		-- else
		-- 	set_description("lspd mode. enable can get more memory.")
		-- end
	end)
    --option("lspd_mode", {default = "enable", showmenu = true, values={"enable","disable"},description = "Enable or disable low speed mode , more memory"})
    add_options("lspd_mode")

	option("denoise_force",function()
        add_deps("chip_target")
		set_default(false)
		set_showmenu(true)
        chip_target = get_config("chip_target")
        set_description("denoise mode. enable can use amr encode to support noise reduction. only ec718p need config, other always disable, no need config ")
        -- after_check(function (option)
        --     if get_config("chip_target") ~= "ec718p" then
        --         option:enable(false)
        --     end
        -- end)
    end)
	add_options("denoise_force")

    if has_config("chip_target") then
        chip_target = get_config("chip_target")
        CHIP = "ec718"
        if chip_target == "ec718p" or chip_target == "ec718pv" or chip_target == "ec718e" then
            add_defines("CHIP_EC718","TYPE_EC718P")
        elseif chip_target == "ec718s" then
            add_defines("CHIP_EC718","TYPE_EC718S")
        elseif chip_target == "ec716s" then
            CHIP = "ec716"
            add_defines("CHIP_EC716","TYPE_EC716S")
        elseif chip_target == "ec716e" then
            CHIP = "ec716"
            add_defines("CHIP_EC716","TYPE_EC716E")
        end

        if (chip_target == "ec718p" or chip_target == "ec718e") and has_config("lspd_mode")  or chip_target == "ec718pv" or chip_target == "ec716s" or chip_target == "ec716e" or chip_target == "ec718s" then
            add_defines("OPEN_CPU_MODE")
        end
        add_includedirs(csdk_root.."/PLAT/driver/hal/ec7xx/ap/inc/"..CHIP,
                    csdk_root.."/PLAT/driver/chip/ec7xx/ap/inc/"..CHIP)
    end

    if has_config("chip_target")then 
        chip_target = get_config("chip_target") 
        lib_ps_plat = "full"
        lib_fw = "oc"
        if has_config("lspd_mode") then
            if chip_target == "ec718pv" then
                lib_fw = "audio"
                lib_ps_plat = "ims"
                add_defines("FEATURE_AMR_CP_ENABLE","FEATURE_VEM_CP_ENABLE")
            elseif chip_target == "ec718p" and has_config("denoise_force") then
                lib_fw = "audio"
                add_defines("FEATURE_AMR_CP_ENABLE","FEATURE_VEM_CP_ENABLE")
                lib_ps_plat = "oc"
            elseif chip_target == "ec716e" then
                lib_ps_plat = "ram"
                lib_ps_plat = "ram"
            else 
                lib_ps_plat = "oc"
            end
        else 
            if chip_target == "ec718p" or chip_target == "ec718e" then
                lib_ps_plat = "full"
            elseif chip_target == "ec718pv" then
                lib_fw = "audio"
                lib_ps_plat = "ims"
                add_defines("FEATURE_AMR_CP_ENABLE","FEATURE_VEM_CP_ENABLE")
            elseif chip_target == "ec718p" or chip_target == "ec718e" and has_config("denoise_force") then
                lib_fw = "audio"
                add_defines("FEATURE_AMR_CP_ENABLE","FEATURE_VEM_CP_ENABLE")
            elseif chip_target == "ec716e" then
                lib_ps_plat = "ram"
                lib_ps_plat = "ram"
            else
                add_defines("MID_FEATURE_MODE")
                lib_ps_plat = "mid"
                lib_fw = "wifi"
            end
        end
        set_values("lib_ps_plat", lib_ps_plat)
        set_values("lib_fw", lib_fw)
    end

    add_defines("__USER_CODE__",
                "CORE_IS_AP",
                "SDK_REL_BUILD",
                "RAMCODE_COMPRESS_EN",
                "REL_COMPRESS_EN",
                "ARM_MATH_CM3",
                "FEATURE_LZMA_ENABLE",
                "WDT_FEATURE_ENABLE=1",
                "TRACE_LEVEL=5",
                "SOFTPACK_VERSION=\"\"",
                "HAVE_STRUCT_TIMESPEC",
                "FEATURE_FOTAPAR_ENABLE",
                "__ASSEMBLY__",
                "__CURRENT_FILE_NAME__=__FILE__"
                )

    add_cxflags("-g3",
                "-mcpu=cortex-m3",
                "-mthumb",
                "-nostartfiles",
                "-mapcs-frame",
                "-ffunction-sections",
                "-fdata-sections",
                "-fno-isolate-erroneous-paths-dereference",
                "-freorder-blocks-algorithm=stc",
                "-Wno-format",
                {force=true})

    add_cxflags("-Werror=maybe-uninitialized", {force=true})

    add_asflags("-mcpu=cortex-m3 -mthumb",{force = true})

    add_ldflags("-mcpu=cortex-m3",
                "-mthumb",
                "--specs=nano.specs",
                "-lm",
                "-Wl,--cref",
                "-Wl,--check-sections",
                "-Wl,--gc-sections",
                "-Wl,--no-undefined",
                "-Wl,--no-print-map-discarded",
                "-Wl,--print-memory-usage",
                {force = true})
    -- SDK通用头文件引用
    add_includedirs(csdk_root.."/PLAT/device/target/board/common/ARMCM3/inc",
                    csdk_root.."/PLAT/device/target/board/ec7xx_0h00/common/inc",
                    csdk_root.."/PLAT/device/target/board/ec7xx_0h00/common/pkginc",
                    csdk_root.."/PLAT/device/target/board/ec7xx_0h00/ap/gcc",
                    csdk_root.."/PLAT/device/target/board/ec7xx_0h00/ap/inc",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/eeprom",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera/sp0A39",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera/sp0821",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera/gc6123",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera/gc6153",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera/gc032A",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/camera/bf30a2",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/audio",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/audio/codec",
                    -- csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/audio/codec/es8388",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/audio/codec/es8311",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/lcd/lcdDev",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/lcd",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/ntc",
                    csdk_root.."/PLAT/driver/board/ec7xx_0h00/inc/exstorage",
                    csdk_root.."/PLAT/driver/hal/common/inc",
                    csdk_root.."/PLAT/driver/hal/ec7xx/ap/inc",
                    csdk_root.."/PLAT/driver/chip/ec7xx/ap/inc",
                    csdk_root.."/PLAT/driver/chip/ec7xx/ap/inc_cmsis",
                    csdk_root.."/PLAT/os/freertos/inc",
                    csdk_root.."/PLAT/os/freertos/CMSIS/common/inc",
                    csdk_root.."/PLAT/os/freertos/CMSIS/ap/inc",
                    csdk_root.."/PLAT/os/freertos/portable/mem/tlsf",
                    csdk_root.."/PLAT/os/freertos/portable/gcc",
                    csdk_root.."/PLAT/middleware/developed/nvram/inc",
                    csdk_root.."/PLAT/middleware/developed/nvram/ec7xx/inc",
                    csdk_root.."/PLAT/middleware/developed/cms/psdial/inc",
                    csdk_root.."/PLAT/middleware/developed/cms/cms/inc",
                    csdk_root.."/PLAT/middleware/developed/cms/psil/inc",
                    csdk_root.."/PLAT/middleware/developed/cms/psstk/inc",
                    csdk_root.."/PLAT/middleware/developed/cms/sockmgr/inc",
                    csdk_root.."/PLAT/middleware/developed/cms/cmsnetlight/inc",
                    csdk_root.."/PLAT/middleware/developed/ecapi/aal/inc",
                    csdk_root.."/PLAT/middleware/developed/ecapi/appmwapi/inc",
                    csdk_root.."/PLAT/middleware/developed/ecapi/psapi/inc",
                    csdk_root.."/PLAT/middleware/developed/common/inc",
                    csdk_root.."/PLAT/middleware/developed/psnv/inc",
                    csdk_root.."/PLAT/middleware/developed/tcpipmgr/app/inc",
                    csdk_root.."/PLAT/middleware/developed/tcpipmgr/common/inc",
                    csdk_root.."/PLAT/middleware/developed/yrcompress",
                    csdk_root.."/PLAT/middleware/thirdparty/lwip/src/include",
                    csdk_root.."/PLAT/middleware/thirdparty/lwip/src/include/lwip",
                    csdk_root.."/PLAT/middleware/thirdparty/lwip/src/include/posix",
                    csdk_root.."/PLAT/middleware/developed/ccio/pub",
                    csdk_root.."/PLAT/middleware/developed/ccio/device/inc",
                    csdk_root.."/PLAT/middleware/developed/ccio/service/inc",
                    csdk_root.."/PLAT/middleware/developed/ccio/custom/inc",
                    csdk_root.."/PLAT/middleware/developed/fota/pub",
                    csdk_root.."/PLAT/middleware/developed/fota/custom/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atdecoder/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atps/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atps/inc/cnfind",
                    csdk_root.."/PLAT/middleware/developed/at/atcust/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atcust/inc/cnfind",
                    csdk_root.."/PLAT/middleware/developed/at/atentity/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atreply/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atref/inc",
                    csdk_root.."/PLAT/middleware/developed/at/atref/inc/cnfind",
                    csdk_root.."/PLAT/core/driver/include",
                    csdk_root.."/PLAT/core/common/include",
                    csdk_root.."/PLAT/core/multimedia/include",
                    csdk_root.."/PLAT/core/tts/include",
                    csdk_root.."/PLAT/prebuild/PS/inc",
                    csdk_root.."/PLAT/prebuild/PLAT/inc")

    on_load(function (target)
        local csdk_root = target:values("csdk_root")
        local chip_target = get_config("chip_target")
        assert (chip_target == "ec718e" or chip_target == "ec718p" or chip_target == "ec718pv" or chip_target == "ec718s" or chip_target == "ec716s" or chip_target == "ec716e" ,"target only support ec718e/ec718p/ec718pv/ec718s/ec716s/ec716e")
        
        if target:name()== target:values("project_name") then
            assert(os.isdir(target:values("luatos_root")),"luatos_root:"..target:values("luatos_root").." not exist")
            local plat_url = "http://cdndownload.openluat.com/xmake/libs/%s/%s.7z"
            cprint(format("${cyan}CPU : ${magenta}%s",os.cpuinfo("model_name")))
            cprint(format("${cyan}MEM : ${magenta}%sG",math.ceil(os.meminfo("totalsize")/1024)))
            cprint(format("${cyan}project_name : ${magenta}%s",target:values("project_name")))
            cprint(format("${cyan}chip_target : ${magenta}%s",chip_target))
            cprint(format("${cyan}lspd_mode : ${magenta}%s",get_config("lspd_mode")))
            cprint(format("${cyan}denoise_force : ${magenta}%s",get_config("denoise_force")))

            local libs_plat = (chip_target=="ec718e"and"ec718p"or chip_target)..(target:values("lib_ps_plat")=="mid"and"-mid"or"")
            cprint(format("${cyan}libs_plat : ${magenta}%s",libs_plat))
            local libs_plat_dir = csdk_root.."/PLAT/libs/"..libs_plat
            import("core.base.json")
            local metas_table = json.loadfile(csdk_root.."/PLAT/libs/metas.json")
            local plat_sha1 = metas_table["libs"][libs_plat]["sha1"]
            
            if not os.isfile(csdk_root.."/PLAT/libs/"..plat_sha1..".7z") or plat_sha1 ~= hash.sha1(csdk_root.."/PLAT/libs/"..plat_sha1..".7z") then
                import("net.http")
                if os.isdir(libs_plat_dir) then os.rmdir(libs_plat_dir) end
                http.download(format(plat_url,libs_plat,plat_sha1), csdk_root.."/PLAT/libs/"..plat_sha1..".7z")
            end
            assert(os.isfile(csdk_root.."/PLAT/libs/"..plat_sha1..".7z"),csdk_root.."/PLAT/libs/"..plat_sha1..".7z".." not exist , mabe download failed")

            if not os.isdir(libs_plat_dir) then
                import("utils.archive")
                archive.extract(csdk_root.."/PLAT/libs/"..plat_sha1..".7z", libs_plat_dir)
            end
        end
        
        for _, filepath in ipairs(os.files(target:values("project_dir").."/**/mem_map_7xx.h")) do
            print(filepath)
            if path.filename(filepath) == "mem_map_7xx.h" then
                target:add("defines", "__USER_MAP_CONF_FILE__=\"mem_map_7xx.h\"")
                target:add("includedirs", path.directory(filepath))
                break
            end
        end
    end)

    after_load(function (target)
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.sourcekind == "as" then -- only asm files
                for idx, objectfile in ipairs(sourcebatch.objectfiles) do
                    sourcebatch.objectfiles[idx] = objectfile:gsub("%.S%.o", ".o")
                end
            end
            if sourcebatch.sourcekind == "cc" then -- only c files
                for idx, objectfile in ipairs(sourcebatch.objectfiles) do
                    sourcebatch.objectfiles[idx] = objectfile:gsub("%.c%.o", ".o")
                end
            end
        end
    end)

end

includes("bootloader/bootloader.lua")
includes("project/project.lua")

