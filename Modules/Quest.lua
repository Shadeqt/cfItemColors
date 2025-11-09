-- Module enable check
local enabled = cfItemColors.Compatibility.ShouldModuleLoad("Quest")
if not enabled then return end

-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

local function updateQuestRewards(buttonPrefix)
	local isQuestLog = QuestLogFrame and QuestLogFrame:IsVisible()

	local numChoices = isQuestLog and GetNumQuestLogChoices() or GetNumQuestChoices()
	local numRewards = isQuestLog and GetNumQuestLogRewards() or GetNumQuestRewards()
	local getItemLink = isQuestLog and GetQuestLogItemLink or GetQuestItemLink

	-- All rewards (choice + guaranteed)
	local totalRewards = numChoices + numRewards
	for i = 1, totalRewards do
		local button = _G[buttonPrefix .. i]
		local itemLink
		if i <= numChoices then
			itemLink = getItemLink("choice", i)
		else
			itemLink = getItemLink("reward", i - numChoices)
		end
		applyQualityColor(button, itemLink)
	end
end

-- Update quest required items
local function updateQuestRequiredItems()
	local numItems = GetNumQuestItems()
	for i = 1, numItems do
		local button = _G["QuestProgressItem" .. i]
		local itemLink = GetQuestItemLink("required", i)
		applyQualityColor(button, itemLink)
	end
end

-- Triggers when viewing quest details at NPC
hooksecurefunc("QuestInfo_Display", function()
	updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem")
end)

-- Triggers when quest log refreshes
hooksecurefunc("QuestLog_Update", function()
	updateQuestRewards("QuestLogItem")
end)

-- Triggers when quest progress dialog shows required items
hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)
