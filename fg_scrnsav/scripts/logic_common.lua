if not v then v = {} end

local Common = {} -- "class" def here!


Common.init = function()
    if isFlag(FLAG_MOD_INITED, 0) then
        pickupGem("Naija-Token", 1)
        centerText("To get out, click the mouse and right-click \"Exit\"")
    end
end

Common.postInit = function()
    setFlag(FLAG_MOD_INITED, 1)
end
    

Common.update = function(dt)
end


v.logic.common = Common
