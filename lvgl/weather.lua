function startWeather()
    if not weather or not weather['now'] then
        log.warn("weather", "data missing")
        return
    end

    local scr = mainscreen
    lvgl.obj_set_style_local_bg_color(scr, lvgl.OBJ_PART_MAIN, lvgl.STATE_DEFAULT, lvgl.color_make(225, 235, 245))

    -- === 建议映射 ===
    local suggestionMap = {
        ["umbrella"] = "雨伞",
        ["dressing"] = "穿衣",
        ["comfort"] = "舒适度",
        ["flu"] = "感冒",
        ["sport"] = "运动",
        ["car_washing"] = "洗车",
        ["travel"] = "旅游",
        ["morning_sport"] = "晨练",
        ["air_pollution"] = "空气污染",
        ["uv"] = "紫外线",
        ["sunscreen"] = "防晒",
        ["traffic"] = "交通",
        ["road_condition"] = "路况",
        ["mood"] = "心情",
        ["fishing"] = "钓鱼",
        ["boating"] = "划船",
        ["kiteflying"] = "放风筝",
        ["airing"] = "晾晒",
        ["shopping"] = "购物",
        ["night_life"] = "夜生活",
        ["chill"] = "风寒",
        ["allergy"] = "过敏",
        ["ac"] = "空调"
    }

    -- === 构建建议列表（按 suggestionMap 顺序）===
    local suggestionList = {}
    local suggestionData = weather['suggestion'] or {}
    for k, _ in pairs(suggestionMap) do
        if suggestionData[k] then
            table.insert(suggestionList, {
                key = k,
                title = suggestionMap[k],
                brief = suggestionData[k]['brief'] or "",
                details = suggestionData[k]['details'] or ""
            })
        end
    end

    local totalPages = math.max(1, math.ceil(#suggestionList / 4)) -- 至少1页（天气页）
    local currentPage = 0

    ::RENDER_PAGE::
    lvgl.obj_clean(scr)

    if currentPage == 0 then
        -- ========== 第0页：天气首页 ==========
        local now = weather['now']
        local loc = weather['location']
        local daily = weather['daily']

        -- 今日图标
        local icon = lvgl.img_create(scr, nil)
        local code = now['code'] or "99"
        lvgl.img_set_src(icon, "/luadb/" .. code .. "@2x.png")
        --lvgl.obj_set_size(icon, 100, 100)
        lvgl.obj_align(icon, nil, lvgl.ALIGN_IN_TOP_LEFT, 15, 10)

        -- 当前温度（大字）
        autoCreateLabelForm_MS(scr, 130, 15, 180, 60, now['temperature'] .. "℃", 56)

        -- 天气现象
        local v = daily and daily[1] or {}
        local desc = (now['text'] or "") .. " " .. colorText(v['high'], "ff8800") .. colorText("/", "888888") ..
                         colorText(v['low'], "0088ff")
        autoCreateLabelForm_MS(scr, 130, 65, 180, 30, desc, 22)

        -- 今日详细信息（湿度、风、降雨）
        local today = daily and daily[1] or {}
        local humidity = today['humidity'] or "--"
        local wind = (today['wind_direction'] or "") ..
                         (tonumber(today['wind_scale']) > 0 and (today['wind_scale'] .. "级") or "")
        local rainfall = today['rainfall'] and string.format("%.1f", tonumber(today['rainfall'])) or "0.0"

        local detailText = colorText("湿度 " .. humidity .. "%", "555555") .. "  " ..
                               colorText("风 " .. wind, "555555") .. "  " ..
                               colorText("雨 " .. rainfall .. "mm", "555555")
        autoCreateLabelForm_MS(scr, 130, 95, 180, 20, detailText, 16)
        -- ===== 分割线 =====
        local line = lvgl.line_create(scr, nil)
        local line_points = {{5, 0}, {315, 0}} -- 水平线，从左到右
        lvgl.line_set_points(line, line_points, 2)
        lvgl.line_set_y_invert(line, false) -- y=0 在顶部（默认）
        -- 设置样式：细线、浅灰色
        local line_style = lvgl.style_t()
        lvgl.style_init(line_style)
        lvgl.style_set_line_width(line_style, lvgl.STATE_DEFAULT, 1)
        lvgl.style_set_line_color(line_style, lvgl.STATE_DEFAULT, lvgl.color_make(180, 180, 180)) -- #B4B4B4
        lvgl.style_set_line_rounded(line_style, lvgl.STATE_DEFAULT, false)
        lvgl.obj_add_style(line, lvgl.LINE_PART_MAIN, line_style)
        lvgl.obj_set_pos(line, 0, 123) -- 放在 Y=130 处
        lvgl.obj_set_size(line, 320, 1) -- 高度1px（实际由line_points决定，此处仅为占位）
        -- 未来两天（横排）
        if daily and #daily >= 3 then
            local startY = 135
            for i = 2, 3 do
                local v = daily[i]
                local x = (i - 2) * 160 + 2 -- 左/右半区

                -- 标题：明天 / 后天
                local dayLabel = (i == 2) and "明天" or "后天"
                dayLabel = colorText(dayLabel, "555555")
                autoCreateLabelForm_MS(scr, x + 10, startY, 150, 22, dayLabel, 16, lvgl.LABEL_ALIGN_LEFT)

                -- 小图标（使用 @1x = 50x50）
                local iconCode = v['code_day'] or v['code_night'] or "99"
                local smallIcon = lvgl.img_create(scr, nil)
                lvgl.img_set_src(smallIcon, "/luadb/" .. iconCode .. "@1x.png")
                lvgl.obj_set_pos(smallIcon, x + 5, startY + 25)

                -- 温度范围（带 ℃）
                local tempText = colorText(v['high'], "ff8800") .. colorText("/", "888888") ..
                                     colorText(v['low'], "0088ff") .. colorText("℃", "888888")
                autoCreateLabelForm_MS(scr, x + 63, startY + 28, 90, 28, tempText, 28)

                -- 天气描述（如“多云转晴”）
                local dayText = v['text_day'] or ""
                local nightText = v['text_night'] or ""
                local textDesc = (dayText == nightText) and dayText or (dayText .. "转" .. nightText)
                --判断是否有雨
                if v['rainfall_day'] and tonumber(v['rainfall_day']) > 0 then
                    textDesc = textDesc .. " " .. colorText("有雨", "ff8800")
                end
                autoCreateLabelForm_MS(scr, x + 63, startY + 60, 85, 25, textDesc, 16)
            end
        end

    else
        -- ========== 生活建议页（横向多列布局） ==========
        local colCount = 3 -- 可改为 3 或 4 列
        local colWidth = math.floor(320 / colCount)
        local rowHeight = 60 -- 每项高度（标题20 + brief20 + details20）

        -- 清屏
        lvgl.obj_clean(scr)

        -- 计算当前页应显示的起始索引（每页最多 colCount * 3 项）
        local itemsPerPage = colCount
        local startIdx = (currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, #suggestionList)

        for i = startIdx, endIdx do
            local item = suggestionList[i]
            local idxInPage = i - startIdx -- 从0开始
            local col = idxInPage % colCount

            local x = col * colWidth + 5
            local y = 5

            -- 标题（如“穿衣”）
            autoCreateLabelForm_MS(scr, x, y, colWidth - 10, 30, item.title, 22, lvgl.LABEL_ALIGN_CENTER)

            -- Brief（如“较冷”）
            autoCreateLabelForm_MS(scr, x, y + 30, colWidth - 10, 30, item.brief, 16, lvgl.LABEL_ALIGN_CENTER)

            -- 将其中的中文字符转换为英文
            item.details = item.details:gsub("，", ",")
            item.details = item.details:gsub("、", " ")
            item.details = item.details:gsub("。", ".")

            -- Details（自动换行）
            local detailLabel = lvgl.label_create(scr, nil)
            lvgl.label_set_long_mode(detailLabel, lvgl.LABEL_LONG_BREAK)
            lvgl.label_set_align(detailLabel, lvgl.LABEL_ALIGN_CENTER)
            lvgl.label_set_recolor(detailLabel, true)
            lvgl.obj_set_size(detailLabel, colWidth - 10, 165)
            lvgl.obj_set_pos(detailLabel, x, y + 65)
            lvgl.label_set_text(detailLabel, item.details)

            lvgl.obj_set_style_local_text_font(detailLabel, lvgl.LABEL_PART_MAIN, lvgl.STATE_DEFAULT, fontlist[16])
            -- ===== 添加分割线（在每项底部）=====
            -- 只在最后一行（即每页最后一行）不加线，避免超出屏幕（可选）
            -- 此处简单实现：每个项都加线，长度 = colWidth - 10
            local line = lvgl.line_create(scr, nil)
            local line_points = {{0, 0}, {colWidth - 10, 0}}
            lvgl.line_set_points(line, line_points, 2)
            -- 样式
            local line_style = lvgl.style_t()
            lvgl.style_init(line_style)
            lvgl.style_set_line_width(line_style, lvgl.STATE_DEFAULT, 1)
            lvgl.style_set_line_color(line_style, lvgl.STATE_DEFAULT, lvgl.color_make(200, 200, 200))
            lvgl.obj_add_style(line, lvgl.LINE_PART_MAIN, line_style)
            -- 放置在线条底部（y + rowHeight - 2）
            lvgl.obj_set_pos(line, x, y + rowHeight - 2)
            lvgl.obj_set_size(line, colWidth - 10, 1)
        end
    end

    -- ========== 按键处理 ==========
    while true do
        local _, key = sys.waitUntil("keyDown")
        if key == "X" then
            return
        elseif key == "B" then
            currentPage = currentPage + 1
            if currentPage > totalPages then
                currentPage = totalPages
            end
            goto RENDER_PAGE
        elseif key == "A" then
            currentPage = currentPage - 1
            if currentPage < 0 then
                currentPage = 0
            end
            goto RENDER_PAGE
        end
    end
end
