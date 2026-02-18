local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.QUEST].enabled then return end

-- Updates quest reward buttons (choices and guaranteed rewards)
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
	updateQuestRewards("QuestInfoRewardsFrameQuestInfoItem")
end

-- Updates quest log rewards
local function updateQuestLogRewards()
	updateQuestRewards("QuestLogItem")
end

hooksecurefunc("QuestInfo_Display", updateQuestInfoRewards)  				-- Quest details shown at NPC
hooksecurefunc("QuestLog_Update", updateQuestLogRewards)  					-- Quest log refreshed
hooksecurefunc("QuestFrameProgressItems_Update", updateQuestRequiredItems)  -- Quest progress items shown

-- Build and maintain quest objective cache from quest log
local function rebuildQuestObjectiveCache()
	wipe(addon.questObjectiveCache)
	for i = 1, GetNumQuestLogEntries() do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			for j = 1, GetNumQuestLeaderBoards(i) do
				local text, objType = GetQuestLogLeaderBoard(j, i)
				if objType == "item" and text then
					local name = text:match("^(.-):%s*%d+/%d+")
					if name then addon.questObjectiveCache[name] = true end
				end
			end
		end
	end
end

local questEventFrame = CreateFrame("Frame")
questEventFrame:RegisterEvent("QUEST_ACCEPTED")
questEventFrame:RegisterEvent("QUEST_REMOVED")
questEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
questEventFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	rebuildQuestObjectiveCache()
end)
