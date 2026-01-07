local Utils = require "utils"

local hookQuestSubsystem = "/Game/Core/Quests/System/BP_QuestSubsystem.BP_QuestSubsystem_C"

local QuestLogic = {}

local MoneyPacksPercentUpgrades = {
    [0] = { Min = 0, Max = 0, GlobalProb = 0 },
    [1] = { Min = 10, Max = 50, GlobalProb = 30 },
    [2] = { Min = 50, Max = 90, GlobalProb = 70 },
}

local OuterFillPercentUpgrades = {
    [0] = { Min = 25, Max = 60},
    [1] = { Min = 50, Max = 80},
    [2] = { Min = 75, Max = 100},
}

local MarkedMoneyPercentUpgrades = {
    [0] = { Min = 75, Max = 100},
    [1] = { Min = 50, Max = 80},
    [2] = { Min = 25, Max = 60},
}

local RequiredMoneyFactorUpgrades = {
    [0] = { Min = 5, Max = 10}, 
    [1] = { Min = 2, Max = 5}, 
    [2] = { Min = 1, Max = 1}, 
    [3] = { Min = 0.5, Max = 0.75}, 
    [4] = { Min = 0.25, Max = 0.5}, 
}

local FillerPercentUpgrades = {
    [0] = { TrashMin = 75, TrashMax = 100, CoinMin = 0, CoinMax = 25},
    [1] = { TrashMin = 25, TrashMax = 75, CoinMin = 25, CoinMax = 75},
    [2] = { TrashMin = 0, TrashMax = 25, CoinMin = 75, CoinMax = 100},
}

local MixPercentUpgrades = {
    [0] = { Min = 0, Max = 10, Probability = 100 }, 
    [1] = { Min = 20, Max = 50, Probability = 50}, 
    [2] = { Min = 50, Max = 100, Probability = 20}, 
}

local AdditionalMoneyPercentUpgrades = {
    [0] = { Min = 5, Max = 10 }, 
    [1] = { Min = 20, Max = 50 }, 
    [2] = { Min = 50, Max = 100 }, 
}

local RareMoneyPercentUpgrades = {
    [0] = { Money = 5, Coin = 5 }, 
    [1] = { Money = 10, Coin = 10 },  
    [2] = { Money = 25, Coin = 25 }, 
}

-- total 18 upgrades
local CurrentUpgrades = {
    ["MoneyPacksPercentUpgrades"] = 0,
    ["OuterFillPercentUpgrades"] = 0,
    ["MarkedMoneyPercentUpgrades"] = 0,
    ["RequiredMoneyFactorUpgrades"] = 0,
    ["FillerPercentUpgrades"] = 0,
    ["MixPercentUpgrades"] = 0,
    ["AdditionalMoneyPercentUpgrades"] = 0,
    ["RareMoneyPercentUpgrades"] = 0,
}
QuestLogic.CurrentUpgrades = CurrentUpgrades

-- total 16 locations
local AvailableQuestBonuses = {
    ["Exact money value"] = { All = true },
    ["More money value"] =  { All = true }, 
    ["Much more money value"] =  { All = true }, 
    ["Single delivery"] =  { All = true }, 
    ["Nothing else"] =  { All = true },
    ["No marked money"] =  { All = true, ["no-mark"] = true },
    ["No fake money"] = { All = true, ["no-fake"] = true },
    ["Perfect packs"] = { All = true, ["packs"] = true },
    ["Perfect blocks"] = { All = true, ["blocks"] = true },
    ["Marked with Labels!"] = { All = true },
    ["Perfect rolls"] = { All = true },
    ["Perfect roll-blocks"] = { All = true },
}
QuestLogic.AvailableQuestBonuses = AvailableQuestBonuses

-- 23 main quest location before pig available
-- 11 optional main location after pig
-- 14 main quest after pig
-- 2 high rep quest (16/24)
-- total 50 main quests

-- max 30 side locations 
QuestLogic.CompletedSideQuests = 0
QuestLogic.CompletedMainQuests = 0

QuestLogic.MaxCompletedSideQuests = 30

QuestLogic.CompletedSideQuestsIds = {}
QuestLogic.CompletedMainQuestsIds = {}

QuestLogic.ForceOpenPneumaticTube = false
QuestLogic.MaxDifficulty = -1

function QuestLogic:Init(ctx)
    self.Save = ctx.Save
    self.Reward = ctx.Reward
    self.MarketLogic = ctx.MarketLogic
end

local BaseMoneyRange = {
    [1] = { Min = 5000, Max = 25000},
    [2] = { Min = 30000, Max = 70000},
    [3] = { Min = 80000, Max = 145000},
    [4] = { Min = 180000, Max = 350000},
}

local BaseCoinRange = {
    [1] = { Min = 10, Max = 50},
    [2] = { Min = 50, Max = 180},
    [3] = { Min = 180, Max = 400},
    [4] = { Min = 400, Max = 1000},
}

function QuestLogic:AlterQuestGenerator()
    local questGenerator = FindFirstOf("BP_QuestGenerator_C")
    if questGenerator ~= nil and questGenerator:IsValid() then

        local moneyRangesArray = questGenerator.MoneyRangesPerVolume
        if moneyRangesArray ~= nil then
            for i = 1, # (moneyRangesArray), 1 do
                local moneyRange = moneyRangesArray[i]
                moneyRange.Min = math.ceil(BaseMoneyRange[i].Min * RequiredMoneyFactorUpgrades[self.CurrentUpgrades["RequiredMoneyFactorUpgrades"]].Min)
                moneyRange.Max = math.ceil(BaseMoneyRange[i].Max * RequiredMoneyFactorUpgrades[self.CurrentUpgrades["RequiredMoneyFactorUpgrades"]].Max)
            end
        end

        local coinsRangesArray = questGenerator.CoinsRangesPerVolume
        if coinsRangesArray ~= nil then
            for i = 1, # (moneyRangesArray), 1 do
                local coinsRange = coinsRangesArray[i] 
                coinsRange.Min = math.ceil(BaseCoinRange[i].Min * RequiredMoneyFactorUpgrades[self.CurrentUpgrades["RequiredMoneyFactorUpgrades"]].Min)
                coinsRange.Max = math.ceil(BaseCoinRange[i].Max * RequiredMoneyFactorUpgrades[self.CurrentUpgrades["RequiredMoneyFactorUpgrades"]].Max)
            end
        end

        questGenerator.MoneyPacksPercent.Min = MoneyPacksPercentUpgrades[self.CurrentUpgrades["MoneyPacksPercentUpgrades"]].Min
        questGenerator.MoneyPacksPercent.Max = MoneyPacksPercentUpgrades[self.CurrentUpgrades["MoneyPacksPercentUpgrades"]].Max
        questGenerator.CreatePacksProbPercent = MoneyPacksPercentUpgrades[self.CurrentUpgrades["MoneyPacksPercentUpgrades"]].GlobalProb

        questGenerator.OuterFillPercent.Min = OuterFillPercentUpgrades[self.CurrentUpgrades["OuterFillPercentUpgrades"]].Min
        questGenerator.OuterFillPercent.Max = OuterFillPercentUpgrades[self.CurrentUpgrades["OuterFillPercentUpgrades"]].Max

        questGenerator.MarkedMoneyPercent.Min = MarkedMoneyPercentUpgrades[self.CurrentUpgrades["OuterFillPercentUpgrades"]].Min
        questGenerator.MarkedMoneyPercent.Max = MarkedMoneyPercentUpgrades[self.CurrentUpgrades["OuterFillPercentUpgrades"]].Max

        questGenerator.TrashFillerRange.Min = FillerPercentUpgrades[self.CurrentUpgrades["FillerPercentUpgrades"]].TrashMin
        questGenerator.TrashFillerRange.Max = FillerPercentUpgrades[self.CurrentUpgrades["FillerPercentUpgrades"]].TrashMax

        questGenerator.CoinsFillerRange.Min = FillerPercentUpgrades[self.CurrentUpgrades["FillerPercentUpgrades"]].CoinMin
        questGenerator.CoinsFillerRange.Min = FillerPercentUpgrades[self.CurrentUpgrades["FillerPercentUpgrades"]].CoinMax

        questGenerator.CurrencyMixExtraMoneyPercent.Min = MixPercentUpgrades[self.CurrentUpgrades["MixPercentUpgrades"]].Min
        questGenerator.CurrencyMixExtraMoneyPercent.Max = MixPercentUpgrades[self.CurrentUpgrades["MixPercentUpgrades"]].Max
        questGenerator.CurrencyMixProbability = MixPercentUpgrades[self.CurrentUpgrades["MixPercentUpgrades"]].Probability
        questGenerator.CurrencyMixReputationLevelRequirement = 1

        questGenerator.UniqueObjectAddProbability = 0.05
        questGenerator.CoinsAddProbability = 0.1

        questGenerator.AdditionalMoneyValuePercent.Min = AdditionalMoneyPercentUpgrades[self.CurrentUpgrades["AdditionalMoneyPercentUpgrades"]].Min
        questGenerator.AdditionalMoneyValuePercent.Max = AdditionalMoneyPercentUpgrades[self.CurrentUpgrades["AdditionalMoneyPercentUpgrades"]].Max

        questGenerator.MarkedMoneyAmountRange.Min = 100
        questGenerator.MarkedMoneyAmountRange.Max = 100

        questGenerator.RareMoneyChance = RareMoneyPercentUpgrades[self.CurrentUpgrades["RareMoneyPercentUpgrades"]].Money
        questGenerator.RareCoinChance = RareMoneyPercentUpgrades[self.CurrentUpgrades["RareMoneyPercentUpgrades"]].Coin
    end
end

function QuestLogic:SetCompletedSideQuest(value)
    self.CompletedSideQuests = value
end

function QuestLogic:SetCompletedMainQuest(value)
    self.CompletedMainQuests = value
end

function QuestLogic:SetMaxCompletedSideQuests(value)
    self.MaxCompletedSideQuests = value
end

function QuestLogic:ReceiveUpgrade(target)
    self.CurrentUpgrades[target] = self.CurrentUpgrades[target] + 1
    self:AlterQuestGenerator()
end

function QuestLogic:SetUpgrades(Upgrades)
    self.CurrentUpgrades = Upgrades
    self:AlterQuestGenerator()
end

function QuestLogic:UpdateForceOpenTube(isOpen)
    if isOpen then
        self.ForceOpenPneumaticTube = true
        self:ForceOpenTube()
    end
end

function QuestLogic:LoadAvailableQuestBonuses(bonuses)
    self.AvailableQuestBonuses = bonuses
end

function QuestLogic:LoadCompletedQuests(MainQuestsIds, SideQuestsIds)
    self.CompletedSideQuestsIds = SideQuestsIds
    self.CompletedMainQuestsIds = MainQuestsIds
end

function QuestLogic:SetMaxDifficulty(Difficulty)
    self.MaxDifficulty = Difficulty
end

function QuestLogic:LogQuestStarted()
    local pre,post = RegisterHook(hookQuestSubsystem .. ":OnQuestStarted", function(_self, questRef)
        print("[MarketMod] quest subsystem OnQuestStarted hook triggered")
        print("quest type", type(questRef))
        local quest = questRef:get()
        print("[MarketMod] Quest started hook triggered", type(quest))
        print(string.format("[MarketMod] Quest started: %s", Utils.GuidToString(quest.QuestId)))
        print("Quest difficulty", quest.Info.Difficulty)
    end)
    Utils.OnQuit(function()
        local functionName = hookQuestSubsystem .. ":OnQuestStarted"
        UnregisterHook(functionName, pre, post)
    end)
end

function QuestLogic:LogQuestRegistered()
    local pre,post = RegisterHook("/Script/CashCleanerSim.Quest:OnRegistered", function(_self)
        local quest = _self:get()
        print(string.format("[MarketMod] Quest registered: %s", Utils.GuidToString(quest.QuestId)))
        print(string.format("[MarketMod] Quest Name: %s", quest.Info.Name:ToString()))
        print(string.format("[MarketMod] Quest Description: %s", quest.Info.Description:ToString()))

        Utils.LoopGameplayTagContainer(quest.GameplayTags.StaticTags, function(tag, index)
            print(string.format("[MarketMod] Static gameplay Tag: %s", tag.TagName:ToString()))
        end)
        Utils.LoopGameplayTagContainer(quest.GameplayTags.GameplayTags, function(tag, index)
            print(string.format("[MarketMod] Gameplay Tag: %s", tag.TagName:ToString()))
        end)
        Utils.LoopGameplayTagContainer(quest.Info.GameplayTags, function(tag, index)
            print(string.format("[MarketMod] Info Gameplay Tag: %s", tag.TagName:ToString()))
        end)
    end)
    Utils.OnQuit(function()
        local functionName = "/Script/CashCleanerSim.Quest:OnRegistered"
        UnregisterHook(functionName, pre, post)
    end)
end

function QuestLogic:AlterQuestValidationRule(Quest)
    for i = 1, #Quest.Objectives do
        local objective = Quest.Objectives[i]

        if objective.DesiredMoneyCurrency or objective.DesiredMoneyValueV2 ~= nil then
            for j = 1, #objective.ValidationRules do
                local rule = objective.ValidationRules[j]
                if rule:ToString() == "bills-usd" then
                    objective.ValidationRules[j] = FName("blocks-usd")
                end
                j = j + 1
            end
        end
        i = i + 1
    end
end

function QuestLogic:InitQuestLimitations()
    local pre, post = RegisterHook("/Script/CashCleanerSim.Quest:OnRegistered", function(_self)
        local quest = _self:get()
        
        if quest.Info.Rewards ~= nil then 
            if #quest.Info.Rewards > 0 then
                for i=1, #quest.Info.Rewards do
                    pcall(function()
                        local reward = quest.Info.Rewards[i]
                        if reward.Reputation ~= nil and type(reward.Reputation) == "number" then
                            reward.Reputation = 0
                        end

                        local readableQuestName = quest.Info.Name:ToString()
                        
                        if readableQuestName == "The Light Test" or readableQuestName == "Hot Dry" or readableQuestName == "Clean Cut" then
                            if reward.SpawnRequests ~= nil then
                                if #reward.SpawnRequests then
                                    local requests = reward.SpawnRequests
                                    for j = 1, #reward.SpawnRequests do
                                        
                                        local req = reward.SpawnRequests[j]
                                        local countRange = req.ObjectsCount
                                
                                        countRange.Min = 0
                                        countRange.Max = 0

                                        j = j + 1
                                    end
                                end
                            end
                        end
                    end)
                    i = i + 1
                end

                for i=1, #quest.Info.FailurePenalty do
                    pcall(function()
                        local penality = quest.Info.FailurePenalty[i]
                        if penality.Reputation ~= nil and type(penality.Reputation) == "number" then
                            penality.Reputation = 0
                        end
                    end)
                    i = i + 1
                end

                for i=1, #quest.Info.CancelFee do
                    pcall(function()
                        local fee = quest.Info.CancelFee[i]
                        if fee.Reputation ~= nil and type(fee.Reputation) == "number" then
                            fee.Reputation = 0
                        end
                    end)
                    i = i + 1
                end
            end
        end

        if quest.Info.Name:ToString() == "Shop Till Drops" then
            local smartphoneSubSystem = FindFirstOf("BP_SmartphoneSubsystem_C")
            smartphoneSubSystem:MakeAllAppsAvailable()

            local questGenerator = FindFirstOf("BP_QuestGenerator_C")
            questGenerator:start()            
        end

    end)
    Utils.OnQuit(function()
        local functionName = "/Script/CashCleanerSim.Quest:OnRegistered"
        UnregisterHook(functionName, pre, post)
    end) 
end

function QuestLogic:SkipCurrentQuest()
    local subsystem = FindFirstOf("BP_QuestSubsystem_C")
    subsystem:CompleteTrackedQuest()
end

function QuestLogic:PunishQuestCancel(questInstance)
    for i = 1, #questInstance.Objectives do
        local objective = questInstance.Objectives[i]

        if objective.DesiredMoneyCurrency and objective.DesiredMoneyCurrency ~= nil then

            local dMoney = 0
            if objective.DesiredMoneyValue and objective.DesiredMoneyValue ~= nil and objective.DesiredMoneyValue ~= 0 then
                dMoney = objective.DesiredMoneyValue
            end
            if objective.DesiredMoneyValueV2 and objective.DesiredMoneyValueV2 ~= nil then
                dMoney = objective.DesiredMoneyValueV2.Value
            end

            if objective.DesiredMoneyCurrency.TagName:ToString() ~= "Object.Property.Denomination.USD" then
                dMoney = dMoney / (100 / MixPercentUpgrades[self.CurrentUpgrades["MixPercentUpgrades"]].Max )
            end
            if objective.DesiredMoneyCurrency.TagName:ToString() == "Object.Property.Denomination.JPY" then                           
                dMoney = dMoney / 100
            end
            dMoney = dMoney * (1.0 + AdditionalMoneyPercentUpgrades[self.CurrentUpgrades["AdditionalMoneyPercentUpgrades"]].Max / 100)
            local pig = FindFirstOf("BP_MoneyPig_C")
            if pig ~= nil then
                pig:SetNewGoal(pig.MoneyGoal + dMoney)
                self:ForceOpenTube()
            end
       
        end

        i = i + 1
    end
end

function QuestLogic:ForceOpenTube()
    if not self.ForceOpenPneumaticTube then
        local pre,post = RegisterHook("/Game/Core/Objects/BP_PneumaticMail.BP_PneumaticMail_C:OnLaunchEnded", function(_self)
            local PneumaticMail = _self:get()
            PneumaticMail:Open(true)
        end)
        Utils.OnQuit(function()
            local functionName = "/Game/Core/Objects/BP_PneumaticMail.BP_PneumaticMail_C:OnLaunchEnded"
            UnregisterHook(functionName, pre, post)
        end)
        self.ForceOpenPneumaticTube = true
    end
end

function QuestLogic:AwardBonus(Bonus, ValidationRules)
    if self.AvailableQuestBonuses[Bonus].All then
        self.AvailableQuestBonuses[Bonus].All = false
        self.Reward:Award("Quest_Bonus_" .. Bonus)
    end

    if Bonus == "No marked money" and ValidationRules["no-mark"] and self.AvailableQuestBonuses[Bonus]["no-mark"] then
        self.AvailableQuestBonuses[Bonus]["no-mark"] = false
        self.Reward:Award("Quest_Bonus_" .. Bonus .. "_with_quest")

    end

    if Bonus == "No fake money" and ValidationRules["no-fake"] and self.AvailableQuestBonuses[Bonus]["no-fake"] then
        self.AvailableQuestBonuses[Bonus]["no-fake"] = false
        self.Reward:Award("Quest_Bonus_" .. Bonus .. "_with_quest")

    end

    if Bonus == "Perfect packs" and ValidationRules["packs"] and self.AvailableQuestBonuses[Bonus]["packs"] then
        self.AvailableQuestBonuses[Bonus]["packs"] = false
        self.Reward:Award("Quest_Bonus_" .. Bonus .. "_with_quest")

    end

    if Bonus == "Perfect blocks" and ValidationRules["blocks"] and self.AvailableQuestBonuses[Bonus]["blocks"] then
        self.AvailableQuestBonuses[Bonus]["blocks"] = false
        self.Reward:Award("Quest_Bonus_" .. Bonus .. "_with_quest")
    end
end

function QuestLogic:OnQuestFinish()
    local pre, post = RegisterHook("/Script/CashCleanerSim.Quest:OnFinished", function(_self, Resolution)
        local questInstance = _self:get()

        local isSide = true
        Utils.LoopGameplayTagContainer(questInstance.Info.GameplayTags, function(tag, index)
            if  tag.TagName:ToString() == "Quest.Property.NonDiscardable" then
                isSide = false
            end
            
            if tag.TagName:ToString():find("^Quest.Specific.Tutorial") or
               tag.TagName:ToString():find("^Quest.Specific.Main") or
               tag.TagName:ToString():find("^Quest.Specific.Side") then
                isSide = false
            end 
        end)

        local canceled = false
        Utils.LoopGameplayTagContainer(Resolution:get(), function(tag, index)
            if tag.TagName:ToString() == "Quest.Resolution.Canceled" or tag.TagName:ToString() == "Quest.Resolution.Failed" then
                canceled = true
            end
        end)

        if canceled then
            self:PunishQuestCancel(questInstance)
        end
        
        if not canceled and not isSide then
            if not self.CompletedMainQuestsIds[Utils.GuidToString(questInstance.QuestId)] then
                self.CompletedMainQuestsIds[Utils.GuidToString(questInstance.QuestId)] = true
                self.Reward:Award("MainQuest_" .. self.CompletedMainQuests)
                self.CompletedMainQuests = self.CompletedMainQuests + 1
            end
        end

        if not canceled and isSide then
            if not self.CompletedSideQuestsIds[Utils.GuidToString(questInstance.QuestId)] then
                self.CompletedSideQuestsIds[Utils.GuidToString(questInstance.QuestId)] = true
                if self.CompletedSideQuests < self.MaxCompletedSideQuests then
                    self.Reward:Award("SideQuest_" .. self.CompletedSideQuests)
                end
                self:SetCompletedSideQuest(self.CompletedSideQuests + 1)
            end
            
            local difficulty = questInstance.Info.Difficulty
            if difficulty > self.MaxDifficulty then
                while self.MaxDifficulty < difficulty do
                    self.MaxDifficulty = self.MaxDifficulty + 1
                    self.Reward:Award("Difficulty_" .. self.MaxDifficulty)
                end
            end

            local ValidationRules = {}
            for i = 1, #questInstance.Objectives do
                local objective = questInstance.Objectives[i]
                if objective.DesiredMoneyCurrency ~= nil or objective.DesiredMoneyValueV2 ~= nil then
                    if objective.ValidationRules ~= nil then
                        if #objective.ValidationRules > 0 then
                            for j = 1, #objective.ValidationRules do
                                local rule = objective.ValidationRules[j]
                                if rule:ToString() == "no-fake" then
                                    ValidationRules["no-fake"] = true
                                end
                                if rule:ToString() == "no-mark" then
                                    ValidationRules["no-mark"] = true
                                end
                                if rule:ToString():find("^blocks") then
                                    ValidationRules["blocks"] = true
                                end
                                if rule:ToString():find("^packs") then
                                    ValidationRules["packs"] = true
                                end
                                j = j + 1
                            end
                        end
                    end
                end
                i = i + 1
            end
            local Bonuses = questInstance.Bonuses
            for i = 1, #Bonuses do
                local bonus = Bonuses[i]
                if bonus:IsCompleted() then 
                    self:AwardBonus(bonus.Description:ToString(), ValidationRules)
                end
                i = i + 1
            end
        end
        
    end)
    Utils.OnQuit(function()
        local functionName = "/Script/CashCleanerSim.Quest:OnFinished"
        UnregisterHook(functionName, pre, post)
    end)
end

function QuestLogic:HandleReward(reward)
    local UpgradeKey = reward:match("^Quest_(.+)$")
    self:ReceiveUpgrade(UpgradeKey)
    self.Save:OnChange()
end

function QuestLogic:Start()
    self:InitQuestLimitations()
    self:OnQuestFinish()
end

return QuestLogic