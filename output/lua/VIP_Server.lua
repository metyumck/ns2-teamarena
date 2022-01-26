


--Pistol railgun ....ooooooh yeah
function VIP:InitWeapons()

    Player.InitWeapons(self)

    self:GiveItem(RailPistol.kMapName)
    
    self:SetActiveWeapon(RailPistol.kMapName)
end

