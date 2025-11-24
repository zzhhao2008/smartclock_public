function calendarBegin()
    ::startCal::
    lvgl.obj_clean(mainscreen)
    local chiMode = 0
    local showingYear = 0
    local showingMonth = 0
    local showingDay = 0
    local calendar = lvgl.calendar_create(mainscreen, nil);
    lvgl.obj_set_size(calendar, 320, 240);
    lvgl.obj_align(calendar, nil, lvgl.ALIGN_CENTER, 0, 0);
    lvgl.obj_set_event_cb(calendar, event_handler);

    -- Set today's date
    local today = lvgl.calendar_date_t()
    local time = getLocalTime()
    today.year = time.year;
    today.month = time.mon;
    today.day = time.day;
    showingDay = time.day
    showingMonth = time.mon
    showingYear = time.year

    lvgl.calendar_set_today_date(calendar, today);
    lvgl.calendar_set_showed_date(calendar, today);
    lvgl.obj_set_style_local_bg_color(calendar, lvgl.CALENDAR_PART_DATE, lvgl.STATE_CHECKED,
                lvgl.color_make(0xfb, 0x88, 0x5e));
    -- lvgl.calendar_set_month_names(calendar,{"一月","二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"})
    local highlighted_dates = {}
    if highlighteddays ~= nil then
        for k, v in pairs(highlighteddays) do
            local fday = lvgl.calendar_date_t()
            fday.year = v.y
            fday.month = v.m
            fday.day = v.d
            highlighted_dates[#highlighted_dates + 1] = fday
        end
    end
    if festivals ~= nil then
        for k, v in pairs(festivals) do
            local fday = lvgl.calendar_date_t()
            fday.year = v.y
            fday.month = v.m
            fday.day = v.d
            highlighted_dates[#highlighted_dates + 1] = fday
        end
    end
    lvgl.calendar_set_highlighted_dates(calendar, highlighted_dates, #highlighted_dates)
    ::keySolve::
    local res, keyid = sys.waitUntil("keyDown")
    if keyid == "X" then
        return
    elseif keyid == "A" then -- 切换到上一月
        showingMonth = showingMonth - 1
        if showingMonth < 1 then
            showingMonth = 12
            showingYear = showingYear - 1
        elseif showingMonth > 12 then
            showingMonth = 1
            showingYear = showingYear + 1
        end
        local sday = lvgl.calendar_date_t()
        sday.year = showingYear
        sday.month = showingMonth
        sday.day = showingDay
        lvgl.calendar_set_showed_date(calendar, sday)
    elseif keyid == "B" then -- 切换到下一月
        showingMonth = showingMonth + 1
        if showingMonth < 1 then
            showingMonth = 12
            showingYear = showingYear - 1
        elseif showingMonth > 12 then
            showingMonth = 1
            showingYear = showingYear + 1
        end
        local sday = lvgl.calendar_date_t()
        sday.year = showingYear
        sday.month = showingMonth
        sday.day = showingDay
        lvgl.calendar_set_showed_date(calendar, sday)
    elseif keyid == "O" then

    end
    goto keySolve
end
