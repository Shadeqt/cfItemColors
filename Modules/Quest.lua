local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor
local applyQualityColorWithQuestCheck = addon.applyQualityColorWithQuestCheck

-- Localized API calls
local _GetNumQuestLogChoices = GetNumQuestLogChoices
local _GetNumQuestChoices = GetNumQuestChoices
local _GetNumQuestLogRewards = GetNumQuestLogRewards
local _GetNumQuestRewards = GetNumQuestRewards
local _GetQuestLogItemLink = GetQuestLogItemLink
local _GetQuestItemLink = GetQuestItemLink
local _GetNumQuestItems = GetNumQuestItems

-- Constants
local QuestLogFrame = QuestLogFrame

-- Apply quality colors to quest reward buttons
local function updateQuestRewardButtons(buttonNamePrefix)
	local isQuestLogOpen = QuestLogFrame and QuestLogFrame:IsVisible()

	local getNumChoices = isQuestLogOpen and _GetNumQuestLogChoices or _GetNumQuestChoices
	local getNumRewards = isQuestLogOpen and _GetNumQuestLogRewards or _GetNumQuestRewards
	local getItemLink = isQuestLogOpen and _GetQuestLogItemLink or _GetQuestItemLink

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
local function updateQuestRequiredItems()
	local numRequiredItems = _GetNumQuestItems()
	for i = 1, numRequiredItems do
		local requiredItemButton = _G["QuestProgressItem" .. i]
		if requiredItemButton then
			local requiredItemLink = _GetQuestItemLink("required", i)
			applyQualityColorWithQuestCheck(requiredItemButton, requiredItemLink)
		end
	end
end

-- Hook quest NPC dialog updates
local function updateQuestInfoRewards()
	updateQuestRewardButtons("QuestInfoRewardsFrameQuestInfoItem")
end

local function updateQuestLogRewards()
	updateQuestRewardButtons("QuestLogItem")
end

-- Hook quest UI updates
hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)
hooksecurefunc("QuestInfo_Display", updateQuestInfoRewards)
hooksecurefunc("QuestLog_Update", updateQuestLogRewards)
