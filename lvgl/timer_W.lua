function startTimer()
    mainTimer()
end

function mainTimer()
    lvgl.obj_clean(mainscreen)

    -- 顶部状态栏（电池 + 系统时间）
    batLabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(batLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[16])
    lvgl.label_set_align(batLabel, lvgl.LABEL_ALIGN_RIGHT)
    lvgl.label_set_long_mode(batLabel, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.obj_set_size(batLabel, 100, 30)
    lvgl.obj_set_pos(batLabel, 220, 0)
    lvgl.label_set_recolor(batLabel, true)
    lvgl.label_set_text(batLabel, "#ffffff #")

    local topClockLabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(topClockLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[16])
    lvgl.label_set_align(topClockLabel, lvgl.LABEL_ALIGN_LEFT)
    lvgl.label_set_long_mode(topClockLabel, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.obj_set_size(topClockLabel, 160, 30)
    lvgl.obj_set_pos(topClockLabel, 0, 0)
    lvgl.label_set_recolor(topClockLabel, true)
    lvgl.label_set_text(topClockLabel, "#ffffff 00:00#")

    -- 背景初始化为黑色
    lvgl.obj_set_style_local_bg_color(mainscreen, lvgl.OBJ_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_hex(0x000000))

    -- 主时间显示（大字体）
    local timeLabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(timeLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[56])
    lvgl.label_set_align(timeLabel, lvgl.LABEL_ALIGN_CENTER)
    lvgl.label_set_long_mode(timeLabel, lvgl.LABEL_LONG_SROLL_CIRC) -- 防止溢出
    lvgl.obj_set_width(timeLabel, 320)
    lvgl.label_set_recolor(timeLabel, true)
    -- 垂直居中：主时间稍微靠上
    lvgl.obj_align(timeLabel, nil, lvgl.ALIGN_CENTER, 0, -20)

    -- 总时长 / 状态提示
    local totalLabel = lvgl.label_create(mainscreen, nil)
    lvgl.obj_set_style_local_text_font(totalLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[16])
    lvgl.label_set_align(totalLabel, lvgl.LABEL_ALIGN_CENTER)
    lvgl.label_set_long_mode(totalLabel, lvgl.LABEL_LONG_SROLL_CIRC)
    lvgl.label_set_recolor(totalLabel, true)
    lvgl.obj_set_width(totalLabel, 320)
    lvgl.label_set_text(totalLabel, "")
    -- 状态提示在主时间下方，整体视觉居中
    lvgl.obj_align(totalLabel, nil, lvgl.ALIGN_CENTER, 0, 30)

    -- === 状态变量 ===
    local mode = "setting" -- "setting", "counting", "finished"
    local cursor = 1 -- 1=hour, 2=min, 3=sec
    local setTime = {
        h = 0,
        m = 0,
        s = 0
    }
    local displayTime = {
        h = 0,
        m = 0,
        s = 0
    } -- 用于显示的时间（倒计时或正计时）
    local totalStr = ""
    local paused = false
    local doubleX = false
    local isCountdown = false -- true=倒计时，false=正计时（从0累加）

    -- === 辅助函数 ===
    local function formatTime(t)
        return string.format("%02d:%02d:%02d", t.h, t.m, t.s)
    end

    local function getColorText(text, color)
        return "#" .. color .. " " .. text .. "#"
    end

    local function setColor(colorHex)
        lvgl.obj_set_style_local_bg_color(mainscreen, lvgl.OBJ_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_hex(colorHex))
    end

    local function getStateText()
        if mode == "setting" then
            return "#ffffff 设置中,使用AB键加减时间,XO键移动光标(红色)#"
        elseif mode == "counting" then
            if paused then
                return "#00aaff 已暂停#"
            elseif isCountdown then
                return "#ffaa00 倒计时#"
            else
                return "#00ffaa 正计时#"
            end
        else
            return "#ff0000 结束#"
        end
    end

    local function updateDisplay()
        if mode == "setting" then
            local h = setTime.h
            local m = setTime.m
            local s = setTime.s
            local texts = {getColorText(string.format("%02d", h), cursor == 1 and "ff0000" or "ffffff"), ":",
                           getColorText(string.format("%02d", m), cursor == 2 and "ff0000" or "ffffff"), ":",
                           getColorText(string.format("%02d", s), cursor == 3 and "ff0000" or "ffffff")}
            lvgl.label_set_text(timeLabel, table.concat(texts, ""))
            lvgl.label_set_text(totalLabel, getStateText())
        elseif mode == "counting" then
            local tStr = formatTime(displayTime)
            lvgl.label_set_text(timeLabel, getColorText(tStr, "ffffff"))
            if isCountdown then
                lvgl.label_set_text(totalLabel, "#cccccc 总时长: " .. totalStr .. "# | " .. getStateText())
            else
                lvgl.label_set_text(totalLabel, getStateText())
            end
        elseif mode == "finished" then
            lvgl.label_set_text(timeLabel, getColorText("00:00:00", "ffffff"))
            lvgl.label_set_text(totalLabel, "#ff0000 计时结束#")
        end

        -- 更新顶部系统时间（始终显示）
        local h, m, s = formatedHourMinSec()
        lvgl.label_set_text(topClockLabel, "#ffffff " .. h .. ":" .. m .. ":" .. s .. "#")
    end

    -- === 主循环 ===
    while true do
        updateDisplay()

        local res, key = sys.waitUntil("keyDown", 1000)

        -- === 每秒自动更新逻辑 ===
        if mode == "counting" and not paused then
            if isCountdown then
                -- 倒计时：每秒减1
                if displayTime.h == 0 and displayTime.m == 0 and displayTime.s == 0 then
                    mode = "finished"
                    setColor(0xff0000)
                    -- 进入结束状态，不再自动重置！
                else
                    if displayTime.s > 0 then
                        displayTime.s = displayTime.s - 1
                    elseif displayTime.m > 0 then
                        displayTime.m = displayTime.m - 1
                        displayTime.s = 59
                    elseif displayTime.h > 0 then
                        displayTime.h = displayTime.h - 1
                        displayTime.m = 59
                        displayTime.s = 59
                    end
                end
            else
                -- 正计时：从 0 开始累加
                displayTime.s = displayTime.s + 1
                if displayTime.s >= 60 then
                    displayTime.s = 0
                    displayTime.m = displayTime.m + 1
                    if displayTime.m >= 60 then
                        displayTime.m = 0
                        displayTime.h = displayTime.h + 1
                        -- 可选：限制最大 23:59:59，或继续累加
                        if displayTime.h >= 100 then
                            displayTime.h = 99
                        end
                    end
                end
            end
        end

        -- === 按键处理 ===
        if mode == "finished" then
            -- 在 finished 状态，任何按键（包括超时后的按键）都要处理
            if not res then
                goto continue_loop
            end
            if key == "X" then
                return
            else
                -- 重置回设置状态
                mode = "setting"
                setTime = {
                    h = 0,
                    m = 0,
                    s = 0
                }
                cursor = 1
                setColor(0x000000)
            end
        elseif not res then
            -- 无按键，且不在 finished 状态，继续循环
            goto continue_loop
        end

        -- --- 非 finished 状态的按键处理 ---
        if mode == "setting" then
            if key == "A" then
                local fields = {"h", "m", "s"}
                local field = fields[cursor]
                setTime[field] = setTime[field] + 1
                if field == "h" then
                    setTime.h = setTime.h % 24
                else
                    setTime[field] = setTime[field] % 60
                end
            elseif key == "B" then
                local fields = {"h", "m", "s"}
                local field = fields[cursor]
                setTime[field] = setTime[field] - 1
                if setTime[field] < 0 then
                    if field == "h" then
                        setTime.h = 23
                    else
                        setTime[field] = 59
                    end
                end
            elseif key == "X" then
                if cursor == 1 then
                    return
                else
                    cursor = cursor - 1
                end
            elseif key == "O" then
                if cursor == 3 then
                    -- 启动计时
                    if setTime.h == 0 and setTime.m == 0 and setTime.s == 0 then
                        -- 正计时（从0开始）
                        isCountdown = false
                        displayTime = {
                            h = 0,
                            m = 0,
                            s = 0
                        }
                    else
                        -- 倒计时
                        isCountdown = true
                        displayTime = {
                            h = setTime.h,
                            m = setTime.m,
                            s = setTime.s
                        }
                        totalStr = formatTime(setTime)
                    end
                    mode = "counting"
                    paused = false
                    setColor(0x00aa00)
                    sys.timerStart(function()
                        setColor(0x000000)
                    end, 2000)
                else
                    cursor = cursor + 1
                end
            end

        elseif mode == "counting" then
            if key == "O" then
                paused = not paused
                if paused then
                    setColor(0x0000aa)
                else
                    setColor(0x00aa00)
                    sys.timerStart(function()
                        setColor(0x000000)
                    end, 2000)
                end
            elseif key == "X" then
                if doubleX then
                    return
                else
                    doubleX = true
                    sys.timerStart(function()
                        doubleX = false
                    end, 1000)
                end
            end
        end

        ::continue_loop::
    end
end
