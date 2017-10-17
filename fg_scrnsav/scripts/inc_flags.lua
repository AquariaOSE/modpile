
---- control flags, for node/entity communication ----
FLAG_MOD_INITED = 420
FLAG_RELOAD_UI = 440 -- checked in logic_ui.lua

---- debug flags ----
FLAG_DBG_VISUALS = 491 -- display visual indicators for various things
FLAG_DBG = 492 -- allow cheating for debugging (opening doors and stuff). also prevents cutscenes from changing the map, etc etc.
FLAG_DBG_TOGGLE = 493 -- 0: ignore, 1: enable debug, 2: disable debug (auto-resets to 0)

---- screensaver specific ----
FLAG_MUTE_MUSIC = 400
FLAG_UI_VISIBLE = 401

function v.setNumFlag(flag, val)
    setStringFlag(flag, tostring(val))
end

function v.getNumFlag(flag)
    local val = tonumber(getStringFlag(flag))
    if not val then
        val = 0
    end
    return val
end

function v.isDebug()
    return getFlag(FLAG_DBG) ~= 0
end

function v.isDebugVis()
    return getFlag(FLAG_DBG_VISUALS) ~= 0
end

v._dbgVis = 0

function v.debugVis(x, y, tex, scale)
    if v._dbgVis ~= 0 then
        quad_delete(v._dbgVis)
        v._dbgVis = 0
    end
    
    if not v.isDebugVis() then
        return
    end
    
    if tex == true then
        tex = "yes"
    elseif tex == false then
        tex = "no"
    elseif not tex or tex == "" then
        tex = "missingimage"
    end
    local q = createQuad(tex)
    if scale then
        quad_scale(q, scale, scale)
    end
    
    quad_setPosition(q, x, y)
    v._dbgVis = q 
end

function v.nodeDebugVis(me, tex, scale)
    local x, y = node_getPosition(me)
    v.debugVis(x, y, tex, scale)
end

function v.entDebugVis(me, tex, scale)
    local x, y = entity_getPosition(me)
    v.debugVis(x, y, tex, scale)
end

function v.edbg(me, s, line)
    if v.isDebugVis() then
        local nl = ""
        if line then
            while line ~= 0 do
                nl = nl .. "\n"
                line = line - 1
            end
        end
        s = nl .. s
        entity_debugText(me, s)
        entity_debugText(me, s)
        -- twice, otherwise its too transparent
    end
end
