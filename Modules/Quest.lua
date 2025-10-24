local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor
local applyQualityColorWithQuestCheck = addon.applyQualityColorWithQuestCheck

-- Localized API calls
local _G = _G
local QuestLogFrame = QuestLogFrame
local GetNumQuestLogChoices = GetNumQuestLogChoices
local GetNumQuestChoices = GetNumQuestChoices
local GetNumQuestLogRewards = GetNumQuestLogRewards
local GetNumQuestRewards = GetNumQuestRewards
local GetQuestLogItemLink = GetQuestLogItemLink
local GetQuestItemLink = GetQuestItemLink
local GetNumQuestItems = GetNumQuestItems
local hooksecurefunc = hooksecurefunc

-- Apply quality colors to quest reward buttons
local function UpdateQuestRewardButtons(buttonNamePrefix)
	local isQuestLogOpen = QuestLogFrame and QuestLogFrame:IsVisible()

	local getNumChoices = isQuestLogOpen and GetNumQuestLogChoices or GetNumQuestChoices
	local getNumRewards = isQuestLogOpen and GetNumQuestLogRewards or GetNumQuestRewards
	local getItemLink = isQuestLogOpen and GetQuestLogItemLink or GetQuestItemLink

	local numChoiceRewards = getNumChoices()
	local numGuaranteedRewards = getNumRewards()
	local totalRewards = numChoiceRewards + numGuaranteedRewards

	for i = 1, totalRewards do
		local rewardButton = _G[buttonNamePrefix .. i]
		if rewardButton then
			local rewardItemLink
			if i <= numChoiceRewards then
				rewardItemLink = getItemLink("choice", i)
			else
				rewardItemLink = getItemLink("reward", i - numChoiceRewards)
			end
			applyQualityColor(rewardButton, rewardItemLink)
		end
	end
end

-- Apply quality colors to quest required items
local function UpdateQuestRequiredItems()
	local numRequiredItems = GetNumQuestItems()
	for i = 1, numRequiredItems do
		local requiredItemButton = _G["QuestProgressItem" .. i]
		if requiredItemButton then
			local requiredItemLink = GetQuestItemLink("required", i)
			applyQualityColorWithQuestCheck(requiredItemButton, requiredItemLink)
		end
	end
end

-- Hook quest NPC dialog updates
local function UpdateQuestInfoRewards()
	UpdateQuestRewardButtons("QuestInfoRewardsFrameQuestInfoItem")
end

local function UpdateQuestLogRewards()
	UpdateQuestRewardButtons("QuestLogItem")
end

-- Hook quest UI updates
hooksecurefunc("QuestFrameProgressItems_Update", UpdateQuestRequiredItems)
hooksecurefunc("QuestInfo_Display", UpdateQuestInfoRewards)
hooksecurefunc("QuestLog_Update", UpdateQuestLogRewards)
