
dofile(appendUserDataPath("_mods/fg_scrnsav/scripts/inc_compat.lua"))


v.wasin = false
v.txt = ""

function init(me)
    v.txt = node_getContent(me)
    debugLog("gonode: " .. v.txt)
end

function update(me, dt)
    local ins = node_isEntityIn(me, getNaija())
    if ins and not v.wasin then
        debugLog("gonode: " .. v.txt)
        local node = node_getNearestNode(me, v.txt)
        if node ~= 0 then
            entity_swimToNode(getNaija(), node)
        else
            debugLog("gonode: ... NOT FOUND")
        end
    end
    v.wasin = ins
end

function songNote(me, note)
end

function songNoteDone(me, note, done)
end
