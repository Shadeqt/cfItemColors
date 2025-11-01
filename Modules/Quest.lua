-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

local function updateQuestRewards(buttonPrefix)
	local isQuestLog = QuestLogFrame and QuestLogFrame:IsVisible()

	local numChoices = isQuestLog and GetNumQuestLogChoices() or GetNumQuestChoices()
	local numRewards = isQuestLog and GetNumQuestLogRewards() or GetNumQuestRewards()
	local getItemLink = isQuestLog and GetQuestLogItemLink or GetQuestItemLink

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
	local numItems = GetNumQuestItems()
	for i = 1, numItems do
		local button = _G["QuestProgressItem" .. i]
		if button then
			local itemLink = GetQuestItemLink("required", i)
			applyQualityColorWithQuestCheck(button, itemLink)
		end
	end
end

-- Triggers when viewing quest details at NPC
hooksecurefunc("QuestInfo_Display", function()
	updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem")
	-- Retry after short delay for timing issues
	C_Timer.After(0.1, function()
		updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem")
	end)
end)

-- Triggers when quest log refreshes
hooksecurefunc("QuestLog_Update", function()
	updateQuestRewards("QuestLogItem")
end)

-- Triggers when quest progress dialog shows required items
hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)