project_dir = os.scriptdir()
project_name = project_dir:match(".+[/\\]([%w_]+)")

csdk_root = "../../" --csdk根目录,可自行修改
includes(csdk_root.."csdk.lua")
description_common()

target(project_name,function()
    set_kind("static")
    set_targetdir("$(buildir)/".. project_name .. "/")
    description_csdk()
    -- set_warnings("error")

    local chip_target = get_config("chip_target")
csdk_root = "../../" --csdk根目录,可自行修改
    add_linkdirs(csdk_root.."/lib",csdk_root.."/PLAT/core/lib",{public = true})
    add_linkgroups("mp3", {whole = true,public = true})
    
    on_config(function(target)
        assert (chip_target == "ec718p" or chip_target == "ec718pv" or chip_target == "ec718e" ,"luatos only support ec718p/ec718pv/ec718e")
        -- toolchains = target:tool("cc"):match('.+\\bin')
        -- local parameter = {"-E","-P"}
        -- for _, define_flasg in pairs(target:get("defines")) do
        --     table.insert(parameter,"-D" .. define_flasg)
        -- end
        -- print(parameter)
        -- os.execv(toolchains .. "/arm-none-eabi-gcc",table.join(parameter, {"-o",SDK_PATH .. "/project/luatos/inc/luat_conf_bsp.txt","-"}),{stdin = SDK_PATH .. "/project/luatos/inc/luat_conf_bsp.h"})
        
        local conf_data = io.readfile("./inc/luat_conf_bsp.h")
        local ap_load_add
        if chip_target == "ec718p" and has_config("denoise_force") or chip_target == "ec718pv" then ap_load_add = "0x000Ba000" -- ec718pv AP_FLASH_LOAD_ADDR
        elseif chip_target == "ec718p" then ap_load_add = "0x0007e000"  -- ec718p AP_FLASH_LOAD_ADDR
        end
        local FLASH_FOTA_REGION_START = 0x340000 -- ec718p/ec718pv FLASH_FOTA_REGION_START
        -- print("FLASH_FOTA_REGION_START",FLASH_FOTA_REGION_START)
        local LUAT_SCRIPT_SIZE = tonumber(conf_data:match("\r#define LUAT_SCRIPT_SIZE (%d+)") or conf_data:match("\n#define LUAT_SCRIPT_SIZE (%d+)"))
        local LUAT_SCRIPT_OTA_SIZE = tonumber(conf_data:match("\r#define LUAT_SCRIPT_OTA_SIZE (%d+)") or conf_data:match("\n#define LUAT_SCRIPT_OTA_SIZE (%d+)"))
        -- print(string.format("script zone %d ota %d", LUAT_SCRIPT_SIZE, LUAT_SCRIPT_OTA_SIZE))
        if chip_target == "ec718pv" and LUAT_SCRIPT_SIZE > 128 then
            LUAT_SCRIPT_SIZE = 128
            LUAT_SCRIPT_OTA_SIZE = 96
        end
        local LUA_SCRIPT_ADDR = FLASH_FOTA_REGION_START - (LUAT_SCRIPT_SIZE + LUAT_SCRIPT_OTA_SIZE) * 1024
        local LUA_SCRIPT_OTA_ADDR = FLASH_FOTA_REGION_START - LUAT_SCRIPT_OTA_SIZE * 1024
        local script_addr = string.format("%X", LUA_SCRIPT_ADDR)
        local full_addr = string.format("%X", LUA_SCRIPT_OTA_ADDR)
        -- print("LUA_SCRIPT_ADDR",LUA_SCRIPT_ADDR)
        -- print("LUA_SCRIPT_OTA_ADDR",LUA_SCRIPT_OTA_ADDR)
        -- print("script_addr",script_addr)
        target:add("defines","AP_FLASH_LOAD_SIZE=0x"..script_addr.."-"..ap_load_add,{public = true})
        target:add("defines","AP_PKGIMG_LIMIT_SIZE=0x"..script_addr.."-"..ap_load_add,{public = true})
        target:add("linkgroups","tts_res", {whole = true,public = true})
        local LUAT_USE_TTS_8K = conf_data:find("\r#define LUAT_USE_TTS_8K") or conf_data:find("\n#define LUAT_USE_TTS_8K")
        if LUAT_USE_TTS_8K then
            target:add("linkgroups","aisound50_8K", {whole = true,public = true})
        else 
            target:add("linkgroups","aisound50_16K", {whole = true,public = true})
        end
		target:add("linkgroups","image_decoder_0", {whole = true,public = true})
        local LUAT_USE_TLS_DISABLE = conf_data:find("\r#define LUAT_USE_TLS_DISABLE") or conf_data:find("\n#define LUAT_USE_TLS_DISABLE")
        if not LUAT_USE_TLS_DISABLE then
            -- mbedtls
            target:add("defines", "LUAT_USE_TLS",{public = true})
        end
    end)

    if chip_target == "ec718pv" then
        -- cc
        add_files(luatos_root.."/components/cc/*.c")
    end

    add_defines("__LUATOS__",{public = true})

    add_includedirs(luatos_root.."/lua/include",{public = true})
    add_files(luatos_root .. "/lua/src/*.c")
    add_files(luatos_root .. "/luat/modules/*.c")

    add_files(luatos_root.."/luat/freertos/luat_timer_freertos.c")
    add_files(luatos_root.."/luat/freertos/luat_msgbus_freertos.c")
    -- weak
    add_files(luatos_root.."/luat/weak/luat_rtos_lua.c")
    -- common
    add_includedirs(luatos_root.."/components/common",{public = true})
    -- add_files(luatos_root.."/components/common/*.c")
    -- mobile
    add_files(luatos_root.."/components/mobile/luat_lib_mobile.c")
    -- sms
    add_files(luatos_root.."/components/sms/*.c")
    -- hmeta
    add_includedirs(luatos_root.."/components/hmeta",{public = true})
    add_files(luatos_root.."/components/hmeta/*.c")
    -- profiler
    add_includedirs(luatos_root.."/components/mempool/profiler/include",{public = true})
    add_files(luatos_root.."/components/mempool/profiler/**.c")
    -- rsa
    add_files(luatos_root.."/components/rsa/**.c")
    -- lua-cjson
    add_includedirs(luatos_root .. "/components/lua-cjson",{public = true})
    add_files(luatos_root .. "/components/lua-cjson/*.c")
    -- fastlz
    add_includedirs(luatos_root .. "/components/fastlz",{public = true})
    add_files(luatos_root .. "/components/fastlz/*.c")
    -- miniz
    add_includedirs(luatos_root .. "/components/miniz",{public = true})
    add_files(luatos_root .. "/components/miniz/*.c")
    -- coremark
    add_includedirs(luatos_root .. "/components/coremark",{public = true})
    add_files(luatos_root .. "/components/coremark/*.c")
    -- gmssl
    add_includedirs(luatos_root .. "/components/gmssl/include",{public = true})
    add_files(luatos_root .. "/components/gmssl/**.c")
    -- protobuf
    add_includedirs(luatos_root.."/components/serialization/protobuf",{public = true})
    add_files(luatos_root.."/components/serialization/protobuf/*.c")
    -- vfs
    add_files(luatos_root.."/luat/vfs/*.c")
    remove_files(luatos_root.."/luat/vfs/luat_fs_lfs2.c",
            luatos_root.."/luat/vfs/luat_vfs.c")
    -- fatfs
    add_includedirs(luatos_root.."/components/fatfs",{public = true})
    add_files(luatos_root.."/components/fatfs/*.c")
    -- sfud
    add_includedirs(luatos_root.."/components/sfud",{public = true})
    add_files(luatos_root.."/components/sfud/*.c")
    -- fskv
    add_includedirs(luatos_root.."/components/fskv",{public = true})
    add_files(luatos_root.."/components/fskv/*.c")
    -- fonts
    add_includedirs(luatos_root.."/components/luatfonts",{public = true})
    add_files(luatos_root.."/components/luatfonts/*.c")
    -- gtfont
    add_includedirs(luatos_root.."/components/gtfont",{public = true})
    add_files(luatos_root.."/components/gtfont/*.c")
    add_links("gt")
    -- eink
    add_includedirs(luatos_root.."/components/eink",{public = true})
    add_includedirs(luatos_root.."/components/epaper",{public = true})
    add_files(luatos_root.."/components/eink/*.c")
    add_files(luatos_root.."/components/epaper/*.c")
    remove_files(luatos_root.."/components/epaper/GUI_Paint.c")
    -- u8g2
    add_includedirs(luatos_root.."/components/u8g2", {public = true})
    add_files(luatos_root.."/components/u8g2/*.c")
    -- lcd
    add_includedirs(luatos_root.."/components/lcd", {public = true})
    add_files(luatos_root.."/components/lcd/*.c")
    -- qrcode
    add_includedirs(luatos_root.."/components/tjpgd", {public = true})
    add_files(luatos_root.."/components/tjpgd/*.c")
    -- qrcode
    add_includedirs(luatos_root.."/components/qrcode", {public = true})
    add_files(luatos_root.."/components/qrcode/*.c")
    -- lvgl
    add_includedirs(luatos_root.."/components/lvgl", {public = true})
    add_includedirs(luatos_root.."/components/lvgl/binding", {public = true})
    add_includedirs(luatos_root.."/components/lvgl/gen", {public = true})
    add_includedirs(luatos_root.."/components/lvgl/src", {public = true})
    add_includedirs(luatos_root.."/components/lvgl/font", {public = true})
    add_includedirs(luatos_root.."/components/lvgl/src/lv_font", {public = true})
    add_files(luatos_root.."/components/lvgl/**.c")
    -- 默认不编译lv的demos, 节省大量的编译时间
    remove_files(luatos_root.."/components/lvgl/lv_demos/**.c")
    -- i2c-tools
    add_includedirs(luatos_root.."/components/i2c-tools",{public = true})
    add_files(luatos_root.."/components/i2c-tools/*.c")
    -- lora
    add_includedirs(luatos_root.."/components/lora/sx126x",{public = true})
    add_files(luatos_root.."/components/lora/**.c")
    -- lora2
    add_includedirs(luatos_root.."/components/lora2/sx126x",{public = true})
    add_files(luatos_root.."/components/lora2/**.c")
    -- libgnss
    add_files(luatos_root.."/components/minmea/*.c|minmea.c")
    -- mlx90640
    add_includedirs(luatos_root.."/components/mlx90640-library",{public = true})
    add_files(luatos_root.."/components/mlx90640-library/*.c")
    -- wlan
    add_files(luatos_root.."/components/wlan/*.c")
    -- audio
    add_includedirs(luatos_root.."/components/multimedia/",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/mp3_decode",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/amr_common/dec/include",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/amr_nb/common/include",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/amr_nb/dec/include",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/amr_wb/dec/include",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/opencore-amrnb",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/opencore-amrwb",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/oscl",{public = true})
    add_includedirs(luatos_root.."/components/multimedia/amr_decode/amr_nb/enc/src",{public = true})
    add_files(luatos_root.."/components/multimedia/**.c")
	if chip_target == "ec718p" and has_config("denoise_force") or chip_target == "ec718pv" then
		remove_files(luatos_root .. "/components/multimedia/amr_decode/**.c")
	end
    -- network
    add_includedirs(luatos_root .. "/components/ethernet/w5500", {public = true})
    add_files(luatos_root .. "/components/ethernet/**.c")
	remove_files(luatos_root .."/components/ethernet/common/dns_client.c")
    add_files(luatos_root .."/components/network/adapter/luat_lib_socket.c")
    -- mqtt
    add_includedirs(luatos_root.."/components/network/libemqtt", {public = true})
    add_files(luatos_root.."/components/network/libemqtt/*.c")
    -- http
    add_includedirs(luatos_root.."/components/network/libhttp", {public = true})
    add_files(luatos_root.."/components/network/libhttp/*.c")
    -- http_parser
    add_includedirs(luatos_root.."/components/network/http_parser", {public = true})
    add_files(luatos_root.."/components/network/http_parser/*.c")
    -- websocket
    add_includedirs(luatos_root.."/components/network/websocket", {public = true})
    add_files(luatos_root.."/components/network/websocket/*.c")
    -- errdump
    add_includedirs(luatos_root.."/components/network/errdump", {public = true})
    add_files(luatos_root.."/components/network/errdump/*.c")
    -- -- httpsrv
    add_includedirs(luatos_root.."/components/network/httpsrv/inc", {public = true})
    add_files(luatos_root.."/components/network/httpsrv/src/*.c")
    -- iotauth
    add_includedirs(luatos_root.."/components/iotauth", {public = true})
    add_files(luatos_root.."/components/iotauth/*.c")
    -- sntp
    add_includedirs(luatos_root.."/components/network/libsntp", {public = true})
    add_files(luatos_root.."/components/network/libsntp/*.c")
    -- libftp
    add_includedirs(luatos_root.."/components/network/libftp", {public = true})
    add_files(luatos_root.."/components/network/libftp/*.c")
    -- sfd
    add_includedirs(luatos_root.."/components/sfd", {public = true})
    add_files(luatos_root.."/components/sfd/*.c")
    -- fatfs
    add_includedirs(luatos_root.."/components/fatfs", {public = true})
    add_files(luatos_root.."/components/fatfs/*.c")
    -- iconv
    add_includedirs(luatos_root.."/components/iconv", {public = true})
    add_files(luatos_root.."/components/iconv/*.c")
    remove_files(luatos_root.."/components/iconv/luat_iconv.c")
    -- max30102
    add_includedirs(luatos_root.."/components/max30102", {public = true})
    add_files(luatos_root.."/components/max30102/*.c")
    -- ymodem
    add_includedirs(luatos_root.."/components/ymodem", {public = true})
    add_files(luatos_root.."/components/ymodem/*.c")
    -- shell
    add_includedirs(luatos_root .. "/components/shell", {public = true})
    add_files(luatos_root.."/components/shell/*.c")
    -- cmux
    add_includedirs(luatos_root .. "/components/cmux", {public = true})
    add_files(luatos_root .. "/components/cmux/*.c")
    -- repl
    add_includedirs(luatos_root.."/components/repl", {public = true})
    add_files(luatos_root.."/components/repl/*.c")
    -- statem
    add_includedirs(luatos_root.."/components/statem", {public = true})
    add_files(luatos_root.."/components/statem/*.c")
    -- ercoap
    add_includedirs(luatos_root.."/components/network/ercoap/include",{public = true})
    add_files(luatos_root.."/components/network/ercoap/src/*.c")
    add_files(luatos_root.."/components/network/ercoap/binding/*.c")
    -- sqlite3
    add_includedirs(luatos_root.."/components/sqlite3/include",{public = true})
    add_files(luatos_root.."/components/sqlite3/src/*.c")
    add_files(luatos_root.."/components/sqlite3/binding/*.c")
    -- ws2812 单独的库
    add_includedirs(luatos_root.."/components/ws2812/include",{public = true})
    add_files(luatos_root.."/components/ws2812/src/*.c")
    add_files(luatos_root.."/components/ws2812/binding/*.c")
    -- xxtea
    add_includedirs(luatos_root.."/components/xxtea/include",{public = true})
    add_files(luatos_root.."/components/xxtea/src/*.c")
    add_files(luatos_root.."/components/xxtea/binding/*.c")
	-- ioqueue
	add_files(luatos_root.."/components/io_queue/*.c")
	-- camera
	add_includedirs(luatos_root.."/components/tiny_jpeg", {public = true})
	add_files(luatos_root.."/components/camera/*.c")
	add_files(luatos_root.."/components/tiny_jpeg/*.c")
    --加入代码和头文件
    add_includedirs("./inc",{public = true})
    add_files("./src/*.c",{public = true})

end)