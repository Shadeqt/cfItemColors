local addon = cfItemColorsModuleOptimized

-- Performance tracking statistics
local stats = {
	eventCounts = {},
	eventTimes = {},
	applyColorCalls = {},
	cacheHits = {},
	colorChanges = {},
	-- Detailed cache breakdown
	cacheItemLink = {},
	cacheQuality = {},
	noItem = {},
	noItemInfo = {},
	sessionStart = GetTime()
}

-- Current event context
local currentEvent = nil
local eventStartTime = nil

-- Verbose logging toggle
local verboseLogging = false
local lastEventTime = 0

-- Track when an event starts
function addon.debugTrackEvent(eventName)
	-- Strip [id] suffix from event name for stats tracking
	-- e.g. "BAG_UPDATE [bag:0]" -> "BAG_UPDATE"
	local baseEventName = eventName:match("^([^%[]+)") or eventName
	baseEventName = baseEventName:gsub("%s+$", "") -- Trim trailing spaces

	currentEvent = baseEventName
	eventStartTime = debugprofilestop()

	stats.eventCounts[baseEventName] = (stats.eventCounts[baseEventName] or 0) + 1
	stats.applyColorCalls[baseEventName] = stats.applyColorCalls[baseEventName] or 0
	stats.cacheHits[baseEventName] = stats.cacheHits[baseEventName] or 0
	stats.colorChanges[baseEventName] = stats.colorChanges[baseEventName] or 0
	stats.cacheItemLink[baseEventName] = stats.cacheItemLink[baseEventName] or 0
	stats.cacheQuality[baseEventName] = stats.cacheQuality[baseEventName] or 0
	stats.noItem[baseEventName] = stats.noItem[baseEventName] or 0
	stats.noItemInfo[baseEventName] = stats.noItemInfo[baseEventName] or 0
	stats.eventTimes[baseEventName] = stats.eventTimes[baseEventName] or {}

	-- Verbose logging (shows full event name with ID)
	if verboseLogging then
		local currentTime = GetTime()
		local timeSinceLastEvent = currentTime - lastEventTime
		lastEventTime = currentTime
		print(string.format("[cfID] +%.3fs | %s", timeSinceLastEvent, eventName))
	end
end

-- Track applyColor call result with detailed cache type
-- cacheType: "itemLink", "quality", "noItem", "noItemInfo", or nil for color change
function addon.debugTrackApplyColor(cacheType)
	if not currentEvent then return end

	stats.applyColorCalls[currentEvent] = stats.applyColorCalls[currentEvent] + 1

	if cacheType == "itemLink" then
		stats.cacheHits[currentEvent] = stats.cacheHits[currentEvent] + 1
		stats.cacheItemLink[currentEvent] = stats.cacheItemLink[currentEvent] + 1
	elseif cacheType == "quality" then
		stats.cacheHits[currentEvent] = stats.cacheHits[currentEvent] + 1
		stats.cacheQuality[currentEvent] = stats.cacheQuality[currentEvent] + 1
	elseif cacheType == "noItem" then
		stats.colorChanges[currentEvent] = stats.colorChanges[currentEvent] + 1
		stats.noItem[currentEvent] = stats.noItem[currentEvent] + 1
	elseif cacheType == "noItemInfo" then
		stats.noItemInfo[currentEvent] = stats.noItemInfo[currentEvent] + 1
	else
		-- Actual color change
		stats.colorChanges[currentEvent] = stats.colorChanges[currentEvent] + 1
	end
end

-- Track when an event ends
function addon.debugClearEvent()
	if currentEvent and eventStartTime then
		local duration = debugprofilestop() - eventStartTime
		table.insert(stats.eventTimes[currentEvent], duration)
	end
	currentEvent = nil
	eventStartTime = nil
end

-- Event groups by module
local eventGroups = {
	{name = "Core (Quest Cache)", events = {"QUEST_LOG_UPDATE", "PLAYER_ENTERING_WORLD"}},
	{name = "Bags", events = {"ToggleBag", "ToggleBackpack", "BAG_UPDATE"}},
	{name = "Bank", events = {"BANKFRAME_OPENED", "PLAYERBANKSLOTS_CHANGED"}},
	{name = "Character", events = {"PLAYER_EQUIPMENT_CHANGED"}},
	{name = "Inspect", events = {"INSPECT_READY", "UNIT_INVENTORY_CHANGED", "ADDON_LOADED"}},
	{name = "Merchant", events = {"MerchantFrame_UpdateMerchantInfo", "MerchantFrame_UpdateBuybackInfo"}},
	{name = "Loot", events = {"LootFrame_UpdateButton"}},
	{name = "Quest", events = {"QuestFrameProgressItems_Update", "QuestInfo_Display", "QuestLog_Update"}},
	{name = "Professions", events = {"TradeSkillFrame_Update", "ADDON_LOADED"}}
}

-- Print debug statistics
local function printStats()
	local sessionTime = GetTime() - stats.sessionStart
	local minutes = math.floor(sessionTime / 60)
	local seconds = math.floor(sessionTime % 60)

	print("=== cfItemColors Performance Debug ===")
	print(string.format("Session time: %dm %ds", minutes, seconds))
	print("")

	-- Print stats grouped by module
	for _, group in ipairs(eventGroups) do
		print(string.format("[%s Module]", group.name))

		for _, eventName in ipairs(group.events) do
			local count = stats.eventCounts[eventName] or 0
			local applyColorCalls = stats.applyColorCalls[eventName] or 0
			local cacheHits = stats.cacheHits[eventName] or 0
			local colorChanges = stats.colorChanges[eventName] or 0
			local cacheItemLink = stats.cacheItemLink[eventName] or 0
			local cacheQuality = stats.cacheQuality[eventName] or 0
			local noItem = stats.noItem[eventName] or 0
			local noItemInfo = stats.noItemInfo[eventName] or 0
			local callsPerEvent = count > 0 and (applyColorCalls / count) or 0
			local cacheHitPercent = applyColorCalls > 0 and (cacheHits / applyColorCalls * 100) or 0
			local changePercent = applyColorCalls > 0 and (colorChanges / applyColorCalls * 100) or 0

			-- Calculate average execution time
			local times = stats.eventTimes[eventName] or {}
			local totalTime = 0
			for _, time in ipairs(times) do
				totalTime = totalTime + time
			end
			local avgTime = #times > 0 and (totalTime / #times) or 0

			if count > 0 then
				print(string.format("  %s: %d calls (%.1f/sec)", eventName, count, count / sessionTime))
				print(string.format("    Avg time: %.4fms", avgTime))
				print(string.format("    ApplyColor: %d calls (%.1f per event)", applyColorCalls, callsPerEvent))
				print(string.format("    Cache hits: %d (%.1f%%) [itemLink:%d quality:%d]", cacheHits, cacheHitPercent, cacheItemLink, cacheQuality))
				print(string.format("    Color changes: %d (%.1f%%) [noItem:%d]", colorChanges, changePercent, noItem))
				print(string.format("    No itemInfo: %d", noItemInfo))
			else
				print(string.format("  %s: Not triggered", eventName))
			end
		end
		print("")
	end

	print("====================================")
end

-- Print performance stats
SLASH_CFTEST1 = "/cftest"
SlashCmdList["CFTEST"] = function()
	printStats()
end

-- Toggle verbose event logging
SLASH_CFVERBOSE1 = "/cfverbose"
SlashCmdList["CFVERBOSE"] = function()
	verboseLogging = not verboseLogging
	lastEventTime = GetTime()
	print(string.format("cfItemColors verbose logging: %s", verboseLogging and "ON" or "OFF"))
end
