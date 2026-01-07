local Utils = require "utils"
local RewardList = require "rewardList"
local RewardLocation = require "rewardLocations"

local Reward = {}

Reward.SAVE_PATH = "ue4ss/Mods/Randomizer/Saved/spoiler.lua"
Reward.ExpectedReputation = 1

function Reward:Init(ctx)
    self.Save = ctx.Save
    self.QuestLogic = ctx.QuestLogic
    self.StackSize = ctx.StackSize
    self.MarketLogic = ctx.MarketLogic 
    self:Read()
end

function Reward:Write(data)
    local f, err = io.open(self.SAVE_PATH, "w")
    if not f then
        return false
    end

    f:write("return ")
    f:write(Utils.Serialize(data))
    f:close()

    return true
end

function Reward:Read()
    local ok, data = pcall(dofile, self.SAVE_PATH)
    if ok and type(data) == "table" then
        self.rewardMap = data
        return data
    end

    local generated = self:Generate()
    self:Write(generated)
    self.rewardMap = generated
    return generated
end

local function toArray(t)
    local arr = {}
    for _, v in pairs(t) do
        table.insert(arr, v)
    end
    return arr
end

function Reward:Generate()
    print("[Randomizer] Generating spoiler map")

    local rewards = toArray(RewardList)
    local locations = toArray(RewardLocation)

    math.randomseed(os.time())
    for i = #rewards, 2, -1 do
        local j = math.random(i)
        rewards[i], rewards[j] = rewards[j], rewards[i]
    end

    local generated = {}
    for i = 1, #locations do
        generated[locations[i]] = rewards[i]
    end
    return generated
end

function Reward:GiveMoney()
    ExecuteInGameThread(function()
        local playerState = FindFirstOf("BP_GameplayPlayerState_C")
        if playerState ~= nil and playerState:IsValid() then
            playerState:SetCryptoCurrency(playerState.CryptoCurrency + 500)
        end
        self.Save:OnChange()
    end)
end

function Reward:SetExpectedReputation(Reputation)
    self.ExpectedReputation = Reputation
    ExecuteInGameThread(function()
        local playerState = FindFirstOf("BP_GameplayPlayerState_C")
        if playerState ~= nil and playerState:IsValid() then
            while playerState.ReputationLevel < self.ExpectedReputation do
                playerState:SetReputationLevel(playerState.ReputationLevel + 1, true)
            end
        end
    end)
end

function Reward:GiveReputation()
    ExecuteInGameThread(function()
        local playerState = FindFirstOf("BP_GameplayPlayerState_C")
        if playerState ~= nil and playerState:IsValid() then
            playerState:SetReputationLevel(playerState.ReputationLevel + 1, true)
            self.ExpectedReputation = self.ExpectedReputation + 1
        end
        self.Save:OnChange()
    end)
end

function Reward:GetLocationText(location)
    if location:find("^Main") then
        local number = location:match("^MainQuest_(%d+)$")
        return "Completing main quest " .. number
    elseif location:find("^SideQuest") then
        local number = location:match("^SideQuest_(%d+)$")
        return "Completing side quest " .. number
    elseif location:find("^Difficulty") then
        local number = location:match("^Difficulty_(%d+)$")
        return "Completing side quest with difficulty " .. number
    elseif location:match("^Quest_Bonus_(.+)_with_quest$") then
        local questBonus = location:match("^Quest_Bonus_(.+)_with_quest$")
        return "Completing a specific side quest with bonus " .. questBonus
    elseif location:match("^Quest_Bonus_(.+)$") then
        local questBonus = location:match("^Quest_Bonus_(.+)$")
        return "Completing a side quest with bonus " .. questBonus
    elseif location == "WorldInteractionsRelaxArea" then
        return "Opening the relax area"
    elseif location == "WorldInteractionsUpperArea" then
        return "Opening the upper area"
    elseif location == "WorldInteractionsDunked" then
        return "Scoring 200 points"  
    elseif location == "WorldInteractionsOutOfBound" then
        return "Going out of bounds"  
    elseif location == "WorldInteractionsMoneyGun" then
        return "Buying a Money gun"
    elseif location:find("^WorldCollectiblesMarked") then
        local bill = location:match("^WorldCollectiblesMarked(.+)$")
        return "Collecting " .. bill .. " marked bill"
    elseif location:find("^WorldCollectiblesCoin") then
        local coin = location:match("^WorldCollectiblesCoin(.+)$")
        return "Collecting " .. coin .. " rare coin"
    elseif location:find("^WorldCollectiblesBillEUR.") then
        local coin = location:match("^WorldCollectiblesBillEUR.(%d+)$")
        return "Collecting " .. coin .. "Euro rare bill"
    elseif location:find("^WorldCollectiblesBillJPY.") then
        local coin = location:match("^WorldCollectiblesBillJPY.(%d+)$")
        return "Collecting " .. coin .. "Yen rare bill"
    elseif location:find("^WorldCollectiblesBillUSD.") then
        local coin = location:match("^WorldCollectiblesBillUSD.(%d+)$")
        return "Collecting " .. coin .. "Dollar rare bill"
    end
end

function Reward:GetRewardText(reward)
    if reward:find("^Quest") then
        if reward == "Quest_MoneyPacksPercentUpgrades" then
            return "money packs are now more common"
        elseif reward == "Quest_OuterFillPercentUpgrades" then
            return "containers are now filled a bit more"
        elseif reward == "Quest_MarkedMoneyPercentUpgrades" then
            return "less likely to have marked money"
        elseif reward == "Quest_RequiredMoneyFactorUpgrades" then
            return "less required money for quests"
        elseif reward == "Quest_FillerPercentUpgrades" then    
            return "less trash in containers"   
        elseif reward == "Quest_MixPercentUpgrades" then  
            return "less likely to have additional currency but get more of it"     
        elseif reward == "Quest_RareMoneyPercentUpgrades" then  
            return "more likely to find rare collectibles"     
        elseif reward == "Quest_AdditionalMoneyPercentUpgrades" then   
            return "more money at the start of quests"    
        end
    elseif reward == "StackSizeUpgrade" then
        return "upgrading stack size"
    elseif reward == "ReputationGain" then
        return "increased reputation"
    elseif reward == "MoneyGain" then
        return "some cryptocurrency"
    elseif reward:find("^Market") then
        if reward == "Market_BP_MoneyGun_C" then
            return "less reputation required for Money Gun"
        elseif reward == "Market_BP_Washer_C" then
            return "less reputation required for small washer"
        elseif reward == "Market_BP_UVLamp_C" then
            return "less reputation required for UV Lamps"
        elseif reward == "Market_BP_Dryer_C" then
            return "less reputation required for Dryers"
        elseif reward == "Market_BP_MoneyCounter_C" then
            return "less reputation required for Basic Money Counter"
        elseif reward == "Market_BP_MoneyCounterTier2_C" then
            return "less reputation required for Tier 2 Money Counter"
        elseif reward == "Market_BP_MoneyCounterTier2_Euro_C" then
            return "less reputation required for Tier 2 Euro Money Counter"
        elseif reward == "Market_BP_MoneyCounterTier2_Yen_C" then
            return "less reputation required for Tier 2 Yen Money Counter"
        elseif reward == "Market_BP_MoneyCounterTier3_C" then
            return "less reputation required for Tier 3 Money Counter"
        elseif reward == "Market_BP_Ladder_C" then
            return "less reputation required for Ladder"
        elseif reward == "Market_BP_WorkbenchTool_Sponge_C" then
            return "less reputation required for workbench sponge"
        elseif reward == "Market_BP_MarkedCounter_C" then
            return "less reputation required for Marked Money Counter"
        elseif reward == "Market_BP_WorkbenchTool_FoamA_C" then
            return "less reputation required for workbench Ink foam"
        elseif reward == "Market_BP_WorkbenchTool_FoamB_C" then
            return "less reputation required for workbench Mark foam"
        elseif reward == "Market_BP_WorkbenchTool_FoamC_C" then
            return "less reputation required for workbench Goo foam"
        elseif reward == "Market_BP_DetergentSourceComponent_C" then
            return "less reputation required for Ink detergent"
        elseif reward == "Market_BP_DetergentSourceComponent_C2" then
            return "less reputation required for Mark detergent"
        elseif reward == "Market_BP_DetergentSourceComponent_C3" then
            return "less reputation required for Goo detergent"
        elseif reward == "Market_BP_BigWasher_C" then
            return "less reputation required for Big Washers"
        elseif reward == "Market_BP_StickerGun_C" then
            return "less reputation required for Label gun"
        elseif reward == "Market_BP_PickupSensor_CoinCounter_C" then
            return "less reputation required for Coin Counter"
        end
    end     
end

function Reward:Award(location)
    local reward = self.rewardMap[location]
    local message = "[Randomizer] " .. self:GetLocationText(location) .. " gave you this reward : "
    Utils.Notify(message .. self:GetRewardText(reward))
    if reward:find("^Quest") then
        self.QuestLogic:HandleReward(reward)
    elseif reward == "StackSizeUpgrade" then
        self.StackSize:HandleReward()
    elseif reward == "ReputationGain" then
        self:GiveReputation()
    elseif reward == "MoneyGain" then
        self:GiveMoney()
    elseif reward:find("^Market") then
        self.MarketLogic:HandleReward(reward)
    end     
end

return Reward
