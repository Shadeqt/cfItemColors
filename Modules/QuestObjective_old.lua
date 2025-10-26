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
local pairs = pairs

-- Extract item names from a single quest at the given quest log index
local function extractQuestItems(questIndex, questId)
	local items = {}

	-- Process quest objectives
	local numObjectives = _GetNumQuestLeaderBoards(questIndex)
	for objectiveIndex = 1, numObjectives do
		local objectiveText, objectiveType = _GetQuestLogLeaderBoard(objectiveIndex, questIndex)
		if objectiveType == "item" and objectiveText then
			local questItemName = match(objectiveText, "^(.-):%s*%d+/%d+")
			if questItemName then
				items[questItemName] = true
			end
		end
	end

	-- Process special quest items
	local specialItemLink = _GetQuestLogSpecialItemInfo(questIndex)
	if specialItemLink then
		local specialItemName = match(specialItemLink, "|h%[([^%]]+)%]|h")
		if specialItemName then
			items[specialItemName] = true
		end
	end

	return items
end

-- Add items to cache with questId ownership
local function addItemsToCache(items, questId)
	for itemName in pairs(items) do
		addon.questObjectiveCache[itemName] = questId
	end
end

-- Remove all items belonging to the specified questId
local function removeItemsForQuest(questId)
	for itemName, ownerId in pairs(addon.questObjectiveCache) do
		if ownerId == questId then
			addon.questObjectiveCache[itemName] = nil
		end
	end
end

-- Event handler: Quest accepted (incremental add - scan only the new quest)
local function onQuestAccepted(questLogIndex, questId)
	if not questId then return end

	local items = extractQuestItems(questLogIndex, questId)
	addItemsToCache(items, questId)
end

-- Event handler: Quest removed (incremental remove - no quest scanning needed)
local function onQuestRemoved(questId)
	if not questId then return end

	removeItemsForQuest(questId)
end

-- Event handler: Login/reload (full rebuild necessary)
local function onPlayerEnteringWorld()
	wipe(addon.questObjectiveCache)

	local numQuests = _GetNumQuestLogEntries()
	for questIndex = 1, numQuests do
		local _, _, _, isHeader, _, _, _, questId = _GetQuestLogTitle(questIndex)
		if not isHeader and questId then
			local items = extractQuestItems(questIndex, questId)
			addItemsToCache(items, questId)
		end
	end
end

-- Event dispatcher
local function onQuestEvent(event, arg1, arg2)
	if event == "QUEST_ACCEPTED" then
		onQuestAccepted(arg1, arg2)  -- questLogIndex, questId
	elseif event == "QUEST_REMOVED" then
		onQuestRemoved(arg1)  -- questId
	elseif event == "PLAYER_ENTERING_WORLD" then
		onPlayerEnteringWorld()  -- isLogin, isReload (unused)
	end
end

-- Register quest lifecycle events
local questEventFrame = _CreateFrame("Frame")
questEventFrame:RegisterEvent("QUEST_ACCEPTED")
questEventFrame:RegisterEvent("QUEST_REMOVED")
questEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
questEventFrame:SetScript("OnEvent", onQuestEvent)
