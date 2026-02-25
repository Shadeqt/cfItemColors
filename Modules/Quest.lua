local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.QUEST].enabled then return end

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

-- Build and maintain quest objective cache from quest log
local function rebuildQuestObjectiveCache()
	wipe(addon.questObjectiveCache)
	local allText = {}
	local savedSelection = GetQuestLogSelection()
	for i = 1, GetNumQuestLogEntries() do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			-- Grab quest description text (requires selecting the entry)
			SelectQuestLogEntry(i)
			local description = GetQuestLogQuestText()
			if description then allText[#allText + 1] = description end

			for j = 1, GetNumQuestLeaderBoards(i) do
				local text, objType = GetQuestLogLeaderBoard(j, i)
				if text then
					allText[#allText + 1] = text
					if objType == "item" then
						local name = text:match("^(.-):%s*%d+/%d+")
						if name then addon.questObjectiveCache[name] = true end
					end
				end
			end
		end
	end
	SelectQuestLogEntry(savedSelection)
	addon.questObjectiveText = table.concat(allText, "\n")
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
