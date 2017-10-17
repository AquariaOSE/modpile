-- node_logic - pushing the game engine to its limits

-- This is basically a plugin manager; a single node that loads a set of plugins,
-- each doing its own stuff.
-- If a plugin fails to load, an error message will show.

-- Exactly one (!) logic node must be placed in each map.

dofile(appendUserDataPath("_mods/fg_scrnsav/scripts/inc_compat.lua"))

dofile("scripts/inc_flags.lua")
dofile("scripts/inc_util.lua")
dofile("scripts/inc_timerqueue.lua")


v.needinit = true
v.n = 0
v.logic = 0
v._err = 0
v._errtimer = 0


local function loadLibs()
    --dofile("scripts/lib_datadumper.lua")
end

local function loadPlugin(p)
    local f = "scripts/logic_" .. p .. ".lua"
    local ok, err = pcall(dofile, f)
    if ok then
        return ""
    end
   
    debugLog("LOGIC: Error loading file: " .. f .. " -- ERROR follows:")
    debugLog(err)
    
    return err .. "\n\n"
end

local function loadPlugins()
    local err =
       loadPlugin("common")
    .. loadPlugin("debug")
    .. loadPlugin("ui")
    .. loadPlugin("screensaver")
    
    if #err > 0 then
        v._err = "=== LOGIC PLUGIN ERRORS: ===\n\n" .. err
    end
end

function init(me)
    v.logic = {}
    
    loadLibs()
    loadPlugins()

    v.cursor = createEntity("logichelp_cursorpos")

    for k, f in pairs(v.logic) do
        if f.init then
            f.init()
        end
    end
end

function update(me, dt)
    if v.needinit then
        v.needinit = false
        v.n = getNaija()
        for k, f in pairs(v.logic) do
            if f.postInit then
                f.postInit()
            end
        end
    end
    
    v.updateTQ(dt)
    
    for k, f in pairs(v.logic) do
        f.update(dt)
    end
    
    if v._err ~= 0 then
        if v._errtimer < dt then
            entity_debugText(getNaija(), v._err)
            v._errtimer = 0.5
        else
            v._errtimer = v._errtimer - dt
        end
    end
    
end

function songNote(me, note)
end

function songNoteDone(me, note, done)
end
