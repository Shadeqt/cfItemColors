local addon = cfItemColors

-- Module enable check
if not cfItemColorsDB[addon.MODULES.QUEST].enabled then return end

-- Colors reward buttons using the given API functions and button prefix
local function colorRewardButtons(buttonPrefix, numChoices, numRewards, getItemLink)
	for i = 1, numChoices + numRewards do
		local button = _G[buttonPrefix .. i]
		local itemLink
		if i <= numChoices then
			itemLink = getItemLink("choice", i)
		else
			itemLink = getItemLink("reward", i - numChoices)
		end
		addon.applyQualityColor(button, itemLink)
	end
end

-- Updates quest detail rewards at NPC
local function updateQuestInfoRewards()
	local numChoices = GetNumQuestChoices()
	local numRewards = GetNumQuestRewards()
	local getLink = GetQuestItemLink
	colorRewardButtons("QuestInfoRewardsFrameQuestInfoItem", numChoices, numRewards, getLink)
end

-- Updates quest log rewards
local function updateQuestLogRewards()
	local numChoices = GetNumQuestLogChoices()
	local numRewards = GetNumQuestLogRewards()
	local getLink = GetQuestLogItemLink
	colorRewardButtons("QuestLogItem", numChoices, numRewards, getLink)
end

-- Updates quest required item buttons
local function updateQuestRequiredItems()
	local numItems = GetNumQuestItems()
	for i = 1, numItems do
		local button = _G["QuestProgressItem" .. i]
		local itemLink = GetQuestItemLink("required", i)
		addon.applyQualityColor(button, itemLink)
	end
end

hooksecurefunc("QuestInfo_Display", updateQuestInfoRewards)  				-- Quest details shown at NPC
hooksecurefunc("QuestLog_Update", updateQuestLogRewards)  					-- Quest log refreshed
hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)  -- Quest progress items shown

-- Re-color when item data arrives from server (GetQuestItemLink returns nil until this fires)
local questItemFrame = CreateFrame("Frame")
questItemFrame:RegisterEvent("QUEST_ITEM_UPDATE")
questItemFrame:SetScript("OnEvent", function()
	if QuestFrame and QuestFrame:IsShown() then
		updateQuestInfoRewards()
		updateQuestRequiredItems()
	end
	if QuestLogFrame and QuestLogFrame:IsShown() then
		updateQuestLogRewards()
	end
end)

