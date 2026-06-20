local _, addon = ...

local QUEST_ITEM_CLASS = Enum.ItemClass.Questitem  -- 12; the tooltip's "Quest Item" class

-- True when the link points to a Quest-class item. Force-golds reward/provided items in a
-- quest-offer dialog (e.g. "you will receive this letter"): the quest isn't in your log yet, so
-- neither Blizzard's per-slot flag nor Questie can vouch for it — the item's own class is the
-- only reliable signal there, needing no quest data, log entry, or GetQuestID.
local function isQuestItemLink(itemLink)
	return itemLink and select(6, C_Item.GetItemInfoInstant(itemLink)) == QUEST_ITEM_CLASS
end

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
		addon.applyQualityColor(button, itemLink, nil, isQuestItemLink(itemLink))
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

-- Updates quest required item buttons. Every item in the progress panel is an
-- objective for the quest currently being turned in — i.e. a quest you are on — so
-- we flag them as quest items directly (isQuestItem = true). The default treatment
-- golds them; under Questie the override re-decides per itemID, narrowing to quests
-- it tracks. No bag slot is involved.
local function updateQuestRequiredItems()
	local numItems = GetNumQuestItems()
	for i = 1, numItems do
		local button = _G["QuestProgressItem" .. i]
		local itemLink = GetQuestItemLink("required", i)
		addon.applyQualityColor(button, itemLink, true)
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

