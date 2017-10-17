if not v then v = {} end

local Scrnsav = {} -- "class" def here!

Scrnsav.paths = {}
Scrnsav.cam = 0
Scrnsav.camdst = 0


local function getCamera()
    local cam = Scrnsav.cam
    if cam == 0 then
        cam = getEntity("cam")
        if cam == 0 then
            cam = createEntity("cam")
        end
        Scrnsav.cam = cam
    end
    return cam
end

local function lockCamera()
    entity_msg(getCamera(), "lock")
end

local function freeCamera()
    entity_msg(getCamera(), "free")
end

local function calcCamSpeed(x, y)
    local cam = getCamera()
    local maxs = entity_getMaxSpeed(cam)
    local dx = entity_x(cam) - x
    local dy = entity_y(cam) - y
    local d = math.sqrt(dx*dx + dy*dy)
    return d / maxs
end

local function findPaths()
    local ns, ne, cs, ce
    for i = 1,20 do
        ns = getNode("ns" .. i)
        ne = getNode("ne" .. i)
        cs = getNode("cs" .. i)
        ce = getNode("ce" .. i)
        
        if cs == 0 or ce == 0 then
            cs = 0
            ce = 0
        end
        
        if ns == 0 or ne == 0 then
            ns = 0
            ne = 0
        end
        
        if ns ~= 0 or ne ~= 0 or cs ~= 0 or ce ~= 0 then
            table.insert(Scrnsav.paths, { ns, ne, cs, ce } )
        end
    end
    debugLog("Scrnsav: found " .. #Scrnsav.paths .. " paths")
end

local function startPath(ns, ne, cs, ce)

    debugLog("Scrnsav: start path")
    
    local cam = getCamera()
    
    if cs == 0 then
        debugLog("Scrnsav: locked cam to naija")
        lockCamera() -- no special cam path, lock to naija
    else
        local cx, cy = node_getPosition(cs)
        debugLog(string.format("Scrnsav: cam start: %.2f, %.2f", cx, cy))
        entity_setPosition(cam, cx, cy)
        freeCamera()
        
        --entity_swimToNode(cam, ce)
        
        local endx, endy = node_getPosition(ce)
        entity_interpolateTo(cam, endx, endy, calcCamSpeed(endx, endy))
    end
    
    if ns ~= 0 then
        local nx, ny = node_getPosition(ns)
        debugLog(string.format("Scrnsav: naj start: %.2f, %.2f", nx, ny))
        entity_setPosition(v.n, nx, ny)
        if ne ~= 0 then
            entity_swimToNode(v.n, ne)
        end
        entity_animate(v.n, "swim", -1)
        Scrnsav.camdst = 0
    else
        debugLog("Scrnsav: cam only - " .. node_getName(cs))
        Scrnsav.camdst = ce
    end
end

local function startRandomPath()
    debugLog("Scrnsav: start random path")
    if #Scrnsav.paths == 0 then
        centerText("ERROR: No paths to follow!")
        return
    end
    local r = math.random(#Scrnsav.paths)
    local ns, ne, cs, ce = unpack(Scrnsav.paths[r])
    startPath(ns, ne, cs, ce)
end

Scrnsav.init = function()
    setInvincible(true)
    setCanChangeForm(false)
    avatar_setBlockSinging(true)
    
    if getFlag(FLAG_MUTE_MUSIC) ~= 0 then
        stopMusic()
    end
    
    findPaths()
    getCamera()
end

Scrnsav.postInit = function()
    if not v.isDebug() then
        disableInput()
        startRandomPath()
    end
    
end

Scrnsav.update = function(dt)

    if v.isDebug() then
        return
    end
    
    --entity_setMaxSpeedLerp(v.n, 0.6) -- does not work
    
    if not (entity_isAnimating(v.n) and entity_getAnimationName(v.n) == "swim") then
        debugLog("Scrnsav: swim hack - " .. entity_getAnimationName(v.n) )
        entity_setState(v.n, STATE_FOLLOWNAIJA) -- HACK HACK HAAAAAAACK
        --entity_stopAllAnimations(v.n)
        entity_animate(v.n, "swim", -1)
    end
    
    if Scrnsav.camdst ~= 0 and node_isEntityInRange(Scrnsav.camdst, getCamera(), 500) then
        if chance(100) then
            fade2(0,0,0,0,0)
            fade2(1,1,0,0,0)
            v.pushTQ(1.5, function()
                startRandomPath()
                fade2(0,1,0,0,0)
            end)
        else
            loadMap(v.getRandomMap())
        end
    end
    
    if isInputEnabled() and isFlag(FLAG_UI_VISIBLE, 0) and not v.isDebug() then
        disableInput()
    elseif not isInputEnabled() and isFlag(FLAG_UI_VISIBLE, 1) then
        enableInput()
    end
    
    if isEscapeKey() then
        pause()
		enableInput()
        --unpause() -- NO! otherwise, it will get stuck!
        goToTitle()
    end
end


v.logic.scrnsav = Scrnsav
