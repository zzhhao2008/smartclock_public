function mainscreenStart()
    --[[mainscreen = lvgl.obj_create(mainscreen, nil)
    lvgl.obj_set_size(mainscreen, 320, 240)
    lvgl.obj_set_pos(mainscreen, 0, 0)
    lvgl.scr_load(mainscreen)]]

    --mainscreen = mainscreen

    rightImg = lvgl.img_create(mainscreen, nil);
    lvgl.img_set_src(rightImg, "/luadb/sideback.jpg")
    lvgl.obj_set_x(rightImg, 0)
    lvgl.obj_set_y(rightImg, 0)

    local leftWidth = 110 -- 左侧区域宽度
    local x = 10 -- 靠左
    local yo = 0

    -- 小时
    hourLabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(hourLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[56])
    lvgl.label_set_align(hourLabel, lvgl.LABEL_ALIGN_LEFT)
    lvgl.obj_set_size(hourLabel, leftWidth, 50)
    lvgl.obj_set_pos(hourLabel, x, 10 + yo)
    lvgl.label_set_recolor(hourLabel, true)
    lvgl.label_set_text(hourLabel, "#ffffff 00#")

    -- 日期（月-日）
    datelabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(datelabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[28]) -- 假设 fontlist[28] 存在
    lvgl.label_set_align(datelabel, lvgl.LABEL_ALIGN_LEFT)
    lvgl.label_set_long_mode(datelabel, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.obj_set_size(datelabel, leftWidth - 10, 30)
    lvgl.obj_set_pos(datelabel, x, 65 + yo)
    lvgl.label_set_recolor(datelabel, true)
    lvgl.label_set_text(datelabel, "#ffffff 00-00#")

    -- 右下角电量
    batLabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(batLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[14])
    lvgl.label_set_align(batLabel, lvgl.LABEL_ALIGN_RIGHT)
    lvgl.label_set_long_mode(batLabel, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.obj_set_size(batLabel, 100, 20)
    lvgl.obj_set_pos(batLabel, 220, 220)
    lvgl.label_set_recolor(batLabel, true)
    lvgl.label_set_text(batLabel, "#ffffff #")

    local LT_Y = 235
    LTL_S1 = autoCreateLabelForm_MS(mainscreen, x, LT_Y - 28, 60, 30, "#ffffff ??#", 28)
    LTL_M1 = autoCreateLabelForm_MS(mainscreen, x + 65, LT_Y - 50, 60, 60, "#cc0000 ??#", 56)
    LTL_E1 = autoCreateLabelForm_MS(mainscreen, x + 120, LT_Y - 28, 50, 30, "#ffffff 天#", 28)

    local WEA_Y = 95 + yo
    WEAT = autoCreateLabelForm_MS(mainscreen, x, WEA_Y, 300, 30, "#ffffff ??#", 28)

    local HIDDEN_X_POS = 1000

    local function applyComponentConfig(obj, config, fontlist)
        if config == nil then
            return
        end

        if config['display'] ~= true then
            lvgl.obj_set_pos(obj, HIDDEN_X_POS, 0)
            return
        end

        -- 设置位置
        if config['pos'] ~= nil and config['pos']['x'] ~= nil and config['pos']['y'] ~= nil then
            lvgl.obj_set_pos(obj, config['pos']['x'], config['pos']['y'])
        end

        -- 设置字体
        if config['font'] ~= nil and fontlist[config['font']] ~= nil then
            lvgl.obj_set_style_local_text_font(obj, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[config['font']])
        end
    end

    local desktopcfg = remoteCfg['desktop']
    if desktopcfg == nil then
        log.warn("desktopcfg is nil, skipping configuration")
        return
    end

    log.info("desktop", json.encode(desktopcfg))

    -- Battery
    if desktopcfg['bat'] ~= nil and desktopcfg['bat']['display'] ~= true then
        lvgl.obj_set_pos(batLabel, HIDDEN_X_POS, 0)
    end

    -- Weather
    applyComponentConfig(WEAT, desktopcfg['weather'], fontlist)

    -- Llt
    if desktopcfg['llt'] ~= nil and desktopcfg['llt']['display'] ~= true then
        lvgl.obj_set_pos(LTL_S1, HIDDEN_X_POS, 0)
        lvgl.obj_set_pos(LTL_M1, HIDDEN_X_POS, 0)
        lvgl.obj_set_pos(LTL_E1, HIDDEN_X_POS, 0)
    end

    -- Date
    applyComponentConfig(datelabel, desktopcfg['date'], fontlist)

    -- Clock
    applyComponentConfig(hourLabel, desktopcfg['clock'], fontlist)

    --background
    if desktopcfg['background'] ~= nil then
        local bgpath = "/"..desktopcfg['background']
        if io.exists(bgpath) then
            lvgl.img_set_src(rightImg, bgpath)
        else
            log.warn("background", "file not exists")
        end
    end

    AutoSetFunc()
    sys.timerLoopStart(AutoSetFunc, 1000)

    batSetFuc()
    powersave(1)
end

function stopMainscreen()
    powersave(0)
    sys.timerStopAll(AutoSetFunc)
    lvgl.obj_clean(mainscreen)
    lvgl.obj_clean(mainscreen)
    batLabel = nil
end

function AutoSetFunc()
    if datelabel then
        local hour, min, sec = formatedHourMinSec()
        local dateStr = formatedMonthDay()

        lvgl.label_set_text(hourLabel,
            colorText(hour, "eeeeee") .. colorText(":", "aaaaaa") .. colorText(min, "ffffff") ..
                colorText(":", "aaaaaa") .. colorText(sec, "aa0000"))
        lvgl.label_set_text(datelabel, colorText(dateStr, "ffffff"))

        if festivals then
            if festivals[1] ~= nil then
                local n = festivals[1]
                local diffTime, dd = calcTimeDiffToTarget(0, 0, 0, n['y'], n['m'], n['d'])
                lvgl.label_set_text(LTL_S1, colorText(n.name, "eeeeee"))
                lvgl.label_set_text(LTL_M1, colorText(dd, "cc0000"))
            end
        end

        if weather['now'] ~= nil then
            if (weather['now']['text'] ~= nil and weather['now']['temperature'] ~= nil) then
                lvgl.label_set_text(WEAT, colorText(weather['now']['text'], "ffffff") ..
                    colorText(" " .. weather['now']['temperature'] .. "℃", "ffffff"))
            else
                lvgl.label_set_text(WEAT, colorText("天气信息异常", "cc0000"))
                log.debug("weather", "weather data error", json.encode(weather['now']))
            end
        else
            lvgl.label_set_text(WEAT, colorText("正在获取天气信息", "eeeeee"))
        end
    end
end

function autoCreateLabelForm_MS(father, x, y, width, height, text, font_Size, align)
    if font_Size == nil then
        font_Size = 14
    end
    if width == nil then
        width = 100
    end
    if height == nil then
        height = 20
    end
    if text == nil then
        text = "00"
    end
    if x == nil then
        x = 0
    end
    if y == nil then
        y = 0
    end
    if align == nil then
        align = lvgl.LABEL_ALIGN_LEFT
    end
    if father == nil then
        father = mainscreen
    end
    local label = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(label, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[font_Size])
    lvgl.label_set_align(label, align)
    lvgl.label_set_long_mode(label, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.obj_set_size(label, width, height)
    lvgl.obj_set_pos(label, x, y)
    lvgl.label_set_recolor(label, true)
    lvgl.label_set_text(label, text)
    return label
end
