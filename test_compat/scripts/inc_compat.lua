
--[[

inc_compat.lua

Enables partial upwards compatibility for 1.1.1/2 to 1.1.3+,
and experimental backwards compatibility for mods made for 1.1.1/2, so that they can run with 1.1.3+.

To use this file, add the following line to your mod-init.lua:
     dofile(appendUserDataPath("_mods/YOURMODHERE/scripts/inc_compat.lua"))
     
Then, simply add the following line above each script:
     dofile(getStringFlag("COMPAT"))
     
For maximum compatibility, place a "logic" node in each map.
This will allow calling scripts for nodes, even if they have parameters.
(The old versions mess this up and fail to run scripts on nodes with parameters.)

Optionally, put the following BEFORE including this file, to enable certain features:
                                                         
  setStringFlag("COMPAT_SCRIPTDIR", "oldscripts")    --  specify a secondary script directory next to the original "scripts" dir;
                                                         if this is used, all scripts in this dir will be loaded and managed
                                                         by the compatibility layer, and not the engine itself.
                                                         
  setStringFlag("COMPAT_OLDMODS", "2")               --  to allow running old mods with 1.1.3+ which are not aware
     (This setting is ignored in < 1.1.3)                of the single Lua state introduced in 1.1.3. Possible values:
                                                         "1" == enable for all scripts which include this file.
                                                         "2" == enable for all scripts in the secondary script dir.
                                                         




WARNING: Massive hackery. This overrides global functions the game uses.


-- API changes performed by this file: --


- dofile() supports relative paths now.
- loadfile() supports relative paths as well, but is CASE SENSITIVE !! (impossible to fix this properly, sorry)
- added node_getLabel(node), which returns the name of a node without additional params
- fixed node_getContent(node), it returns the first parameter as a string, now also for non-internal node types
- fixed node_getAmount(node), it returns the second parameter as a number, now also for non-internal node types

- TODO: 
-- override *_getNearestNode() (scan by label not full name!)
-- override createEntity() - needs script properly set if in old dir
-- override entity_color() pingpong using TQ, and override if pingpong was disturbed by another call to it.
-- override .....

  
  
- additionally, this file includes inc_util.lua, with additional functions the API does not have, but which i found very useful.

]]


-- It works for versions >= 1.1.3, but it does horrible things to the single Lua state. It WORKS, however.
-- But we make sure this is only loaded in versions below that, where it's needed.
if not v then v = {} end

if not rawget(v, "__compat_included") then -- include guard
v.__compat_included = true


local function getModPath()

    local modpath = getStringFlag("TEMP_modpath") -- variables starting with "TEMP_" are never saved, when saving the game
    if modpath ~= "" then
        return modpath
    end
    
    if not string.explode then
        ------------------------------------------------------
        -- super simple variant - inc_util.lua contains a slightly better implementation
        -- that will be loaded soon after.
        function string.explode(p, d)
          local t, ll, l
          ll = 0
          t = {}
          if(#p == 1) then return {p} end
            while true do
              l=string.find(p,d,ll,true) -- find the next d in the string
              if l~=nil then -- if "not not" found then..
                table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
                ll=l+1 -- save just after where we found it for searching next time.
              else
                table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
                break -- Break at end, as it should be, according to the lua manual.
              end
            end
          return t
        end

        function string.startsWith(String,Start)
           return string.sub(String,1,string.len(Start))==Start
        end
        
    end
    -----------------------------------------------------------
    
    local _, e = pcall(function() local a = 0 a() end) -- this will always raise an error; e will hold the error message
    
    -- HACK: parse the error message to figure out the mod's path

    
    -- e = "_mods/xyz/mod-init.lua:26: attempt to call local 'a' (a number value)"
    e = e:explode(":")[1]
    -- e = "_mods/xyz/mod-init.lua"
    e = e:explode("/")
    
    local i = 1
    while true do
        if not e[i] then centerText("inc_compat.lua: failed to parse mod path") break end -- nothing we can do, should not happen
        if e[i]:lower() == "_mods" then break end
        i = i + 1
    end
    e = table.concat(e, "/", 1, i+1)
    -- e = "_mods/xyz"
    -- or possibly: e = "[string "_mods/xyz"
    if e:lower():startsWith("[string \"") then
        e = e:explode("\"")
        e = table.concat(e, "", 2) -- skip first part ([string ")
    end
    
    -- skip "./"  -- eh what?
    if e:startsWith("./") then
        e = e:sub(3)
    end
    
    debugLog("detected mod path: " .. e)
    
    modpath = e
    setStringFlag("TEMP_modpath", modpath)
    return modpath
end

local function overrideGlobalAccess()
    local function looksLikeGlobal(s)
        local A = string.byte("A")
        local Z = string.byte("Z")
        local N0 = string.byte("0")
        local N9 = string.byte("9")
        local u = string.byte("_")
        local c 
        for i = 1, #s do
            c = s:byte(i)
            -- accept any uppercase, number, and _ char
            if not ((c >= A and c <= Z) or c == u or (c >= N0 and c <= N9)) then
                return false
            end
        end
        return true
    end
    
    local meta = getmetatable(_G)
    if not meta then
        meta = {}
        setmetatable(_G, meta)
    end
    
    -- if key not found, try looking in v table
    meta.__index = v
        
    -- redirect writes from the global table to the v table,
    -- unless a variable looks like a global - in that case write to both, just in case.
    meta.__newindex = function(t, k, val)
        if looksLikeGlobal(k) then
            rawset(t, k, val)
        end
        v[k] = val
    end
end

if AQUARIA_VERSION then
    -- assume dofile() supports relative paths
    setStringFlag("COMPAT", "scripts/inc_compat.lua")
    dofile("scripts/inc_util.lua")
    
    -- experimental: attempt to allow running old mods that are not aware
    -- of the single Lua state, if configured to do so.
    if getStringFlag("COMPAT_OLDMODS") == "1" then
        overrideGlobalAccess()
    end
else
    if not TILE_SIZE then -- this is directly in the engine as of 1.1.3, or defined in the file below, for prev. versions
        dofile("scripts/entities/entityinclude.lua")
    end

    local modpath = getModPath()
    setStringFlag("COMPAT", modpath + "/scripts/inc_compat.lua")
    
    -- guard against recursively overriding dofile() with replacement version
    if not rawget(_G, "o_dofile") then
    
        rawset(_G, "o_dofile", dofile)
    
        -- dofile that supports relative paths
        -- try to load specified file, otherwise append current mod path to it
        -- this is not 100% safe, though, as syntax errors in the first attempt will always trigger a 2nd load attempt.
        dofile = function(file)
            debugLog("dofile override: trying [" .. file .. "]")
            local ok, ret = pcall(o_dofile, file)
            if not ok then
                --local mp = getStringFlag("TEMP_modpath")
                local mp = modpath
                local path = mp .. "/" .. file
                debugLog("... trying [" .. path .. "]")
                ret = o_dofile(path)
            end
            return ret
        end
    end
    
    dofile("scripts/inc_util.lua")
    
    -- this function is new, and does not exist in < 1.1.3. Returns the node name without additional params.
    node_getLabel = function(me)
        local a = node_getName(me):lower():explode(" ", true)
        return a[1] or ""
    end

    node_getContent = function(me)
        local a = node_getName(me):lower():explode(" ", true)
        return a[2] or ""
    end
    
    node_getAmount = function(me)
        local a = node_getName(me):explode(" ", true)
        a = tonumber(a[3] or 0)
        return a or 0
    end
    
end -- end < 1.1.3 specific


-- this is b0rked for all versions so far !

if not rawget(_G, "o_loadfile") then

    rawset(_G, "o_loadfile", loadfile)

    -- loadfile that supports relative paths - but is NOT case insensitive !!
    loadfile = function(file)
        if file == "" then return nil end
        debugLog("loadfile override: trying [" .. file .. "]")
        local f, _ = o_loadfile(file)
        
        if f then
            debugLog("... sucess! [f = " .. type(f) .. "]")
            return f
        end
        
        local mp = getModPath()
        local path = mp .. "/" .. file
        debugLog("... trying [" .. path .. "]")
        return o_loadfile(path)
    end
end


-- export
v.getModPath = getModPath
v.overrideGlobalAccess = overrideGlobalAccess

    

end -- end include guard
