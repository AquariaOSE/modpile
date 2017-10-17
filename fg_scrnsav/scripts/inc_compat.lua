
-- contains replacement functions for versions below 1.1.3
-- include [dofile()] this file before including anything else.
-- WARNING: Massive hackery. This overrides global functions the game uses.

-- API changes performed by this file: --
--[[

- dofile() supports relative paths now.
  Note that to include this file in versions < 1.1.3, you still need to use an absolute path.
  In each script, after this file was included, this is no longer necessary and relative paths can be used.
- added node_getLabel(node), which returns the name of a node without additional params
- fixed node_getContent(node), it returns the first parameter as a string, now also for non-internal node types
- fixed node_getAmount(node), it returns the second parameter as a number, now also for non-internal node types

  
  
- additionally, this file includes inc_util.lua, with additional functions the API does not have, but which i found very useful.

]]


-- It works for versions >= 1.1.3, but it does horrible things to the single Lua state. It WORKS, however.
-- But we make sure this is only loaded in versions below that, where it's needed.
if not v then v = {} end
if AQUARIA_VERSION then
    dofile("scripts/inc_util.lua") -- assume dofile() supports relative paths
else
    if not TILE_SIZE then -- this is directly in the engine as of 1.1.3, or defined in the file below, for prev. versions
        dofile("scripts/entities/entityinclude.lua")
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

    local modpath = getStringFlag("TEMP_modpath") -- variables starting with "TEMP_" are never saved, when saving the game
    if not modpath or modpath == "" then
        local _, e = pcall(function() local a = 0 a() end) -- this will always raise an error; e will hold the error message
        
        -- HACK: parse the error message to figure out the mod's path
        
        -- e = "_mods/xyz/mod-init.lua:26: attempt to call local 'a' (a number value)"
        e = e:explode(":")[1]
        -- e = "_mods/xyz/mod-init.lua"
        e = e:explode("/")
        e = e[1] .. "/" .. e[2]
        -- e = "_mods/xyz"
        -- or possibly: e = "[string "_mods/xyz"
        if e:lower():startsWith("[string \"") then
            e = e:explode("\"")
            e = table.concat(e, "", 2) -- skip first part ([string ")
        end
        
        debugLog("detected mod path: " .. e)
        
        modpath = e
        setStringFlag("TEMP_modpath", modpath)
    end
    
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
        local a = node_getName(me):explode(" ", true)
        return a[1] or ""
    end

    node_getContent = function(me)
        local a = node_getName(me):explode(" ", true)
        local r = a[2] or ""
        debugLog("--- node_getContent override: " .. r)
        return r
    end
    
    node_getAmount = function(me)
        local a = node_getName(me):explode(" ", true)
        a = tonumber(a[3] or 0)
        return a or 0
    end
    
end
