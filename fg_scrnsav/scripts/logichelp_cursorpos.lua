
dofile(appendUserDataPath("_mods/fg_scrnsav/scripts/inc_compat.lua"))
dofile("scripts/inc_flags.lua")


function init(me)
	setupEntity(me)
	entity_setEntityType(me, ET_NEUTRAL) -- by making the entity neutral, normal shots won't target this
    
    entity_setTexture(me, "missingimage")
    
    if getFlag(FLAG_DBG_VISUALS) == 0 then
        entity_alpha(me, 0.001) -- setting this to 0.0 makes shots unable to follow it.
    end
    
    esetv(me, EV_LOOKAT, false)
	
	entity_setAllDamageTargets(me, false)
    entity_setUpdateCull(me, -1)
    
    entity_setDamageTarget(me, DT_AVATAR_ENERGYBLAST, true) -- however, its still a valid target for manually spawned shots
    entity_setDamageTarget(me, DT_AVATAR_SHOCK, true)
	
	entity_setCollideRadius(me, 1)
	
	entity_setCanLeaveWater(me, true)
end



function postInit(me)
end

function update(me, dt)
    entity_setPosition(me, getMouseWorldPos())
end

function enterState(me)
end

function exitState(me)
end

function msg(me, msg)
end

function damage(me, attacker, bone, damageType, dmg)
	return false
end

function animationKey(me, key)
end

function hitSurface(me)
end

function songNote(me, note)
end

function songNoteDone(me, note)
end

function song(me, song)
end

function activate(me)
end

