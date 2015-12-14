// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\RailPistol.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/EffectsMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'RailPistol' (ClipWeapon)

RailPistol.kMapName = "railpistol"

local kModelName = PrecacheAsset("models/marine/welder/builder.model")
local kViewModels = GenerateMarineViewModelPaths("welder")
local kAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_rr_view.animation_graph")
local kChargeTime = 2
// The RailPistol will automatically shoot if it is charged for too long.
local kChargeForceShootTime = 2.2
local kRailPistolRange = 400
local kRailPistolSpread = Math.Radians(0)
local kBulletSize = 0.3


local kRailPistolChargeTime = 1.4

local kChargeSound = PrecacheAsset("sound/NS2.fev/marine/heavy/railgun_charge")

PrecacheAsset("cinematics/vfx_materials/alien_frag.surface_shader")
PrecacheAsset("cinematics/vfx_materials/decals/railgun_hole.surface_shader")

local networkVars =
{
    timeChargeStarted = "time",
    RailPistolAttacking = "boolean",
    lockCharging = "boolean",
    timeOfLastShot = "time"
}



function RailPistol:OnCreate()

    ClipWeapon.OnCreate(self)
    InitMixin(self, PointGiverMixin)
    
    self.timeChargeStarted = 0
    self.RailPistolAttacking = false
    self.lockCharging = false
    self.timeOfLastShot = 0
    
    if Client then
    
        InitMixin(self, ClientWeaponEffectsMixin)
        self.chargeSound = Client.CreateSoundEffect(Shared.GetSoundIndex(kChargeSound))
        self.chargeSound:SetParent(self:GetId())
        
    end

end

function RailPistol:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function RailPistol:GetAnimationGraphName()
    return kAnimationGraph
end

function RailPistol:GetSprintAllowed()
    return false
end

function RailPistol:GetHUDSlot()
    return kNoWeaponSlot
end

function RailPistol:GetWeight()
    return kRailPistolWeight
end

function RailPistol:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(ClipWeapon.kHumanAttachPoint)
    
end

function RailPistol:OnHolster(player)

    ClipWeapon.OnHolster(self, player)
    
    self.building = false
    
end

function RailPistol:OnDrawClient()

    ClipWeapon.OnDrawClient(self)
    
    self.playEffect = true
    
end

function RailPistol:OnHolsterClient()

    ClipWeapon.OnHolsterClient(self)
    
    self.playEffect = false
    
end

function RailPistol:UpdateViewModelPoseParameters(viewModel)
    viewModel:SetPoseParam("welder", 0)
end


function RailPistol:OnUpdateAnimationInput(modelMixin)

    PROFILE("Builder:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", "primary")
    modelMixin:SetAnimationInput("welder", false)
    
end

function RailPistol:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    if self.chargeSound then
    
        Client.DestroySoundEffect(self.chargeSound)
        self.chargeSound = nil
        
    end
    
    if self.chargeDisplayUI then
    
        Client.DestroyGUIView(self.chargeDisplayUI)
        self.chargeDisplayUI = nil
        
    end
    
end

function RailPistol:OnInitialized()

    ClipWeapon.OnInitialized(self)
    
    self:SetModel(kModelName, kAnimationGraph)
    
end

function RailPistol:OnPrimaryAttack(player)
    if not self.lockCharging and self.timeOfLastShot + kRailPistolChargeTime <= Shared.GetTime() then
        
        if not self.RailPistolAttacking then
           
            self.timeChargeStarted = Shared.GetTime()
            
        end
        self.RailPistolAttacking = true
        
    end
    
end

function RailPistol:GetIsThrusterAllowed()
    return not self.RailPistolAttacking
end

function RailPistol:GetWeight()
    return kRailPistolWeight
end

function RailPistol:OnPrimaryAttackEnd(player)
    self.RailPistolAttacking = false
end

function RailPistol:GetBarrelPoint()

    local player = self:GetParent()
    if player then
    
        if player:GetIsLocalPlayer() then
        
            local origin = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            
            return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * -0.65 + viewCoords.yAxis * -0.19
        
        else
    
            local origin = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            
            return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * -0.35 + viewCoords.yAxis * -0.15

            
        end    
        
    end
    
    return self:GetOrigin()
    
end

function RailPistol:GetTracerEffectName()
    return kRailgunTracerEffectName
end

function RailPistol:GetTracerResidueEffectName()
    return kRailgunTracerResidueEffectName
end

function RailPistol:GetTracerEffectFrequency()
    return 1
end

function RailPistol:GetDeathIconIndex()
    return kDeathMessageIcon.Railgun
end

function RailPistol:GetChargeAmount()
    return self.RailPistolAttacking and math.min(1, (Shared.GetTime() - self.timeChargeStarted) / kChargeTime) or 0
end

local function TriggerSteamEffect(self, player)

    player:TriggerEffects("railgun_steam_right")
  
    
end

function RailPistol:GetIsAffectedByWeaponUpgrades()
    return true
end

local function ExecuteShot(self, startPoint, endPoint, player)

    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAllButIsa("Tunnel"))
    local hitPointOffset = trace.normal * 0.3
    local direction = (endPoint - startPoint):GetUnit()
    local damage = kRailPistolDamage + math.min(1, (Shared.GetTime() - self.timeChargeStarted) / kChargeTime) * kRailPistolChargeDamage

    local extents = GetDirectedExtentsForDiameter(direction, kBulletSize)
    
    if trace.fraction < 1 then
    
        // do a max of 10 capsule traces, should be sufficient
        local hitEntities = {}
        for i = 1, 20 do
        
            local capsuleTrace = Shared.TraceBox(extents, startPoint, trace.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
            if capsuleTrace.entity then
            
                if not table.find(hitEntities, capsuleTrace.entity) then
                
                    table.insert(hitEntities, capsuleTrace.entity)
                    self:DoDamage(damage, capsuleTrace.entity, capsuleTrace.endPoint + hitPointOffset, direction, capsuleTrace.surface, false, false)
                
                end
                
            end    
                
            if (capsuleTrace.endPoint - trace.endPoint):GetLength() <= extents.x then
                break
            end
            
            // use new start point
            startPoint = Vector(capsuleTrace.endPoint) + direction * extents.x * 3
        
        end
        
        // for tracer
        local effectFrequency = self:GetTracerEffectFrequency()
        local showTracer = ConditionalValue(GetIsVortexed(player), false, math.random() < effectFrequency)
        self:DoDamage(0, nil, trace.endPoint + hitPointOffset, direction, trace.surface, false, showTracer)
        
        if Client and showTracer then
            TriggerFirstPersonTracer(self, trace.endPoint)
        end
    
    end
    
end

function RailPistol:LockGun()
    self.timeOfLastShot = Shared.GetTime()
end

local function Shoot(self)

    local player = self:GetParent()
    
    // We can get a shoot tag even when the clip is empty if the frame rate is low
    // and the animation loops before we have time to change the state.
    if player then
   
        player:TriggerEffects("railgun_attack")
        
        local viewAngles = player:GetViewAngles()
        local shootCoords = viewAngles:GetCoords()
        
        local startPoint = player:GetEyePos()
        
        local spreadDirection = CalculateSpread(shootCoords, kRailPistolSpread, NetworkRandom)
        
        local endPoint = startPoint + spreadDirection * kRailPistolRange
        ExecuteShot(self, startPoint, endPoint, player)
        
        if Client then
            TriggerSteamEffect(self, player)
        end
        
        self:LockGun()
        self.lockCharging = true
        
    end
    
end

if Server then

    function RailPistol:OnParentKilled(attacker, doer, point, direction)
    end
    
    /**
     * The RailPistol explodes players. We must bypass the ragdoll here.
     */
    function RailPistol:OnDamageDone(doer, target)
    
        if doer == self then
        
            if target:isa("Player") and not target:GetIsAlive() then
                target:SetBypassRagdoll(true)
            end
            
        end
        
    end
    
end

function RailPistol:ProcessMoveOnWeapon(player, input)

    if self.RailPistolAttacking then
    
        if (Shared.GetTime() - self.timeChargeStarted) >= kChargeForceShootTime then
            self.RailPistolAttacking = false
        end
        
    end
    
end

function RailPistol:OnUpdateRender()

    ClipWeapon.OnUpdateRender(self)
    local chargeAmount = self:GetChargeAmount()
    
    
    if self.chargeSound then
    
        local playing = self.chargeSound:GetIsPlaying()
        if not playing and chargeAmount > 0 then
            self.chargeSound:Start()
        elseif playing and chargeAmount <= 0 then
            self.chargeSound:Stop()
        end
        
        self.chargeSound:SetParameter("charge", chargeAmount, 1)
        
    end
    
end

function RailPistol:OnTag(tagName)
 
    PROFILE("RailPistol:OnTag")
    
    if tagName == "l_shoot" then
        Shoot(self)
    elseif tagName == "l_shoot_end" then
        self.lockCharging = false
    end
end

function RailPistol:OnUpdateAnimationInput(modelMixin)

    local activity = "none"
    if self.RailPistolAttacking then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity_left", activity)
    
end

if Client then

    local kRailPistolMuzzleEffectRate = 0.5
    local kMuzzleAttachPoint = "fxnode_weldermuzzle"    
    local kMuzzleEffectName = PrecacheAsset("cinematics/marine/Railgun/muzzle_flash.cinematic")

    function RailPistol:OnClientPrimaryAttackEnd()
    
        local parent = self:GetParent()
        
        if parent then
            CreateMuzzleCinematic(self, kCinematicName, kCinematicName, kMuzzleAttachPoint)
        end
        
    end
    
    function RailPistol:GetSecondaryAttacking()
        return false
    end
    
    function RailPistol:GetIsActive()
        return true
    end    
    
    function RailPistol:GetPrimaryAttacking()
        return self.RailPistolAttacking
    end
    
    function RailPistol:OnProcessMove(input)
    
        Entity.OnProcessMove(self, input)
        
        local player = self:GetParent()
        
        if player then
    
            // trace and highlight first target
            local filter = EntityFilterAllButMixin("RailgunTarget")
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * kRailPistolRange
            local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAllButIsa("Tunnel"))
            local direction = (endPoint - startPoint):GetUnit()
            
            local extents = GetDirectedExtentsForDiameter(direction, kBulletSize)
            
            self.RailPistolTargetId = nil
            
            if trace.fraction < 1 then

                for i = 1, 20 do
                
                    local capsuleTrace = Shared.TraceBox(extents, startPoint, trace.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
                    if capsuleTrace.entity then
                    
                        capsuleTrace.entity:SetRailgunTarget()
                        self.RailPistolTargetId = capsuleTrace.entity:GetId()
                        break
                        
                    end    
                
                end
            
            end
        
        end
    
    end
    
    function RailPistol:GetTargetId()
        return self.RailPistolTargetId
    end
    
end

if Client then

    function RailPistol:GetUIDisplaySettings()
        return { xSize = 512, ySize = 512, script = "lua/GUIWelderDisplay.lua", textureNameOverride = "welder" }
    end
    
end

Shared.LinkClassToMap("RailPistol", RailPistol.kMapName, networkVars)