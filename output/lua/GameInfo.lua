// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua/GameInfo.lua
//
// GameInfo is used to sync information about the game state to clients.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GameInfo' (Entity)

GameInfo.kMapName = "gameinfo"

local networkVars =
{
    state = "enum kGameState",
    startTime = "time",
    averagePlayerSkill = "integer",
    isGatherReady = "boolean",
    rookieMode = "boolean",
    numPlayersTotal = "integer",
    isDedicated = "boolean",
    marineWins = "integer",
    alienWins = "integer",
    currentVIPSteamId = "integer",
    currentTimeLeft = "float",

}

function GameInfo:OnCreate()

    Entity.OnCreate(self)
    
    if Server then
    
        self:SetPropagate(Entity.Propagate_Always)
        self:SetUpdates(false)
        
        self.state = kGameState.NotStarted
        self.startTime = 0
        self.averagePlayerSkill = 0
        self.numPlayersTotal = 0
	self.isDedicated = Server.IsDedicated()
        self.marineWins = 0
        self.alienWins = 0
        self.listOfMarinePlayers = {}
        self.currentVIPSteamId = 0
        self.currentTimeLeft = 0
        
        
    end
    
end

function GameInfo:GetStartTime()
    return self.startTime
end

function GameInfo:GetGameStarted()
    return self.state == kGameState.Started
end

function GameInfo:GetState()
    return self.state
end

function GameInfo:GetAveragePlayerSkill()
    return self.averagePlayerSkill
end

function GameInfo:GetCurrentVIPSteamID()
    return self.currentVIPSteamId
end

function GameInfo:GetNumPlayersTotal()
    return self.numPlayersTotal
end

function GameInfo:GetMarineWins()
    return self.marineWins
end
    
function GameInfo:GetAlienWins()
    return self.alienWins
end
    
function GameInfo:SetIsGatherReady(isGatherReady)
    self.isGatherReady = isGatherReady
end

function GameInfo:GetIsGatherReady()
    return self.isGatherReady
end

function GameInfo:GetRookieMode()
    return self.rookieMode
end

function GameInfo:GetCurrentTimeLeft()
    return self.currentTimeLeft
end

if Server then

    function GameInfo:SetCurrentTimeLeft(timeLeft)
        self.currentTimeLeft = timeLeft
    end


    function GameInfo:SetStartTime(startTime)
        self.startTime = startTime
    end
    
    function GameInfo:SetState(state)
        self.state = state
    end
    
    function GameInfo:SetAveragePlayerSkill(skill)
        self.averagePlayerSkill = skill
    end
    
    function GameInfo:SetNumPlayersTotal( numPlayersTotal )
        self.numPlayersTotal = numPlayersTotal
    end

    function GameInfo:SetRookieMode(mode)
        self.rookieMode = mode
    end
    
    function GameInfo:SetMarineWins( marineWins )
        self.marineWins = marineWins
    end
    
    function GameInfo:SetAlienWins( alienWins )
        self.alienWins = alienWins
    end
    
    function GameInfo:SetCurrentVIPSteamID( currentVIPSteamID )
        self.currentVIPSteamId = currentVIPSteamID
    end
    
end

Shared.LinkClassToMap("GameInfo", GameInfo.kMapName, networkVars)