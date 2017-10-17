

debugLog("- COMPAT = " .. getStringFlag("COMPAT"))
dofile(getStringFlag("COMPAT"))

v.t = 0
v.txt = 0

function init(me)
    local a = node_getContent(me)
    if a ~= "" then
        v.txt = a
    else
        v.txt = "No param test works!"
    end
end

function update(me, dt)
    if v.t >= 0 then
        v.t = v.t - dt
        if v.t <= 0 then
            v.t = 1
            entity_debugText(getNaija(), v.txt)
        end
    end
end

function songNote(me, note)
end

function songNoteDone(me, note, done)
end

function action(me)
end

rawset(_G, "penis", function() return 0 end)
