


//Pistol railgun ....ooooooh yeah
function VIP:InitWeapons()
    self:GiveItem(Pistol.kMapName)
    self:GiveItem(Axe.kMapName)
    self:GiveItem(RailPistol.kMapName)
    
    self:SetActiveWeapon(RailPistol.kMapName)
end