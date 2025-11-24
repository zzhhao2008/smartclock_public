local rtos_bsp = rtos.bsp()

function onKey(id)
    if psCfg.mode == "lcdoff" then
        powersave(0)
        mcu.setClk(psCfg.clk)
        psCfg = {
            clk = mcu.getClk(),
            mode = "normal"
        }
        lcd.on()
        log.info("powersave", "normal","WAKE UP BY",id)
        return
    end
    log.info("key", id)
    sys.publish("key" .. id .. "On")
    sys.publish("keyDown", id)
end

gpio.debounce(11, 200, 0)
Key_A = gpio.setup(11, function()
    onKey("A")
end, nil, gpio.RISING)

gpio.debounce(12, 200, 0)
Key_B = gpio.setup(12, function()
    onKey("B")
end, nil, gpio.RISING)

gpio.debounce(38, 200, 0)
Key_X = gpio.setup(38, function()
    onKey("X")
end, nil, gpio.RISING)

gpio.debounce(47, 200, 0)
Key_O = gpio.setup(47, function()
    onKey("O")
end, nil, gpio.RISING)

function adc_usbin()
    adc.open(5)
    local usbV = adc.get(5)
    adc.close(5)
    return usbV * 4 / 1000
end

function adc_battery()
    adc.open(6)
    local batteryV = adc.get(6)
    adc.close(6)
    return batteryV * 4 / 1000
end

screenLi = 0

--[[function screenLight(light,f)
    if light==nil then
        light=0
    end
    screenLi=screenLi+light
    if screenLi>100 then
        screenLi=100
    elseif screenLi<0 then
        screenLi=0
    end
    if f~=nil then
        pwm.open(13,20000,screenLi)
    end
    -- 0-100映射到 5-20
    local tli = (screenLi)*15/100+5
    pwm.open(13,20000,tli)
end]]

powerKey = gpio.setup(48, 1)
BEEPKey = gpio.setup(9, 0)

-- spi_id,pin_reset,pin_dc,pin_cs,bl
function lcd_pin()
    return 2, 16, 15, 14, 13
    --[[
    if rtos_bsp == "AIR101" then
        return 0, pin.PB03, pin.PB01, pin.PB04, pin.PB00
    elseif rtos_bsp == "AIR103" then
        return 0, pin.PB03, pin.PB01, pin.PB04, pin.PB00
    elseif rtos_bsp == "AIR105" then
        return 5, pin.PC12, pin.PE08, pin.PC14, pin.PE09
    elseif rtos_bsp == "ESP32C3" then
        return 2, 10, 6, 7, 11
    elseif rtos_bsp == "ESP32S3" then
        return 2, 16, 15, 14, 13
    elseif rtos_bsp == "EC618" then
        return 0, 1, 10, 8, 18
    else
        log.info("main", rtos_bsp, "bsp not support")
        return
    end]]
end

local spi_id, pin_reset, pin_dc, pin_cs, bl = lcd_pin()

spi_lcd = spi.deviceSetup(spi_id, pin_cs, 0, 0, 8, 40 * 1000 * 1000, spi.MSB, 1, 0)

lcd.init("st7789", {
    port = "device",
    pin_dc = pin_dc,
    pin_pwr = bl,
    pin_rst = pin_reset,
    direction = 2,
    w = 320,
    h = 240,
    xoffset = 0,
    yoffset = 0
}, spi_lcd)

--lcd.invoff()

function BEEP(frec, volu, time)
    if (MUTE == 1) then
        return
    end
    if (frec == nil) then
        frec = 1000
    end
    if (volu == nil) then
        volu = 100
    end
    if (time == nil) then
        time = 300
    end
    pwm.open(9, frec, volu)

    sys.timerStart(function()
        pwm.close(9)
    end, time)
end

function powersave(flag, super)
    log.info("powersave", flag)
    if flag == 1 or flag == nil then
        if super ~= nil and netStatus==false then
            mcu.setClk(40)
            return
        end
        mcu.setClk(80)
    else
        mcu.setClk(240)
    end
    wlan.powerSave(wlan.PS_MIN_MODEM)
end

psCfg = {
    clk = 80,
    mode = "normal"
}
function poweroff()
    saveSysConfig_DB()
    log.info("poweroff!")
    lcd.close()
    powerKey(0)
    sys.wait(500)
    rtos.reboot()
end

function sleep()
    lcd.off()
    psCfg = {
        clk = mcu.getClk(),
        mode = "lcdoff"
    }
    powersave(1, 1)
    -- pm.request(pm.LIGHT)
    wlan.powerSave(wlan.PS_MAX_MODEM)
end

function delayPowerOff(d)
    log.debug("poweroff!", d)
    if d == nil then
        d = 5000
    end
    if d <= 1000 then
        d = 1000
    end
    playSound("warn");
    sys.timerStart(poweroff, d)
end

function cancelPowerOff()
    sys.timerStopAll(poweroff)
end

function addZero(str, num)
    -- log.info("addZreo",str)
    -- 判断是不是字符串
    str = str .. ""
    if num == nil then
        num = 2
    end
    while #str < num do
        str = "0" .. str
    end
    return str
end
