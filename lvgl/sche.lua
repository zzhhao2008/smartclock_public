function startScheDule()
    lvgl.obj_clean(mainscreen)

    local toolTop = autoCreateLabelForm_MS(nil, 5, 5, 310, 29, "日程表 按下O可同步云", 16, lvgl.ALIGN_LEFT)

    local listr = lvgl.list_create(mainscreen, nil)
    lvgl.obj_set_size(listr, 320, 210);
    lvgl.obj_set_pos(listr, 0, 33);
    lvgl.list_set_anim_time(listr, 500)
    lvgl.list_set_edge_flash(listr, true)
    ::scheitems::

    local list_btns = {};
    local nowSelect = 1
    lvgl.list_clean(listr)
    local now = getLocalTime()
    for k, v in pairs(schedule) do
        local timeStr = ""
        if v.time.y == now.year and v.time.mon == now.m and v.time.d == now.day then
            v.time.s = nil
            timeStr = timeformat(v.time)
        else
            timeStr = datetimeformat(v.time)
        end
        list_btns[k] = lvgl.list_add_btn(listr, lvgl.SYMBOL_LIST,timeStr.. " " .. v["text"])
    end

    ::schefocus::
    log.info("scheitems", "focusing", nowSelect)
    lvgl.list_focus(list_btns[nowSelect], lvgl.ANIM_ON)
    ::keysolve::
    sys.wait(100)
    local res, keyid = sys.waitUntil("keyDown")
    if keyid == "B" then
        nowSelect = nowSelect + 1
        if nowSelect > #schedule then
            nowSelect = 1
        end
    elseif keyid == "A" then
        nowSelect = nowSelect - 1
        if nowSelect < 1 then
            nowSelect = #schedule
        end
    elseif keyid == "O" then
        if SyncSchedule() then
            lvgl.label_set_text(toolTop, "日程表 #00ff00 同步成功#")
            sys.timerStart(function()
                lvgl.label_set_text(toolTop, "日程表 按下O可同步云")
            end, 2000)
            goto scheitems
        else
            lvgl.label_set_text(toolTop, "日程表 #ff0000 同步失败#")
        end
    elseif keyid == "X" then
        return
    else
        goto keysolve
    end
    goto schefocus
end
