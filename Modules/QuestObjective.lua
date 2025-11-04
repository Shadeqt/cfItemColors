-- Shared dependencies
local questObjectiveCache = cfItemColors.questObjectiveCache

local function extractQuestItems(questLogIndex)
	local items = {}

	-- Quest objectives (kill X wolves, collect Y items)
	local numObjectives = GetNumQuestLeaderBoards(questLogIndex)
	for i = 1, numObjectives do
		local objectiveText, objectiveType = GetQuestLogLeaderBoard(i, questLogIndex)

		if objectiveType == "item" and objectiveText then
			local itemName = objectiveText:match("^(.-):%s*%d+/%d+")
			if itemName then
				items[itemName] = true
			end
		end
	end

	-- Special quest items (right-click to use)
	local specialItemLink = GetQuestLogSpecialItemInfo(questLogIndex)
	if specialItemLink then
		print("Found special item link:", specialItemLink)
		local itemName = specialItemLink:match("|h%[([^%]]+)%]|h")
		if itemName then
			print("Adding special quest item:", itemName)
			items[itemName] = true
		end
	end

	return items
end

-- Rebuild entire cache
local function rebuildCache()
	wipe(questObjectiveCache)

	local numQuests = GetNumQuestLogEntries()
	for i = 1, numQuests do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			local items = extractQuestItems(i)
			for itemName in pairs(items) do
				questObjectiveCache[itemName] = true
			end
		end
	end

	cfItemColors.onQuestObjectivesChanged()
end

-- Register events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", rebuildCache)