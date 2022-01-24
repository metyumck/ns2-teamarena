-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TechTree_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IterableDict.lua")

kResearchNotificationSource = enum({ 'CreateNode', 'UpdateNode', 'UpdateNodeInstanced', 'CatchUpSync' })

function GetHasTech(callingEntity, techId, silentError)

        --this change may break aliens

        if callingEntity:isa("Marine") then
  
            local techTree = callingEntity:GetTechTree()
        else

            local techTree = GetTechTree()
        end
        if(techTree ~= nil) then
        
            return techTree:GetHasTech(techId, silentError)
        
        else
            Print("GetHasTech (Client) returned nil tech tree.")
        end
        
        return false
    
end

function GetTechNode(techId)
    
    local techTree = GetTechTree()
    
    if(techTree) then
    
        return techTree:GetTechNode(techId)
        
    end
    
    return nil
    
end

function TechTree:GetResearchInProgress(techId, entityId)

    if entityId ~= nil then

        return self.inProgressInstances[entityId] ~= nil

    end

    return self.inProgressResearch[techId] ~= nil
end

function TechTree:GetAndClearTechTreeResearchCancelled()

    local ret = self.inProgressCancelled
    self.inProgressCancelled = false

    return ret

end

function TechTree:GetResearchInProgressTable(outTable)

    for techId, v in pairs(self.inProgressResearch) do

        if not GetTechIdIsInstanced(techId) then
            table.insert(outTable, v)
        end

    end

    for _, v in pairs(self.inProgressInstances) do
        table.insert(outTable, v)
    end
end

function TechTree:CreateTechNodeFromNetwork(techNodeBaseTable)
    
    local techNode = TechNode()
    ParseTechNodeBaseMessage(techNode, techNodeBaseTable)

    if techNode:GetIsResearch() then

        local techId = techNode:GetTechId()
        local inProgress = ConditionalValue(techNode:GetResearching() and not techNode:GetResearched(), true, nil)
        self.inProgressResearch[techId] = ConditionalValue(inProgress, {techId = techId, entityId = nil}, nil)

        -- Make sure Client knows about researching changes.
        if Client then

            local player = Client.GetLocalPlayer()
            if player and HasMixin(player, "GUINotification") and inProgress and not GetTechIdIsInstanced(techId) then
                player:AddNotification({techId = techId, entityId = nil, source = kResearchNotificationSource.CreateNode})
            end

        end

    end
    
    self:AddNode(techNode)
    
end

function TechTree:UpdateTechNodeFromNetwork(techNodeUpdateTable)

    local techNode = self:GetTechNode(techNodeUpdateTable.techId)

    if techNode ~= nil then

        local lastResearching = techNode:GetResearching() and not techNode:GetResearched()
        ParseTechNodeUpdateMessage(techNode, techNodeUpdateTable)

        if techNode:GetIsResearch() then

            local techId = techNode:GetTechId()
            local inProgress = ConditionalValue(techNode:GetResearching() and not techNode:GetResearched(), true, nil)
            self.inProgressResearch[techId] = ConditionalValue(inProgress, {techId = techId, entityId = nil}, nil)

            if not self.inProgressCancelled then
                self.inProgressCancelled = (lastResearching == true and inProgress == nil)
            end

            -- Make sure Client knows about researching changes.
            if Client and lastResearching ~= inProgress then

                local player = Client.GetLocalPlayer()
                if player and inProgress and HasMixin(player, "GUINotification") and not GetTechIdIsInstanced(techId) then
                    player:AddNotification({techId = techId, entityId = nil, source = kResearchNotificationSource.UpdateNode})
                end

            end
        end
    end
end

function TechTree:UpdateNodeInstanceFromNetwork(instanceUpdateTable)

    local techNode = GetTechTree():GetTechNode(instanceUpdateTable.researchId)
    if techNode ~= nil then

        if not techNode.instances then
            techNode.instances = IterableDict()
        end

        local lastInProgress = self:GetResearchInProgress(instanceUpdateTable.researchId, instanceUpdateTable.entity)
        ParseTechNodeInstanceMessage(techNode, instanceUpdateTable)

        local instance = techNode.instances[instanceUpdateTable.entity]
        local inProgress = (instance.progress > 0 and instance.progress < 1 and not instanceUpdateTable.removed) or nil

        if not self.inProgressCancelled then
            self.inProgressCancelled = (instance.progress < 1 and instanceUpdateTable.removed)
        end

        self.inProgressInstances[instanceUpdateTable.entity] =
        ConditionalValue(inProgress,
                {techId = instanceUpdateTable.researchId, entityId = instanceUpdateTable.entity},
                nil)

        -- Make sure Client knows about researching changes.
        if lastInProgress ~= inProgress then

            local player = Client.GetLocalPlayer()
            if player and inProgress and HasMixin(player, "GUINotification") and GetTechIdIsInstanced(instanceUpdateTable.researchId) then
                player:AddNotification({techId = instanceUpdateTable.researchId, entityId = instanceUpdateTable.entity, source = kResearchNotificationSource.UpdateNodeInstanced})
            end

        end


    end

end