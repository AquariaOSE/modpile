
local Debug = {} -- "class" def here!

local function dbgSetFlags(on)
    if on then on = 1 else on = 0 end
    
    setFlag(FLAG_DBG_VISUALS, on)
end

local function dbgCheckGlobalFlags()
    local err = ""
    local taken = {}
    for a, x in pairs(_G) do
        if type(x) == "number" and a:startsWith("FLAG_") then
            if taken[x] then
                if not (a:endsWith("START") or a:endsWith("_END") or taken[x]:endsWith("START") or taken[x]:endsWith("_END")) then
                    err = err .. "\nDbl def flag: " .. a .. " = " .. x .. " ( = " .. taken[x] .. ")"
                end
            else
                taken[x] = a
            end
        end
    end
    
    if #err > 0 then
        debugLog(err)
        centerText(err)
    end
end

Debug.init = function()

    
    if v.isDebug() then
        setControlHint("Debug mode active!", false, false, false, 1.5, "youngli/head")
        dbgSetFlags(true) -- be sure all debug is really enabled on debug maps
    else
        dbgSetFlags(false)
    end

end

Debug.postInit = function()

    dbgCheckGlobalFlags()
    
    debugLog("debug: Lua mem in use: " .. collectgarbage("count") .. " KB")
    

end
    

Debug.update = function(dt)
    if v.isDebug() then
		if entity_getHealthPerc(v.n) <= 0.4 then
			cureAllStatus()
			setControlHint("DEBUG Healing", 0, 0, 0, 1)
			entity_heal(v.n,3)
		end
    end
    
    local d = getFlag(FLAG_DBG_TOGGLE)
    if d == 1 then
        dbgSetFlags(true)
        setFlag(FLAG_DBG_TOGGLE, 0)
        setFlag(FLAG_DBG, 1) -- HACK
        setFlag(FLAG_RELOAD_UI, 1)
    elseif d == 2 then
        dbgSetFlags(false)
        setFlag(FLAG_DBG_TOGGLE, 0)
        setFlag(FLAG_DBG, 0) -- HACK
        setFlag(FLAG_RELOAD_UI, 1)
    end
    
end


--v.logic.debug = Debug
