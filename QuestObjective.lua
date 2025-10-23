local addon = cfItemColors

-- Localized API calls
local wipe = wipe
local string_match = string.match
local CreateFrame = CreateFrame
local GetNumQuestLogEntries = GetNumQuestLogEntries
local GetQuestLogTitle = GetQuestLogTitle
local GetNumQuestLeaderBoards = GetNumQuestLeaderBoards
local GetQuestLogLeaderBoard = GetQuestLogLeaderBoard
local GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo

-- Quest objective item cache
local questObjectiveCache = {}

-- Rebuild quest objective cache from quest log
local function RebuildQuestObjectiveCache()
	wipe(questObjectiveCache)

	local numQuests = GetNumQuestLogEntries()
	for questIndex = 1, numQuests do
		local _, _, _, isHeader = GetQuestLogTitle(questIndex)
		if not isHeader then
			-- Process quest objectives
			local numObjectives = GetNumQuestLeaderBoards(questIndex)
			for objectiveIndex = 1, numObjectives do
				local objectiveText, objectiveType = GetQuestLogLeaderBoard(objectiveIndex, questIndex)
				if objectiveType == "item" and objectiveText then
					local questItemName = string_match(objectiveText, "^(.-):%s*%d+/%d+")
					if questItemName then
						questObjectiveCache[questItemName] = true
					end
				end
			end

			-- Process special quest items
			local specialItemLink = GetQuestLogSpecialItemInfo(questIndex)
			if specialItemLink then
				local specialItemName = string_match(specialItemLink, "|h%[([^%]]+)%]|h")
				if specialItemName then
					questObjectiveCache[specialItemName] = true
				end
			end
		end
	end
end

-- Check if item is a quest objective
function addon.IsQuestObjective(itemName)
	if not itemName then return false end
	return questObjectiveCache[itemName] == true
end

-- Listen for quest log changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", RebuildQuestObjectiveCache)
