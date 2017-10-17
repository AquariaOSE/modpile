
local UI = {} -- "class" def here!

local STATE_CLICKED = 1337

UI.clicktimer = 0
UI.visible = false
UI.wasLMB = false
UI.showt = 0

UI.elemcount = 0

UI.audio = 0
UI.xx = 0

local function setElementValue(e, ev, val)
    entity_msg(e, ev)
    entity_msg(e, tostring(val))
end

local function addElement(tex, x, y, scale, a, callback, light)
    debugLog("add gui elem x: " .. x .. "  y: " .. y) 
    local e = createEntity("guielement")
    
    local f = function()
        setElementValue(e, "tex",   tex     )
        setElementValue(e, "x",     x       )
        setElementValue(e, "y",     y       )
        if scale then setElementValue(e, "scale", scale   ) end
        if a     then setElementValue(e, "a",     a       ) end
        if light then setElementValue(e, "light", light   ) end
        entity_msg(e, "initdone")
        --debugLog("-- gui element inited:" .. tex)
    end
    
    UI.elems[e] = callback
    table.insert(UI.deferredCalls, f)
    UI.elemcount = UI.elemcount + 1
    return e
end

local function showAll()
    UI.showt = 3
    if UI.visible then return end
    setFlag(FLAG_UI_VISIBLE, 1)
    
    debugLog("-showAll-")
    for e,_ in pairs(UI.elems) do
        entity_msg(e, "show")
    end
    UI.visible = true
    
    playSfx("urchin-hit")
end

local function hideAll()
    if not UI.visible then return end
    setFlag(FLAG_UI_VISIBLE, 0)
    
    debugLog("-hideAll-")
    for e,_ in pairs(UI.elems) do
        entity_msg(e, "hide")
    end
    UI.visible = false
    UI.showt = 0
    playSfx("popshell")
end


local function bTestCallback()
    hideAll()
    shakeCamera(30, 0.5)
    setFlag(FLAG_RELOAD_UI, 1)
end

local function bMusicCallback()
    local muted = getFlag(FLAG_MUTE_MUSIC)
    if muted == 0 then
        setFlag(FLAG_MUTE_MUSIC, 1)
        --fadeOutMusic(1)
        musicVolume(0, 1)
    else
        setFlag(FLAG_MUTE_MUSIC, 0)
        --updateMusic()
        musicVolume(1, 1)
    end
end

local function bToggleDebugCallback()
    if v.isDebug() then
        setFlag(FLAG_DBG_TOGGLE, 2) -- disable
        playSfx("denied")
    else
        setFlag(FLAG_DBG_TOGGLE, 1) -- enable
        playSfx("secret")
    end
    hideAll()
end

-- possibly called multiple times
UI.init = function()
    UI.elemcount = 0
    if UI.elems then
        for e,_ in pairs(UI.elems) do
            entity_delete(e)
        end
    end
    
    UI.elems = {}
    UI.deferredCalls = {}
    
    local light = 0.8
    
    local x = 335
    local y = 555
    
    UI.audio = addElement("gui/audio", x, y, 0.9, 1, bMusicCallback, light)
    UI.xx = addElement("missingimage", x, y, 0.9, 1, 0)
    x = x + 120
    
    addElement("exit", x, y, 1.2, 1, goToTitle, light)
    x = x + 70
    
    if v.logic.debug then
        local s = "ingredients/mushroom"
        if v.isDebug() then s = "ingredients/rainbow-mushroom" end
        addElement(s, x, y, 0.7, 1, bToggleDebugCallback, light)
        x = x + 70
    end
    
    if v.isDebug() then
        addElement("gui/wok-drop", x, y, 0.7, 1, bTestCallback, light)
        x = x + 70
    end
end

UI.postInit = function()
    --UI.cursor = getEntity("logichelp_cursorpos")
end

UI.update = function(dt)

    if getFlag(FLAG_RELOAD_UI) ~= 0 then
        UI.init()
        setFlag(FLAG_RELOAD_UI, 0)
    end
    
    if next(UI.elems) == nil or UI.elemcount <= 1 then -- HACK TEMPORARY
        return
    end

    if isLeftMouse() or isRightMouse() then
        showAll()
    end
    
    if UI.showt > 0 then
        UI.showt = UI.showt - dt
        if UI.showt <= 0 then
            hideAll()
        end
    end

    -- first-time init
    if UI.deferredCalls then
        for e,dc in pairs(UI.deferredCalls) do
            dc()
        end
        UI.deferredCalls = nil
        return
    end
    
    for e,cb in pairs(UI.elems) do
        if entity_isState(e, STATE_CLICKED) then
            entity_setState(e, STATE_IDLE)
            if cb ~= 0 then
                cb(e)
                break
            end
            --hideAll()
        end
    end
    
    -- HACK
    local a = 0
    if isFlag(FLAG_MUTE_MUSIC, 1) then
        a = entity_getAlpha(UI.audio)
    end
    entity_alpha(UI.xx, a)
end


v.logic.ui = UI
