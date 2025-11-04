-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local MAX_QUEST_ITEMS = 10 -- Maximum quest reward/choice items (6 choice + 4 guaranteed)
local MAX_REQUIRED_ITEMS = 6 -- Maximum required items for quest progress

-- Module states
local questInfoButtonCache = {}
local questLogButtonCache = {}
local questProgressButtonCache = {}

-- Pre-cache quest frames at module load
for i = 1, MAX_QUEST_ITEMS do
	questInfoButtonCache[i] = _G["QuestInfoRewardsFrameQuestInfoItem" .. i]
	questLogButtonCache[i] = _G["QuestLogItem" .. i]
end

for i = 1, MAX_REQUIRED_ITEMS do
	questProgressButtonCache[i] = _G["QuestProgressItem" .. i]
end

local function updateQuestRewards(buttonCache)
	local isQuestLog = QuestLogFrame and QuestLogFrame:IsVisible()

	local numChoices = isQuestLog and GetNumQuestLogChoices() or GetNumQuestChoices()
	local numRewards = isQuestLog and GetNumQuestLogRewards() or GetNumQuestRewards()
	local getItemLink = isQuestLog and GetQuestLogItemLink or GetQuestItemLink

	-- All rewards (choice + guaranteed)
	local totalRewards = numChoices + numRewards
	for i = 1, totalRewards do
		local button = buttonCache[i]
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
		local button = questProgressButtonCache[i]
		local itemLink = GetQuestItemLink("required", i)
		applyQualityColor(button, itemLink)
	end
end

-- Triggers when viewing quest details at NPC
hooksecurefunc("QuestInfo_Display", function()
	updateQuestRewards(questInfoButtonCache)
	-- Retry after short delay for timing issues
	C_Timer.After(0.1, function()
		updateQuestRewards(questInfoButtonCache)
	end)
end)

-- Triggers when quest log refreshes
hooksecurefunc("QuestLog_Update", function()
	updateQuestRewards(questLogButtonCache)
end)

-- Triggers when quest progress dialog shows required items
hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)
