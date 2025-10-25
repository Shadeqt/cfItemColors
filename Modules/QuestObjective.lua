local addon = cfItemColors

-- WoW API calls
local _CreateFrame = CreateFrame
local _GetNumQuestLogEntries = GetNumQuestLogEntries
local _GetQuestLogTitle = GetQuestLogTitle
local _GetNumQuestLeaderBoards = GetNumQuestLeaderBoards
local _GetQuestLogLeaderBoard = GetQuestLogLeaderBoard
local _GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo

-- Lua built-ins
local wipe = wipe
local match = string.match

-- Rebuild quest objective cache from quest log
local function rebuildQuestObjectiveCache()
	wipe(addon.questObjectiveCache)

	local numQuests = _GetNumQuestLogEntries()
	for questIndex = 1, numQuests do
		local _, _, _, isHeader = _GetQuestLogTitle(questIndex)
		if not isHeader then
			-- Process quest objectives
			local numObjectives = _GetNumQuestLeaderBoards(questIndex)
			for objectiveIndex = 1, numObjectives do
				local objectiveText, objectiveType = _GetQuestLogLeaderBoard(objectiveIndex, questIndex)
				if objectiveType == "item" and objectiveText then
					local questItemName = match(objectiveText, "^(.-):%s*%d+/%d+")
					if questItemName then addon.questObjectiveCache[questItemName] = true end
				end
			end

			-- Process special quest items
			local specialItemLink = _GetQuestLogSpecialItemInfo(questIndex)
			if specialItemLink then
				local specialItemName = match(specialItemLink, "|h%[([^%]]+)%]|h")
				if specialItemName then addon.questObjectiveCache[specialItemName] = true end
			end
		end
	end
end

-- Register quest lifecycle events
local questEventFrame = _CreateFrame("Frame")
questEventFrame:RegisterEvent("QUEST_ACCEPTED")
questEventFrame:RegisterEvent("QUEST_REMOVED")
questEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
questEventFrame:SetScript("OnEvent", rebuildQuestObjectiveCache)
