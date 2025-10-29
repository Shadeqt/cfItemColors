local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor
local applyQualityColorWithQuestCheck = addon.applyQualityColorWithQuestCheck

-- Cache API calls
local _GetNumQuestLogChoices = GetNumQuestLogChoices
local _GetNumQuestChoices = GetNumQuestChoices
local _GetNumQuestLogRewards = GetNumQuestLogRewards
local _GetNumQuestRewards = GetNumQuestRewards
local _GetQuestLogItemLink = GetQuestLogItemLink
local _GetQuestItemLink = GetQuestItemLink
local _GetNumQuestItems = GetNumQuestItems
local _hooksecurefunc = hooksecurefunc
local _QuestLogFrame = QuestLogFrame
local _G = _G

-- Update quest reward buttons (both quest log and NPC dialog)
local function updateQuestRewards(buttonPrefix)
	local isQuestLog = _QuestLogFrame and _QuestLogFrame:IsVisible()
	
	local numChoices = isQuestLog and _GetNumQuestLogChoices() or _GetNumQuestChoices()
	local numRewards = isQuestLog and _GetNumQuestLogRewards() or _GetNumQuestRewards()
	local getItemLink = isQuestLog and _GetQuestLogItemLink or _GetQuestItemLink
	
	-- All rewards (choice + guaranteed)
	local totalRewards = numChoices + numRewards
	for i = 1, totalRewards do
		local button = _G[buttonPrefix .. i]
		if button then
			local itemLink
			if i <= numChoices then
				itemLink = getItemLink("choice", i)
			else
				itemLink = getItemLink("reward", i - numChoices)
			end
			applyQualityColor(button, itemLink)
		end
	end
end

-- Update quest required items
local function updateQuestRequiredItems()
	local numItems = _GetNumQuestItems()
	for i = 1, numItems do
		local button = _G["QuestProgressItem" .. i]
		if button then
			local itemLink = _GetQuestItemLink("required", i)
			applyQualityColorWithQuestCheck(button, itemLink)
		end
	end
end

-- Triggers when viewing quest details at NPC
_hooksecurefunc("QuestInfo_Display", function()
	updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem")
	-- Retry after short delay for timing issues
	C_Timer.After(0.1, function()
		updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem")
	end)
end)

-- Triggers when quest log refreshes
_hooksecurefunc("QuestLog_Update", function()
	updateQuestRewards("QuestLogItem")
end)

-- Triggers when quest progress dialog shows required items
_hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)