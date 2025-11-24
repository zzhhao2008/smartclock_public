function startMenu()
    lvgl.obj_clean(mainscreen)

    local listr = lvgl.list_create(mainscreen, nil)
    lvgl.obj_set_size(listr, 320, 240);
    lvgl.obj_align(listr, nil, lvgl.ALIGN_CENTER, 0, 0);
    lvgl.list_set_anim_time(listr, 500)
    lvgl.list_set_edge_flash(listr, true)
    local page = "main"
    local menubtn = {}
    ::menuitems::
    lvgl.list_clean(listr)
    if page == "main" then
        menubtn = {{
            text = " 日历",
            func = calendarBegin
        }, {
            text = " 计时器",
            func = startTimer
        }, {
            text = " 天气",
            func = startWeather
        }, {
            text = " 日程表",
            func = startScheDule
        }, {
            text = " 设备信息与设置",
            func = nil,
            cpage = "SETTINGS"
        }, {
            text = (netStatus and "立即同步远程设置" or "连接WIFI后同步远程设置"),
            func = getSysCfg
        }}
    elseif page == "SETTINGS" then
        menubtn = {{
            text = " 返回",
            func = nil,
            cpage = "main"
        }, {
            text = "设备ID(MAC):" .. device_id
        }, {
            text = "版本:" .. VERSION .. "_Code By Dinner"
        }, {
            text = "IP:" .. localIP
        }, {
            text = (netStatus and "断开WIFI连接" or "连接WIFI"),
            func = function()
                if netStatus then
                    sys.publish("WIFIDISCONNECT")
                    sys.wait(500)
                else
                    startWifiSelector()
                end
            end
        }, {
            text = " 重置所有设置",
            func = resetAllSetting
        }, {
            text = " 关机",
            func = poweroff
        }, {
            text = " 睡眠",
            func = Dsp__
        }}
    end

    local list_btns = {};
    local nowSelect = 1

    for k, v in pairs(menubtn) do
        list_btns[k] = lvgl.list_add_btn(listr, lvgl.SYMBOL_LIST, v["text"])
    end

    ::focusr::
    lvgl.list_focus(list_btns[nowSelect], lvgl.ANIM_ON)
    for k, v in pairs(list_btns) do
        lvgl.obj_set_style_local_bg_color(v, lvgl.BTN_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_make(0xff, 0xff, 0xff));
    end
    lvgl.obj_set_style_local_bg_color(list_btns[nowSelect], lvgl.BTN_PART_MAIN, lvgl.STATE_DEFAULT,
        lvgl.color_make(0x61, 0xE2, 0xF1));

    ::keysolve::
    sys.wait(100)
    local res, keyid = sys.waitUntil("keyDown")
    if keyid == "B" then
        nowSelect = nowSelect + 1
        if nowSelect > #menubtn then
            nowSelect = 1
        end
    elseif keyid == "A" then
        nowSelect = nowSelect - 1
        if nowSelect < 1 then
            nowSelect = #menubtn
        end
    elseif keyid == "O" then
        if menubtn[nowSelect]["cpage"] ~= nil then
            page = menubtn[nowSelect]["cpage"]
            goto menuitems
        end
        if (menubtn[nowSelect]["func"] == nil) then
            goto keysolve
        end
        menubtn[nowSelect]["func"]()
        return
    elseif keyid == "X" then

        return
    else
        goto keysolve
    end
    goto focusr
end

function Dsp__()
    sys.timerStart(sleep, 500)
end

function resetAllSetting()
    dbClear()
    delayPowerOff(0)
    lvgl.obj_clean(mainscreen)
end
