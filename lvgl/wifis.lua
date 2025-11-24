function startWifiSelector()
    lvgl.obj_clean(mainscreen)

    local labelTop = lvgl.label_create(mainscreen)
    lvgl.label_set_align(labelTop, lvgl.LABEL_ALIGN_CENTER)
    lvgl.label_set_long_mode(labelTop, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.obj_set_size(labelTop, 320, 29)
    lvgl.obj_set_pos(labelTop, 0, 10)
    lvgl.label_set_recolor(labelTop, true);
    lvgl.label_set_text(labelTop, "选择一个WiFi,或按下X键恢复默认WIFI配置")
    lvgl.obj_set_style_local_text_font(labelTop, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[16])

    local listr = lvgl.list_create(mainscreen, nil)
    lvgl.obj_set_size(listr, 320, 180);
    lvgl.obj_align(listr, nil, lvgl.ALIGN_CENTER, 0, 0);
    lvgl.list_set_anim_time(listr, 250)
    lvgl.list_set_edge_flash(listr, true)

    local labelr = lvgl.label_create(mainscreen)
    lvgl.obj_set_style_local_text_font(labelr, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[16])
    lvgl.label_set_text(labelr, "等待选择wifi")
    lvgl.label_set_align(labelr, lvgl.LABEL_ALIGN_CENTER)
    lvgl.label_set_long_mode(labelr, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.label_set_recolor(labelr, true)
    lvgl.obj_set_size(labelr, 320, 29)
    lvgl.obj_set_pos(labelr, 0, 210)

    local wifilist = {}
    for k,v in pairs(sysConfig.wifilist) do
        wifilist[#wifilist + 1] = v
    end
    listMergeUnique(wifilist,morewifi)
    local list_btns = {};
    local nowSelect = 1

    for k, v in pairs(wifilist) do
        list_btns[k] = lvgl.list_add_btn(listr, lvgl.SYMBOL_FILE, v["ssid"] .. " " .. v["password"])
    end
    local first_click = true
    if (sysConfig.wifi ~= nil and sysConfig.wifi.ssid~=nil and sysConfig.wifi.password~=nil) then
        first_click = false
        lvgl.label_set_text(labelr, "1S 后自动连接:" .. sysConfig.wifi.ssid)
    end
    ::focusr::
    lvgl.list_focus(list_btns[nowSelect], lvgl.ANIM_ON)
    for k, v in pairs(list_btns) do
        lvgl.obj_set_style_local_bg_color(v, lvgl.BTN_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_make(0xff, 0xff, 0xff));
    end
    lvgl.obj_set_style_local_bg_color(list_btns[nowSelect], lvgl.BTN_PART_MAIN, lvgl.STATE_DEFAULT,
        lvgl.color_make(0x61, 0xE2, 0xF1));

    ::keysolve::
    local res, keyid = sys.waitUntil("keyDown", 1000)
    if res == true then
        first_click = true
        --log.info("Cancle Auto Connect", "CAC", first_click)
        lvgl.label_set_text(labelr, "请选择一个WIFI来连接")
    else
        if first_click == false then -- 用户未作出操作
            sys.publish("WIFI_CONNECT_ON", wifilist[nowSelect])
            lvgl.label_set_text(labelr, "自动连接-" .. sysConfig.wifi.ssid .. "...")
            goto waitWiFiCONNECT
        end
    end
    if keyid == "B" then
        nowSelect = nowSelect + 1
        if nowSelect > #wifilist then
            nowSelect = 1
        end
    elseif keyid == "A" then
        nowSelect = nowSelect - 1
        if nowSelect < 1 then
            nowSelect = #wifilist
        end
    elseif keyid == "O" then
        log.info("nowSelect", nowSelect)
        sysConfig.wifi = wifilist[nowSelect]
        sys.publish("WIFI_CONNECT_ON", wifilist[nowSelect])
        lvgl.label_set_text(labelr, "connecting WIFI " .. sysConfig.wifi.ssid .. "...")
        goto waitWiFiCONNECT
        goto keysolve
    elseif keyid == "X" then
        sysConfig.wifilist = defaultSysConfig.wifilist
        sysConfig.wifi = nil
        saveSysConfig_DB()
        lvgl.label_set_text(labelr, "#e09200 WIFI 配置已恢复出厂设置...#")
        delayPowerOff(2000)
        while true do
            sys.wait(5000)
        end
    else
        goto keysolve
    end
    goto focusr
    ::waitWiFiCONNECT::
    sys.waitUntil("IP_READY", 10000)
    sys.wait(100)
    if netStatus == true then
        lvgl.label_set_text(labelr, "#00ff00 连接成功! 开始下载文件...#")
        sys.wait(200)
        goto startDownLoad
    else
        lvgl.label_set_text(labelr, "#ff0000 连接失败#")
        sys.wait(200)
        wlan.disconnect()
        log.info("wlan", "TURN DISCONNECT")
        sys.publish("WIFIDISCONNECT")
        goto keysolve
    end
    ::startDownLoad::
    lvgl.label_set_text(labelTop, "下载资源")
    sys.publish("STARTDOWNLOAD")
    if true then 
        return
    end
    lvgl.list_clean(listr)
    list_btns = {}
    local flag_ = true
    while true do
        local _, path, code = sys.waitUntil("downloading")
        if path == "end" then
            if flag_ then
                lvgl.obj_clean(mainscreen)
                sys.wait(500)
                return
            else
                delayPowerOff(5000)
                sys.wait(50000)
                return
            end
        end
        local t = lvgl.list_add_btn(listr, lvgl.SYMBOL_FILE, path .. " " .. code)
        lvgl.list_focus(t, lvgl.ANIM_ON)
        if (code == 200 or code == 201) then
            lvgl.obj_set_style_local_bg_color(t, lvgl.BTN_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_make(0, 0xff, 0));
        else
            flag_ = false
            lvgl.label_set_text(labelr, "#ff0000 error occurred when downloading " .. path .. "# Restart To Try Again!")
            lvgl.obj_set_style_local_bg_color(t, lvgl.BTN_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_make(255, 0, 0));
        end
    end
    return
end

function enableESPTOUCH()
    wlan.smartconfig()
    local ret, ssid, passwd = sys.waitUntil("SC_RESULT", 180 * 1000) -- 等3分钟
    if ret == false then
        log.info("smartconfig", "timeout")
        wlan.smartconfig(wlan.STOP)
        sys.wait(3000)
        return 0
    else
        -- 获取配网后, ssid和passwd会有值
        log.info("smartconfig", ssid, passwd)
        local ssid, password = ssid, passwd
        sysConfig.wifi.ssid = ssid
        sysConfig.wifi.password = password
        dbPut("esptouch", json.encode(sysConfig.wifi))
        sys.publish("WIFI_CONNECT_ON")
        return 1
    end
end
