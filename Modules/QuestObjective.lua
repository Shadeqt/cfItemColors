local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.QUEST_OBJECTIVE].enabled then return end

-- Module constants
local QUEST_LOG_TITLE_QUESTID = 8 -- GetQuestLogTitle() returns questID as 8th value

-- Quest-related items missing proper classification
local MISCLASSIFIED_QUEST_ITEMS = {
	["Thunder Ale"] = 310,
	["Kravel's Crate"] = 5762,
}

-- Extracts item objectives and special quest items from quest log entry
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

-- Increments cache version and notifies listeners
local function invalidateQuestCache()
	addon.questCacheVersion = addon.questCacheVersion + 1
	addon.onQuestObjectivesChanged()
end

-- Builds complete quest item cache from all active quests
local function createQuestCache()
	local numQuests = GetNumQuestLogEntries()
	for i = 1, numQuests do
		local _, _, _, isHeader = GetQuestLogTitle(i)
		if not isHeader then
			local items, questID = extractQuestItems(i)

			for itemName in pairs(items) do
				addon.questObjectiveCache[itemName] = questID
			end

			for itemName, misclassifiedQuestID in pairs(MISCLASSIFIED_QUEST_ITEMS) do
                if questID == misclassifiedQuestID then
                    addon.questObjectiveCache[itemName] = questID
                end
            end
		end
	end
	invalidateQuestCache()
end

-- Adds items from newly accepted quest to cache
local function onQuestAccepted(questLogIndex)
	C_Timer.After(0.2, function()
		local items, questID = extractQuestItems(questLogIndex)
		for itemName in pairs(items) do
			addon.questObjectiveCache[itemName] = questID
		end

		for itemName, misclassifiedQuestID in pairs(MISCLASSIFIED_QUEST_ITEMS) do
			if questID == misclassifiedQuestID then
				addon.questObjectiveCache[itemName] = questID
			end
		end

		invalidateQuestCache()
	end)
end

-- Removes items from abandoned or completed quest from cache
local function onQuestRemoved(questID)
	for itemName, ownerID in pairs(addon.questObjectiveCache) do
		if ownerID == questID then
			addon.questObjectiveCache[itemName] = nil
		end
	end

	invalidateQuestCache()
end

-- Track how many QUEST_LOG_UPDATEs to skip (for stale/incomplete data on initial login)
local skipQuestLogUpdateCount = 0

-- Build and maintain quest objective cache from quest log
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")  		-- Quest accepted
eventFrame:RegisterEvent("QUEST_REMOVED")  			-- Quest abandoned or completed
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  	-- Login (controls skip counter)
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")  		-- Quest log updated (first update only)
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