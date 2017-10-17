
dofile(appendUserDataPath("_mods/fg_scrnsav/scripts/inc_compat.lua"))
dofile("scripts/inc_flags.lua")


v.lock = true

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
	
	entity_setCanLeaveWater(me, true)
    
    --cam_toEntity(me)
    
    
    debugLog("cam created")
end



function postInit(me)
    v.n = getNaija()
end

function update(me, dt)
    if v.isDebug() or v.lock then
        entity_setPosition(me, entity_getPosition(v.n))
    else
        entity_updateMovement(me, dt)
    end
    cam_setPosition(entity_getPosition(me))
    --entity_setMaxSpeed(me, entity_getMaxSpeed(getNaija())) -- may fail if naija is in a current
   entity_setMaxSpeed(me, 460)
end

function enterState(me)
end

function exitState(me)
end

function msg(me, msg)
    if msg == "lock" then
        v.lock = true
    elseif msg == "free" then
        v.lock = false
    end
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

