local addon = cfItemColors

-- Module enable check
if not cfItemColorsDB[addon.MODULES.QUEST].enabled then return end

-- Updates quest reward buttons (choices and guaranteed rewards)
local function updateQuestRewards(buttonPrefix, isQuestLog)
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
		addon.applyQualityColor(button, itemLink)
	end
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

-- Updates quest detail rewards at NPC
local function updateQuestInfoRewards()
	updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem", false)
end

-- Updates quest log rewards
local function updateQuestLogRewards()
	updateQuestRewards("QuestLogItem", true)
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

-- Build quest text and reset lazy item cache
local function rebuildQuestText()
	wipe(addon.questItemCache)
	local allText = {}
	local savedSelection = GetQuestLogSelection()
	for i = 1, GetNumQuestLogEntries() do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			SelectQuestLogEntry(i)
			local description, objectives = GetQuestLogQuestText()
			if objectives then allText[#allText + 1] = objectives end
			if description then allText[#allText + 1] = description end

			for j = 1, GetNumQuestLeaderBoards(i) do
				local text = GetQuestLogLeaderBoard(j, i)
				if text then allText[#allText + 1] = text end
			end
		end
	end
	SelectQuestLogEntry(savedSelection)
	addon.questObjectiveText = table.concat(allText, "\n")
end

local questEventFrame = CreateFrame("Frame")
questEventFrame:RegisterEvent("QUEST_ACCEPTED")
questEventFrame:RegisterEvent("QUEST_REMOVED")
questEventFrame:RegisterEvent("QUEST_LOG_UPDATE")
questEventFrame:SetScript("OnEvent", function(self, event)
	if event == "QUEST_LOG_UPDATE" then
		self:UnregisterEvent("QUEST_LOG_UPDATE")
	end
	rebuildQuestText()
end)
