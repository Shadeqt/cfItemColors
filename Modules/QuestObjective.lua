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
		local itemName = specialItemLink:match("|h%[([^%]]+)%]|h")
		if itemName then
			items[itemName] = true
		end
	end

	return items
end

-- Add quest items to cache
local function addQuestItems(questLogIndex, questId)
	local items = extractQuestItems(questLogIndex)
	for itemName in pairs(items) do
		questObjectiveCache[itemName] = questId
	end
end

-- Remove quest items from cache
local function removeQuestItems(questId)
	for itemName, ownerId in pairs(questObjectiveCache) do
		if ownerId == questId then
			questObjectiveCache[itemName] = nil
		end
	end
end

-- Rebuild entire cache
local function rebuildCache()
	wipe(questObjectiveCache)

	local numQuests = GetNumQuestLogEntries()
	for i = 1, numQuests do
		local _, _, _, isHeader, _, _, _, questId = GetQuestLogTitle(i)
		if not isHeader and questId then
			addQuestItems(i, questId)
		end
	end
end

-- Register events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, questLogIndex, questId)
	if event == "QUEST_ACCEPTED" then
		addQuestItems(questLogIndex, questId)
	elseif event == "QUEST_REMOVED" then
		removeQuestItems(questLogIndex)
	elseif event == "PLAYER_ENTERING_WORLD" then
		rebuildCache()
	end
end)