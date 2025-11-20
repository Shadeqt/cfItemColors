local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.QUEST_OBJECTIVE].enabled then return end

-- Quest-related items that are misclassified by WoW's API (always treated as quest items)
local MISCLASSIFIED_QUEST_ITEMS = {
	["Thunder Ale"] = true,
	["Kravel's Crate"] = true,
}

-- Extracts item objectives from quest log entry
local function extractQuestItems(questLogIndex)
	local items = {}

	-- Extract item collection objectives
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

	return items
end

-- Rebuilds complete quest item cache from all active quests
local function rebuildQuestCache()
	-- Start with empty cache
	addon.questObjectiveCache = {}

	-- Add misclassified items as baseline (always present)
	for itemName in pairs(MISCLASSIFIED_QUEST_ITEMS) do
		addon.questObjectiveCache[itemName] = true
	end

	-- Add items from current quest log
	local numQuests = GetNumQuestLogEntries()
	for i = 1, numQuests do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			local items = extractQuestItems(i)

			for itemName in pairs(items) do
				addon.questObjectiveCache[itemName] = true
			end
		end
	end

	-- Count and print summary
	local count = 0
	for _ in pairs(addon.questObjectiveCache) do
		count = count + 1
	end
	print(string.format("|cff00ff00[QuestObjective]|r %d items cached", count))

	addon.onQuestObjectivesChanged()
end

-- Build and maintain quest objective cache from quest log
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")  		-- Quest accepted
eventFrame:RegisterEvent("QUEST_REMOVED")  			-- Quest abandoned or completed
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  	-- Initial cache build
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "QUEST_ACCEPTED" then
		rebuildQuestCache()
	elseif event == "QUEST_REMOVED" then
		rebuildQuestCache()
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(0.5, rebuildQuestCache)
		eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)