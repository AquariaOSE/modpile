--[[
logic_compat.lua

Compatibility related logic plugin.
Works with 1.1.1/2 and 1.1.3+, but not required in 1.1.3 or later.

This plugin autodetects nodes that should have a script,
but which can not be run because they have parameters.
(Assuming you have a "mytest" node with a script, this one will work fine.
But as soon as you add one or more parameters, as in "mytest abcd 1.5",
the pre-1.1.3 engines will fail to load it.)

It also enables loading of map_*.lua and premap_*.lua scripts when a new map is loaded.
Note that the order of processing map scripts is a bit different than if the engine does it.

Besides placing a "logic" node on all your maps and making sure that node_logic.lua
loads this script, there is nothing more to do.
]]


--if not AQUARIA_VERSION then


local function puts(s)
    debugLog("logic_compat: " .. s)
end

local function fmt(x)
    local t = type(x)
    if t == "nil" then
        return "<Nil>"
    elseif t == "function" then
        return "(function)"
    elseif t == "userdata" then
        return "(userdata)"
    elseif t == "table" then
        return "(table)"
    elseif x == true then
        return "true"
    elseif x == false then
        return "false"
    elseif t == "thread" then
        return "(thread)"
    elseif t == "number" or t == "string" then
        return tostring(x)
    end
    return t
end

local function dumptab(t, lvl, s)
    if type(t) ~= "table" then
        puts("dumptab: " .. fmt(t))
        return
    end
    s = s or ""
    lvl = lvl or 0
    for i, x in pairs(t) do
        debugLog(s .. fmt(i) .. " => " .. fmt(x))
        if lvl > 0 and type(x) == "table" then
            dumptab(x, lvl - 1, s .. "  ")
        end
    end
end


-- all interface functions used by the game.
-- some of these are not used at all, though.
local INTERFACE_FUNCS =
{
	action = true,
	activate = true,
	animationKey = true,
	castSong = true,
	damage = true,
	dieEaten = true,
	dieNormal = true,
	enterState = true,
	entityDied = true,
	exitState = true,
	exitTimer = true,
	hitEntity = true,
	hitSurface = true,
	init = true,
	lightFlare = true,
	msg = true,
	postInit = true,
	preUpdate = true,
	shiftWorlds = true,
	shotHitEntity = true,
	song = true,
	songNote = true,
	songNoteDone = true,
	sporesDropped = true,
	update = true,
	useTreasure = true,
}

-- returns the function and the table where this function is stored,
-- preference is on interface functions.
-- if no interface function is found, look in _G.
-- otherwise return nil and warn.
local function getInterfaceFunction(fname, env, scNameOverride)

    if not env then
        env = _G
    end
    
    -- 1.1.3+ compatible interface
    local tf = rawget(env, "_scriptfuncs")
    if tf then
        local localpath = "/scripts/" .. (scNameOverride or ("node_" .. node_getLabel(v.me))) .. ".lua" -- FIXME: what if v.me is not defined here?
        local n = v.getModPath() .. localpath
        local tab = tf[n]
        -- not found?
        if not tab then
            n = "./" .. n
            tab = tf[n]
            -- still not found? do a linear search and hope for the best
            if not tab then
                localpath = localpath:lower()
                for i, x in pairs(tf) do
                    if i:lower():endsWith(localpath) then
                        n = i
                        break
                    end
                end
                tab = tf[n]
            end
        end
        -- should have it now
        if tab then
            local f = tab[fname]
            if f then
                return f, tab
            end
        end
    end
    
    -- 1.1.1 has its interface functions in the global table
    local f = rawget(env, fname)
    if f then
        return f, env
    end
    
    puts("Interface function not found: " .. fname)
end

-- loads a script in another environment and returns that environment after populating it, or nil.
-- can't use dofile() here because it ignores setfenv().
-- - see also: http://lua-users.org/wiki/DofileNamespaceProposal
-- loadfile() is already patched by inc_compat.lua to support relative paths.
local function protectedLoad(fn, env)

    puts("Loading in protected env: " .. fn)
    local f,err = loadfile(fn)
    if not f then
        puts("-- ERROR: " .. err)
        return
    end
    
    -- TODO: Can be optimized here! Load the file only once, cache the function, and then call it repeatedly
    
    pcall(setfenv(f, env)) -- call it! (note that setfenv() returns the function it changed; which is what pcall() calls)
    
    return getfenv(f)
end

-- returns a table that is based on another table, as in redirecting reads to the original table
-- if not found. Writes will always go to the new table.
-- Defaults to _G if not set.
local function setupEnvironment(env)
    if not env then
        env = _G
    end
    
    -- copy script warnings, if enabled
    local newmeta = {}
    for i, x in pairs(getmetatable(env)) do
        newmeta[i] = x
    end
    
    -- prepare a new environment for the foreign script
    local cp = {}
    cp._G = env
    cp.v = {}
    
    -- ask the original global environment for values in case they are missing
    newmeta.__index = env
    setmetatable(cp, newmeta)
    
    return cp
end

-- returns a table with all script globals, or nil
local function tryLoad(nodename)
    puts("Loading script for node: " .. nodename)
    local fn = "scripts/node_" .. nodename .. ".luax" -- OMG FIXME <<<<--------------
    local env = setupEnvironment()
    return protectedLoad(fn, env)
end

local function setupNode(node)
    local nn = node_getName(node)
    puts("Preparing Node: " .. nn) 
    local env = tryLoad(node_getLabel(node))
    if not env then
        puts("Failed to capture Node: " .. nn)
        return nil
    end
    
    -- store foreign patched interface functions
    local funcs = {}
    for i, x in pairs(env) do
        if type(x) == "function" and INTERFACE_FUNCS[i] then
            funcs[i] = x
        end
    end
    
    -- the functions in INTERFACE will be called in their own context,
    -- because they were loaded in their own environment.
    env.INTERFACE = funcs
    
    -- sanity checks / debug
    puts("Captured Node: " .. node_getName(node))
    for i, x in pairs(env.INTERFACE) do
        local s = "success"
        if getfenv() == getfenv(x) then
            s = "FAIL" -- this should never appear
        end
        puts(" - " .. i .. " : " .. s)
    end
        
    return env
end


-- hooks a global or interface function by name
local function hookGlobalFunc(fname, hook)
    local parent
    local f, parent = getInterfaceFunction(fname)
    if f then
        if f == hook then return end
        rawset(parent, fname, function(...)
            hook(...)
            return f(...)
        end)
        return true
    end
    return false
end

local function doMapScript(prefix)
    local env = setupEnvironment()
    local scname = prefix .. "_" .. getMapName()
    local fn = "scripts/" .. scname .. ".luax" -- FIXME
    local sc = protectedLoad(fn, env)
    if sc then
        local initfunc = getInterfaceFunction("init", nil, scname)
        -- FIXME: not sure if this works -- THIS DOES NOT WORK YET
        if initfunc and type(initfunc) == "function" then
            local ok, err = pcall(initfunc)
            if not ok then
                puts("doMapScript [" .. fn .. "]: Error in init function: " .. err)
            end
        else
            puts("doMapScript [" .. fn .. "]: init does not exist or not a function")
        end
    else
        puts("doMapScript [" .. fn .. "]: File not found")
    end
end

------------------------------------------


local Compat = {}
local f_dummy = function() end

-- calls an interface function of one captured foreign node
local function performCall(node, env, fname, ...)
    local f = env.INTERFACE[fname]
    if f then
        local ok, err = pcall(f, node, ...)
        if not ok then
            puts("Error in node [" .. node_getName(node) .. "] in function [" .. fname .. "] : " .. err)
        end
    else
        puts("Warning: Node [" .. node_getName(node) .. "] does not export function: " .. fname)
        env.INTERFACE[fname] = f_dummy -- silence warnings
    end
end

-- calls an interface function of all captured foreign nodes
local function doInterfaceCall(fname, ...)
    for node, env in pairs(Compat.nodes) do
        performCall(node, env, fname, ...)
    end
end

-- registers interface function call forwarding;
-- if a hooked function is called, all captured nodes will have the same function
-- called in their own context, with the same parameters
local function forwardInterfaceCall(fname)
    hookGlobalFunc(fname, function(me, ...)
        -- "me" is this node (node_logic), and not the one in whose context the call should be performed.
        -- so we simply ignore it.
        doInterfaceCall(fname, ...)
    end)
end


Compat.init = function()
    local an = v.getAllNodes()
    Compat.nodes = {} -- maps all captured nodes: [node => environment]
    local broken = {} -- things that failed to load, where it can be assumed that trying to load it will fail again
    
    for _, n in pairs(an) do
        local label = node_getLabel(n)
        if not broken[label] then
            if node_getName(n):lower() ~= label then -- do we need to capture the node? yes if the node has parameters.
                local env = setupNode(n)
                if env then
                    Compat.nodes[n] = env
                else
                    broken[label] = true -- failed to load it once, assume the script is broken
                end
            else
                puts("Skipped Node: " .. node_getName(n))
            end
        end
    end
    
    doMapScript("premap")
    
    doInterfaceCall("init")
    
    -- because we don't know if other logic plugins use these functions,
    -- don't risk overwriting anything. Hook them instead.
    forwardInterfaceCall("song")
    forwardInterfaceCall("songNote")
    forwardInterfaceCall("songNoteDone")
    forwardInterfaceCall("action")
    forwardInterfaceCall("activate")
    
    doMapScript("map")
end

Compat.postInit = function()
end


Compat.update = function(dt)
    -- relocate to player, to be able to capture songs and the like
    node_setPosition(v.me, entity_x(v.n), entity_y(v.n))
    
    doInterfaceCall("update", dt)
end


v.logic.compat = Compat

--end
