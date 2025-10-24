local addon = cfItemColors

-- WoW API calls
local _CreateFrame = CreateFrame
local _GetNumQuestLogEntries = GetNumQuestLogEntries
local _GetQuestLogTitle = GetQuestLogTitle
local _GetNumQuestLeaderBoards = GetNumQuestLeaderBoards
local _GetQuestLogLeaderBoard = GetQuestLogLeaderBoard
local _GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo

-- Quest objective item cache
local questObjectiveCache = {}

-- Rebuild quest objective cache from quest log
local function rebuildQuestObjectiveCache()
	wipe(questObjectiveCache)  -- wipe is Lua table function, no underscore prefix

	local numQuests = _GetNumQuestLogEntries()
	for questIndex = 1, numQuests do
		local _, _, _, isHeader = _GetQuestLogTitle(questIndex)
		if not isHeader then
			-- Process quest objectives
			local numObjectives = _GetNumQuestLeaderBoards(questIndex)
			for objectiveIndex = 1, numObjectives do
				local objectiveText, objectiveType = _GetQuestLogLeaderBoard(objectiveIndex, questIndex)
				if objectiveType == "item" and objectiveText then
					local questItemName = string.match(objectiveText, "^(.-):%s*%d+/%d+")
					if questItemName then
						questObjectiveCache[questItemName] = true
					end
				end
			end

			-- Process special quest items
			local specialItemLink = _GetQuestLogSpecialItemInfo(questIndex)
			if specialItemLink then
				local specialItemName = string.match(specialItemLink, "|h%[([^%]]+)%]|h")
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
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", rebuildQuestObjectiveCache)
