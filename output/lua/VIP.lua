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

function VIP:OnInitialized()
    Marine.OnInitialized(self)
    self:ActivateNanoShield()
    self:AddTimedCallback(UpdateNanoArmor, 1)
    self:AddTimedCallback(ActivateNanoShieldWrapper, 0.7)
end


Shared.LinkClassToMap("VIP", VIP.kMapName, networkVars, true)