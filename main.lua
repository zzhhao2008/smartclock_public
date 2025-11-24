PROJECT = "SMARTCLOCK"
VERSION = "1.2.3"
-- sys库是标配
_G.sys = require("sys")
_G.sysplus = require("sysplus")

if wdt then
    wdt.init(9000) -- 初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000) -- 3s喂一次狗
end

batp = 0
usbV = 0
batv = 0
init = "noinit"
netStatus = false
netInfo = {}
fontlist = {}
weather = {}
batPercent = 0
festivals = {}
highlighteddays = {}
schedule = {}

sysConfig = {
    wifi = nil,
    filesToDownload = {
        server = "http://iot.zsvstudio.top/dl?id=",
        files = { -- "sideback.jpg",
        --"sideback1.jpg" -- "sy_14_full.bin",
        -- "xsf_28.bin",
        -- "xsf_56.bin",
        -- "xsf_90.bin",
        }
    },
    wifilist = {{
        ssid = "DESKTOP-KDV2VVJ 0031",
        password = "b92=274Y"
    }, {
        ssid = "SEEWO",
        password = "SEEWOSEEWO"
    }}
}

defaultSysConfig = sysConfig

remoteCfg = {}
weather = {}
morewifi = {}

require "devices"
require "subc"
require "sounds"

-- === 数据库配置加载（集成化）===
local function loadDBVar(key, target, handler,params)
    local val = dbGet(key)
    if val ~= nil then
        if handler then
            handler(val, params)
        else
            _G[target] = val
        end
    end
end

loadDBVar("sysConfig", "sysConfig")
loadDBVar("festivals", "festivals")
loadDBVar("remoteCfg", nil, remoteCfgdeal)
loadDBVar("schedule", "schedule")
loadDBVar("highlighteddays", "highlighteddays")

require "wlanfunc"
require "msc"
require "wifis"
require "calendar"
require "timer_W"
require "menu"
require "weather"
require "sche"

require "lvglfunc"

sys.taskInit(function()
    while true do
        local batvtotal = 0
        local usbvtotal = 0
        for i = 0, 10, 1 do
            batvtotal = batvtotal + adc_battery()
            usbvtotal = usbvtotal + adc_usbin()
            sys.wait(50)
        end
        batv = batvtotal / 10
        usbV = usbvtotal / 10
        batp = math.floor((batv - 3.55) / (4.15 - 3.55) * 100)
        if batp > 100 then
            batp = 100
        elseif batp < 0 then
            batp = 0
        end
        batPercent = batp
        --log.info("BU", usbV, batp, batv)
        netInfo = wlan.getInfo()
        --log.info("wlan", "info", json.encode(netInfo))
        sys.wait(4500)
    end
end)

sys.taskInit(function()
    ::autoSyncStart::
    sys.waitUntil("DOWNLOAD_ENDED")
    while true do
        if netStatus == false then
            goto autoSyncStart
        end
        ::getFes::
        if not getFestivals() then
            sys.wait(3000)
            goto getFes
        end
        sys.wait(100)
        ::getSYSCFG::
        if not getSysCfg() then
            sys.wait(3000)
            goto getSYSCFG
        end
        sys.wait(100)
        ::getWea::
        if not getWeather() then
            sys.wait(3000)
            goto getWea
        end
        sys.wait(100)
        ::SyncSchedule::
        if not SyncSchedule() then
            sys.wait(3000)
            goto SyncSchedule
        end
        sys.wait(3600 * 1000) -- 等待一小时
    end
end)
sys.run()
