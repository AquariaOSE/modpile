
dofile(appendUserDataPath("_mods/fg_scrnsav/scripts/inc_compat.lua"))
dofile("scripts/inc_maps.lua")
dofile("scripts/inc_flags.lua")

function init()

    if AQUARIA_VERSION then
        --setFlag(FLAG_DBG_TOGGLE, 1) -- TEMP
        loadMap(v.getRandomMap())
    else
        voice("naija_quitjabba")
        -- .. and that kicks us back to the title
    end
end
