localIP = ""

sys.taskInit(function()
    wlan.init()
    netStatus = false
    if wlan and wlan.connect then
        ::WLANinit::
        device_id = wlan.getMac()
        log.info("device_id", "MAC", device_id)
        wlan.hostname("ZSV_SC_C_" .. device_id)
        sys.waitUntil("WIFI_CONNECT_ON")
        -- wifi 联网, ESP32系列均支持
        -- local ssid,password = "MERCURY_D0CD","yu2834139"
        local ssid, password = sysConfig.wifi.ssid, sysConfig.wifi.password
        log.info("wifi", ssid, password)
        wlan.setMode(wlan.STATION)
        wlan.connect(ssid, password, 1)
        local result, data = sys.waitUntil("IP_READY", 10000)
        log.info("wlan", "IP_READY", result, data)
        log.info("wlan", "info", json.encode(wlan.getInfo()))
        if (result) then
            localIP = data
            netStatus = true
            saveSysConfig_DB()
        else
            netStatus = false
            wlan.disconnect()
            goto WLANinit
        end
        sys.waitUntil("STARTDOWNLOAD",5000)
        local list = sysConfig.filesToDownload.files
        local fail = false
        log.info("filesToDownload", json.encode(list))
        for i = 1, #list do
            local path = list[i]
            if io.exists(path) then
                log.info("fileExist", path)
                sys.publish("downloading", path, 201)
            else
                log.info("fileNotExist", path)
                local url = sysConfig.filesToDownload.server .. path
                local res = http_download(url, "/" .. path)
                log.info("HTTPDOWNLOAD", res)
                sys.publish("downloading", path, res)
                if res ~= 200 then
                    fail = true
                end
            end
        end
        sys.publish("downloading", "end")
        sys.publish("DOWNLOAD_ENDED", fail)

        sys.waitUntil("WIFIDISCONNECT")
        if netStatus or true then
            wlan.disconnect()
        end
        netStatus = false
        goto WLANinit
    end
end)

function md5l(s)
    return string.lower(crypto.md5(s))
end

function http_get(uri)
    -- 最普通的Http GET请求
    local code, headers, body = http.request("GET", uri).wait()
    -- log.info("http.get", code, headers, body)
    return code, headers, body
end

function post_json(uri, data)
    -- POST request 演示
    local req_headers = {}
    req_headers["Content-Type"] = "application/json"
    local body = json.encode(data)
    local code, headers, body =
        http.request("POST", uri, req_headers, body -- POST请求所需要的body, string, zbuff, file均可
        ).wait()
    -- log.info("http.post", code, headers, body)
    return code, headers, body
end

function post_form(uri, data)
    -- POST request 演示
    local req_headers = {}
    req_headers["Content-Type"] = "application/x-www-form-urlencoded"
    local params = data
    if params == nil then
        params = {}
    end
    local body = ""
    for k, v in pairs(params) do
        body = body .. tostring(k) .. "=" .. tostring(v):urlEncode() .. "&"
    end
    local code, headers, body =
        http.request("POST", uri, req_headers, body -- POST请求所需要的body, string, zbuff, file均可
        ).wait()
    -- log.info("http.post.form", code, headers, body)
    return code, headers, body
end

function http_download(uri, path)

    -- POST and download, task内的同步操作
    local opts = {} -- 额外的配置项
    opts["dst"] = path -- 下载路径,可选
    opts["timeout"] = 30000 -- 超时时长,单位ms,可选
    -- opts["adapter"] = socket.ETH0  -- 使用哪个网卡,可选
    -- opts["callback"] = http_download_callback
    -- opts["userdata"] = http_userdata

    for k, v in pairs(opts) do
        print("opts", k, v)
    end

    local code, headers, body = http.request("POST", uri, {}, -- 请求所添加的 headers, 可以是nil
    "", opts).wait()
    -- log.info("http.post", code, headers, body) -- 只返回code和headers

    return code, headers
end

function getFestivals()
    local uri = "【YOUR IOT PLATFORM URL】/fes"
    local code, headers, body = http_get(uri)
    if code == 200 then
        local data = json.decode(body)
        if data ~= nil then
            log.info("festival GOT", json.encode(data))
            dbPut("festivals", data)
            festivals = data
            return true
        end
    end
    log.debug("festival", "getFestivals FAILED", code, headers, body)
    return false
end

function getSysCfg()
    local uri = "【YOUR IOT PLATFORM URL】/cfg"
    local code, headers, body = http_get(uri)
    if code == 200 then
        local data = json.decode(body)
        if data ~= nil then
            log.info("RCFG GOT", json.encode(data))
            dbPut("remoteCfg", data)
            remoteCfgdeal(data)
            if data.cfg.desktop.background ~= nil then
                local bguri = "【YOUR IOT PLATFORM URL】/back?file=".. data.cfg.desktop.background
                local bgpath = "/"..data.cfg.desktop.background
                os.remove(bgpath)
                local code, headers, body = http_download(bguri, "/"..data.cfg.desktop.background)
                if code == 200 then
                    log.info("background", "downloaded")
                else
                    os.remove(bgpath)
                    log.info("background", "download failed")
                end
            end
            return true
        end
    end
    log.debug("RCFG", "RCFG FAILED", code, headers, body)
    return false
end

function getWeather()
    local uri = "【YOUR IOT PLATFORM URL】/wea"
    local code, headers, body = http_get(uri)
    if code == 200 then
        local data = json.decode(body)
        if data ~= nil then
            log.info("weather GOT", json.encode(data))
            weather = data
            return true
        end
    end
    log.debug("weather", "getWeather FAILED", code, headers, body)
end

function SyncSchedule()
    if netStatus == false then
        log.info("SyncSchedule", "no net")
        return false
    end
    local uri = "【YOUR IOT PLATFORM URL】/sche"
    local code, headers, body = http_get(uri)
    if code == 200 then 
        local data = json.decode(body)
        if data ~= nil then
            log.info("schedule GOT", json.encode(data))
            dbPut("schedule", data)
            schedule = data
            return true
        end
    else
        log.debug("SyncSchedule", "SyncSchedule FAILED", code, headers, body)
        return false
    end
end
