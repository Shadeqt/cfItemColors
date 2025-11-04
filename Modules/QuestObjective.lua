-- Shared dependencies
local questObjectiveCache = cfItemColors.questObjectiveCache

-- GetQuestLogTitle() returns questID as 8th value
local QUEST_LOG_TITLE_QUESTID = 8

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
		print("|cffff00ffFound special item link:|r", specialItemLink)
		local itemName = specialItemLink:match("|h%[([^%]]+)%]|h")
		if itemName then
			print("|cffff00ffAdding special quest item:|r", itemName)
			items[itemName] = true
		end
	end

	return items, questID
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
		end
	end
end

-- Adds items from newly accepted quest to cache
local function onQuestAccepted(questLogIndex)
	local items, questID = extractQuestItems(questLogIndex)
	for itemName in pairs(items) do
		questObjectiveCache[itemName] = questID
	end

	-- Increment cache version to invalidate stale item colors
	cfItemColors.questCacheVersion = cfItemColors.questCacheVersion + 1
	cfItemColors.onQuestObjectivesChanged()
end

-- Removes items belonging to abandoned/completed quest from cache
local function onQuestRemoved(questID)
	for itemName, ownerID in pairs(questObjectiveCache) do
		if ownerID == questID then
			questObjectiveCache[itemName] = nil
		end
	end

	-- Increment cache version to invalidate stale item colors
	cfItemColors.questCacheVersion = cfItemColors.questCacheVersion + 1
	cfItemColors.onQuestObjectivesChanged()
end

-- Event registration and handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "QUEST_ACCEPTED" then
		local questLogIndex = ...
		onQuestAccepted(questLogIndex)
	elseif event == "QUEST_REMOVED" then
		local questID = ...
		onQuestRemoved(questID)
	elseif event == "PLAYER_ENTERING_WORLD" then
		createQuestCache()
	end
end)