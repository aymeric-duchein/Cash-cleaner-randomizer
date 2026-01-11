local StackSize = require "stackSize"
local Utils = require "utils"
local QuestLogic = require "questLogic"
local MarketLogic = require "marketLogic"
local WorldInteraction = require "worldInteraction"
local Reward = require "reward"
local Save = require "save"
local mainGameMode = "/Game/Core/Rules/BP_TheMainGameMode.BP_TheMainGameMode_C"

ExecuteInGameThread(function()
 
    LoadAsset(mainGameMode) 
    RegisterHook(mainGameMode .. ":ReceiveBeginPlay", function(_self)
        local mainGameModeInstance = _self:get()

        if mainGameModeInstance == nil or not mainGameModeInstance:IsValid() then
            return
        end 

        Reward:Init({
            QuestLogic = QuestLogic,
            Save = Save,
            WorldInteraction = WorldInteraction,
            MarketLogic = MarketLogic,
            StackSize = StackSize
        })
        Save:Init({
            QuestLogic = QuestLogic,
            WorldInteraction = WorldInteraction,
            MarketLogic = MarketLogic,
            StackSize = StackSize,
            Reward = Reward
        })
        QuestLogic:Init({
            Save = Save,
            Reward = Reward,
            MarketLogic = MarketLogic
        })
        WorldInteraction:Init({
            Save = Save,
            Reward = Reward
        })
        MarketLogic:Init({
            Save = Save,
            Reward = Reward
        })
        StackSize:Init({
            Save = Save,
            MarketLogic = MarketLogic
        })
        Save:LoadSave()

        QuestLogic:Start()
        WorldInteraction:ListenAllEvents()

        print("[Randomizer] Mod initialized")

        Utils.OnWakeUp(function()
            WorldInteraction:AlterInitConsumables()
        end)

        RegisterKeyBind(Key.K, function()
            QuestLogic:SkipCurrentQuest()
        end)
    end)

    
end)
