
-- note: include this file only in an init() function or somethin, not at file scope!

v._maps =
{
    "energytemple01",
    "energytemple03",
    "jailveiltunnel",
    "o.mainarea",
    "o.songcave",
    "o.trainingcave",
    "river02",
}

v._freeMaps = false

function v.getRandomMap()

    if not v._freeMaps then
        local s = getStringFlag("TEMP_freemaps")
        if #s > 0 then
            v._freeMaps = s:explode(" ", true)
        end
    end
    
    if not v._freeMaps or #(v._freeMaps) == 0 then
        v._freeMaps = table.deepcopy(v._maps)
    end
    
    local r = math.random(#v._freeMaps)
    local m = table.remove(v._freeMaps, r)
    
    setStringFlag("TEMP_freemaps", table.concat(v._freeMaps, " "))
    
    return m
end
