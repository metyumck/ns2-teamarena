Script.Load("lua/Marine.lua")


class 'VIP' (Marine)

VIP.kMapName = "vip"

if Server then
    Script.Load("lua/VIP_Server.lua")
elseif Client then
    Script.Load("lua/VIP_Client.lua")
end

local networkVars = {}



function UpdateNanoArmor(self)
    //VIP always has nanoarmor to identify him
    self.hasNanoArmor = true 
    
    return true
end

function ActivateNanoShieldWrapper(self)
    self:ActivateNanoShield()
    
    return true
end



function VIP:OnCreate()
    Marine.OnCreate(self)
end

function VIP:OnInitialized()
    
    Marine.OnInitialized(self)
    self:ActivateNanoShield()
end


Shared.LinkClassToMap("VIP", VIP.kMapName, networkVars, true)