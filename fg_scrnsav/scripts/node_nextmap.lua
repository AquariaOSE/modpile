
dofile(appendUserDataPath("_mods/fg_scrnsav/scripts/inc_compat.lua"))

dofile("scripts/inc_maps.lua")

v.on = true

function init(me)
end

function update(me, dt)
    if v.on and node_isEntityIn(me, getNaija()) then
        v.on = false
        local m = v.getRandomMap()
        debugLog("Next map: " .. m)
        loadMap(m)
    end
end

function songNote(me, note)
end

function songNoteDone(me, note, done)
end
