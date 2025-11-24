local Sounds = {
    -- 开机自检音效：模拟大疆无人机经典的“滴-滴-滴滴”开机自检声
    start = {{600, 150}, -- 第一声短促低音
    {800, 150}, -- 第二声稍高
    {1000, 300} -- 第三声高音短促
    },

    -- 普通提示音
    beep = {{2000, 100}},

    -- 错误提示音：急促重复的警示音
    err = {{300, 100}, {200, 100} -- 低频警示
    },

    -- 闹钟音效 1：经典渐强闹铃
    alarm1 = {{800, 200}, {1000, 200}, {800, 200}, {1000, 200}, {800, 200}, {1000, 200}},

    -- 闹钟音效 2：柔和唤醒铃声
    alarm2 = {{500, 300}, {600, 300}, {700, 300}, {500, 300}, {600, 300}, {700, 300}},

    -- 闹钟音效 3：急促提醒铃声（适合重要提醒）
    alarm3 = {{1200, 100}, {1400, 100}, {1200, 100}, {1400, 100}, {1200, 100}, {1400, 100}, {1200, 100}, {1400, 100}},

    -- 闹钟音效 4：舒缓旋律（模拟简单音乐片段）
    alarm4 = {{523, 250}, -- C5
    {587, 250}, -- D5
    {659, 250}, -- E5
    {698, 250}, -- F5
    {784, 250}, -- G5
    {880, 250}, -- A5
    {988, 250}, -- B5
    {1047, 250} -- C6
    }
}

vol = 50
MUTE = 0

SoundQUEUE = {}

function playSound(name)
    table.insert(SoundQUEUE, name)
    sys.publish("SOUNDADDED")
end

function setVol(newvol)
    vol = newvol
    if (vol < 0) then
        vol = 0
    elseif (vol > 100) then
        vol = 100
    end
    sys.publish("Seted Vol", vol)
end

function setMute(newMute)
    log.info("setMute", newMute)
    if newMute == 1 then
        MUTE = 1
        BEEPKey(0)
    else
        MUTE = 0
    end
end

sys.taskInit(function()
    while true do
        ::wait::
        sys.waitUntil("SOUNDADDED")
        ::endofQ::
        if (#SoundQUEUE == 0) then
            goto wait
        end
        local name = SoundQUEUE[1]
        sys.publish("Playing Sound", name)
        log.info("playingSound", name)
        if MUTE == 1 then
            log.info("MUTED", name)
            goto endofPS
        end
        if Sounds[name] ~= nil then
            for i, v in ipairs(Sounds[name]) do
                BEEP(v[1], vol, v[2])
                sys.wait(v[2])
            end
        end
        ::endofPS::
        sys.publish("Sound Played", name)
        log.info("Sound Played", name)
        table.remove(SoundQUEUE, 1)
        if (#SoundQUEUE > 0) then
            sys.wait(300)
            goto endofQ
        end
    end
end)
