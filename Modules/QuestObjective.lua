-- Module enable check
local enabled = cfItemColors.Init.GetModuleState(cfItemColors.Init.MODULES.QUEST_OBJECTIVE)
if not enabled then return end

-- Shared dependencies
local questObjectiveCache = cfItemColors.questObjectiveCache

-- Module constants
local QUEST_LOG_TITLE_QUESTID = 8 -- GetQuestLogTitle() returns questID as 8th value

local MISCLASSIFIED_QUEST_ITEMS = {
	["Thunder Ale"] = 310,
	["Kravel's Crate"] = 5762,
}

-- Extracts item objectives and special quest items from a quest
local function extractQuestItems(questLogIndex)
	local items = {}
	local questID = select(QUEST_LOG_TITLE_QUESTID, GetQuestLogTitle(questLogIndex))

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

	-- Extract special quest items (usable items)
	local specialItemLink = GetQuestLogSpecialItemInfo(questLogIndex)
	if specialItemLink then
		local itemName = specialItemLink:match("|h%[([^%]]+)%]|h")
		if itemName then
			items[itemName] = true
		end
	end

	return items, questID
end

-- Increments cache version and triggers bag refresh
local function invalidateQuestCache()
	cfItemColors.questCacheVersion = cfItemColors.questCacheVersion + 1
	cfItemColors.onQuestObjectivesChanged()
end

-- Builds complete quest item cache on login
local function createQuestCache()
	local numQuests = GetNumQuestLogEntries()
	for i = 1, numQuests do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			local items, questID = extractQuestItems(i)

			for itemName in pairs(items) do
				questObjectiveCache[itemName] = questID
			end

			for itemName, misclassifiedQuestID in pairs(MISCLASSIFIED_QUEST_ITEMS) do
                if questID == misclassifiedQuestID then
                    questObjectiveCache[itemName] = questID
                end
            end
		end
	end
	invalidateQuestCache()
end

-- Adds items from newly accepted quest to cache
local function onQuestAccepted(questLogIndex)
	local items, questID = extractQuestItems(questLogIndex)
	for itemName in pairs(items) do
		questObjectiveCache[itemName] = questID
	end

	for itemName, misclassifiedQuestID in pairs(MISCLASSIFIED_QUEST_ITEMS) do
		if questID == misclassifiedQuestID then
			questObjectiveCache[itemName] = questID
		end
	end

	invalidateQuestCache()
end

-- Removes items belonging to abandoned/completed quest from cache
local function onQuestRemoved(questID)
	for itemName, ownerID in pairs(questObjectiveCache) do
		if ownerID == questID then
			questObjectiveCache[itemName] = nil
		end
	end

	invalidateQuestCache()
end

-- Track how many QUEST_LOG_UPDATEs to skip (for stale/incomplete data on initial login)
local skipQuestLogUpdateCount = 0

-- Event registration and handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "QUEST_ACCEPTED" then
		local questLogIndex = ...
		onQuestAccepted(questLogIndex)
	elseif event == "QUEST_REMOVED" then
		local questID = ...
		onQuestRemoved(questID)
	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReloadingUI = ...
		-- Skip first 2 QUEST_LOG_UPDATEs on login (stale data), but not on reload
		skipQuestLogUpdateCount = isInitialLogin and 2 or 0
	elseif event == "QUEST_LOG_UPDATE" then
		if skipQuestLogUpdateCount > 0 then
			skipQuestLogUpdateCount = skipQuestLogUpdateCount - 1
			return
		end
		-- Initial cache build; subsequent updates handled by QUEST_ACCEPTED/REMOVED events
		createQuestCache()
		eventFrame:UnregisterEvent("QUEST_LOG_UPDATE")
	end
end)