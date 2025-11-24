sys.taskInit(function()
    log.info("start", PROJECT, VERSION)
    lcd.showImage(0, 0, "/luadb/startbg.jpg")
    setMute(1)
    sys.wait(100)
    playSound("start")
    sys.wait(300)
    lvgl.init()
    lvgl.theme_set_act("material_light")

    fontlist = {
        [14] = lvgl.font_load("/luadb/sy_14.bin"), -- 全部ASCII和一些中文和字符
        [28] = lvgl.font_load("/luadb/xsf_28.bin"), -- 像素风字体，全部ASCII和一些中文和字符，含℃
        [56] = lvgl.font_load("/luadb/xsf_56.bin"), -- 仅ASCII，含℃
        [12] = lvgl.font_get("opposans_m_12"),
        [22] = lvgl.font_get("opposans_m_22"),
        [16] = lvgl.font_get("opposans_m_16") -- 字库比较全的opposans 但是没有中文和特殊符号，比如°，有％
    }

    mainscreen = lvgl.obj_create(lvgl.scr_act())
    lvgl.obj_set_size(mainscreen, 320, 240)
    lvgl.obj_set_pos(mainscreen, 0, 0)
    local style_msc = lvgl.style_t();
    lvgl.style_init(style_msc);
    lvgl.style_set_border_width(style_msc, lvgl.STATE_DEFAULT, 0)
    lvgl.style_set_bg_color(style_msc, lvgl.STATE_DEFAULT, lvgl.color_make(225, 235, 245))
    lvgl.obj_add_style(mainscreen, lvgl.OBJ_PART_MAIN, style_msc)
    lvgl.scr_load(mainscreen)

    startWifiSelector()
    init = "lvglok"

    sys.timerLoopStart(function()
        batSetFuc()
    end, 2000)

    ::mainFunc::
    lvgl.obj_clean(lvgl.scr_act())
    mainscreenStart()
    batSetFuc()
    ::mainFuncKeys::
    local res, keyid = sys.waitUntil("keyDown")
    if keyid == "O" then
        stopMainscreen()
        startMenu()
        sys.wait(200)
    elseif keyid == "X" then
        sleep()
    elseif keyid == "B" then
        stopMainscreen()
        startWeather()
        goto mainFunc
    elseif keyid == "A" then
        stopMainscreen()
        startTimer()
        goto mainFunc
    else
        goto mainFuncKeys
    end
    goto mainFunc
    ::endoflvgl::
end)

function batSetFuc()
    if batLabel ~= nil and psCfg.mode ~= "lcdoff" then
        local color = "fffff"
        local clk = mcu.getClk()
        if clk == 80 then
            color = "F1C40F"
        elseif clk == 240 then
            color = "3498DB"
        end
        if batp <= 20 or batv <= 3.55 then
            color = "ff0000"
        end
        if usbV >= 4.3 then
            color = "00ff00"
        end
        local netinfos = "E"
        local netcolor = "ff0000"
        local rssi = netInfo.rssi
        if rssi < -25 and rssi > -65 then
            netcolor = "00ff00"
            netinfos = "G"
        elseif rssi < -65 and rssi > -85 then
            netcolor = "FFC40F"
            netinfos = "L"
        end
        lvgl.label_set_text(batLabel,
            colorText(netinfos, netcolor) .. " " .. colorText(string.format("%d", batp) .. "%", color))
    end
end
