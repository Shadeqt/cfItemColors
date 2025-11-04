cfItemColors = {}

-- Performance tracking metrics
cfItemColors.metrics = {
	-- Early returns (in execution order)
	earlyReturn_noItemLink = 0,
	earlyReturn_cachedItemLink = 0,
	earlyReturn_noItemQuality = 0,
	earlyReturn_cachedQuality = 0,
	earlyReturn_borderAlreadyExists = 0,

	-- API calls
	calls_GetItemInfo = 0,
	calls_SetVertexColor = 0,
	calls_CreateTexture = 0,

	-- Color transitions
	transitions = {},  -- {from_quality -> to_quality -> count}

	-- Quest detection
	questUpgrades = 0,
}

-- Helper to track color transitions
local function trackTransition(fromQuality, toQuality)
	local metrics = cfItemColors.metrics
	metrics.transitions[fromQuality] = metrics.transitions[fromQuality] or {}
	metrics.transitions[fromQuality][toQuality] = (metrics.transitions[fromQuality][toQuality] or 0) + 1
end

-- Shared dependencies
cfItemColors.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

cfItemColors.questObjectiveCache = {}
cfItemColors.questCacheVersion = 0

-- Module states
local questObjectiveCache = cfItemColors.questObjectiveCache

local QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
local QUALITY_COMMON    = 1 -- White
local QUALITY_UNCOMMON  = 2 -- Green
local QUALITY_QUEST 	= 99
QUALITY_COLORS[QUALITY_QUEST] = {r = 1.0, g = 0.82, b = 0.0}

local MISCLASSIFIED_QUEST_ITEMS = {
	["Kravel's Crate"] = true,
}

function cfItemColors.IsBagAddonActive()
	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.IsAddOnLoaded(i) then
			local name = C_AddOns.GetAddOnInfo(i):lower()
			local title = (C_AddOns.GetAddOnMetadata(i, "Title") or ""):lower()
			local notes = (C_AddOns.GetAddOnMetadata(i, "Notes") or ""):lower()
			local xnotes = (C_AddOns.GetAddOnMetadata(i, "X-Notes") or ""):lower()
			local category = (C_AddOns.GetAddOnMetadata(i, "Category") or ""):lower()
			local xcategory = (C_AddOns.GetAddOnMetadata(i, "X-Category") or ""):lower()

			-- Check all metadata fields for bag-related keywords
			local fields = {name, title, notes, xnotes, category, xcategory}
			-- Bag addon detection keywords
			local BAG_KEYWORDS = {"bag", "inventory"}

			for _, field in ipairs(fields) do
				for _, keyword in ipairs(BAG_KEYWORDS) do
					if field:find(keyword) then
						return true, C_AddOns.GetAddOnInfo(i)
					end
				end
			end
		end
	end

	return false, nil
end

-- Determines if an item is quest-related based on type, class, or cache
local function isQuestItem(itemType, itemClassId, itemName)
	if itemType == "Quest" or itemClassId == 12 then
		return true
	end

	if questObjectiveCache[itemName] or MISCLASSIFIED_QUEST_ITEMS[itemName] then
		return true
	end

	return false
end

-- Creates and configures a custom border texture for a button
local function createBorder(button)
	if button.border then
		cfItemColors.metrics.earlyReturn_borderAlreadyExists = cfItemColors.metrics.earlyReturn_borderAlreadyExists + 1
		return button.border
	end

	cfItemColors.metrics.calls_CreateTexture = cfItemColors.metrics.calls_CreateTexture + 1

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetTexCoord(0.225, 0.775, 0.225, 0.775)
	border:SetBlendMode("ADD")
	border:SetAlpha(0.8)

	local buttonName = button:GetName()
	local iconTexture = buttonName and _G[buttonName .. "IconTexture"]
	border:SetAllPoints(iconTexture or button)
	border:Hide()

	return border
end

local function showBorder(button, itemQuality)
	if button.itemQuality == itemQuality then
		cfItemColors.metrics.earlyReturn_cachedQuality = cfItemColors.metrics.earlyReturn_cachedQuality + 1
		return
	end

	-- Track color transition
	local fromQuality = button.itemQuality or 0  -- 0 = no border/nil
	trackTransition(fromQuality, itemQuality)

	button.border = createBorder(button)

	cfItemColors.metrics.calls_SetVertexColor = cfItemColors.metrics.calls_SetVertexColor + 1
	local color = QUALITY_COLORS[itemQuality]
	button.border:SetVertexColor(color.r, color.g, color.b)
	button.border:Show()

	button.itemQuality = itemQuality
end

local function hideBorder(button)
	if button.border then
		-- Track transition to hidden (quality 0)
		if button.itemQuality then
			trackTransition(button.itemQuality, 0)
		end
		button.border:Hide()
	end

	button.itemQuality = nil
end

function cfItemColors.applyQualityColor(button, itemIdOrLink)
	if not itemIdOrLink then
		cfItemColors.metrics.earlyReturn_noItemLink = cfItemColors.metrics.earlyReturn_noItemLink + 1
		hideBorder(button)
		button.itemIdOrLink = nil
		return
	end

	if button.itemIdOrLink == itemIdOrLink and button.questCacheVersion == cfItemColors.questCacheVersion then
		cfItemColors.metrics.earlyReturn_cachedItemLink = cfItemColors.metrics.earlyReturn_cachedItemLink + 1
		return
	end

	cfItemColors.metrics.calls_GetItemInfo = cfItemColors.metrics.calls_GetItemInfo + 1
	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then
		cfItemColors.metrics.earlyReturn_noItemQuality = cfItemColors.metrics.earlyReturn_noItemQuality + 1
		return
	end

	button.itemIdOrLink = itemIdOrLink
	button.questCacheVersion = cfItemColors.questCacheVersion

	-- Upgrade quest items to special quality
	if itemQuality <= QUALITY_COMMON and isQuestItem(itemType, itemClassId, itemName) then
		cfItemColors.metrics.questUpgrades = cfItemColors.metrics.questUpgrades + 1
		itemQuality = QUALITY_QUEST
	end

	-- Apply or hide border based on quality
	if itemQuality >= QUALITY_UNCOMMON then
		showBorder(button, itemQuality)
	else
		hideBorder(button)
	end
end

-- Callback invoked when quest objectives change (cache updated)
cfItemColors.onQuestObjectivesChanged = function() end

-- Slash command to display performance metrics
SLASH_CFITEMS1 = "/cfitems"
SlashCmdList["CFITEMS"] = function(msg)
	local metrics = cfItemColors.metrics

	print("|cff00ff00=== cfItemColors Performance Metrics ===|r")
	print(" ")

	-- Early returns (in execution order)
	print("|cffFFD700Early Returns (Execution Order):|r")
	print("  1. No item link:        " .. metrics.earlyReturn_noItemLink)
	print("  2. Cached item link:    |cff00ff00" .. metrics.earlyReturn_cachedItemLink .. "|r |cff888888(saved GetItemInfo)|r")
	print("  3. No item quality:     " .. metrics.earlyReturn_noItemQuality)
	print("  4. Cached quality:      |cff00ff00" .. metrics.earlyReturn_cachedQuality .. "|r |cff888888(saved SetVertexColor)|r")
	print("  5. Border exists:       |cff00ff00" .. metrics.earlyReturn_borderAlreadyExists .. "|r |cff888888(saved CreateTexture)|r")
	print(" ")

	-- Expensive API calls
	local totalAttempts = metrics.calls_GetItemInfo + metrics.earlyReturn_cachedItemLink
	local itemLinkEfficiency = totalAttempts > 0 and (metrics.earlyReturn_cachedItemLink / totalAttempts * 100) or 0

	print("|cffFFD700Expensive API Calls:|r")
	print("  GetItemInfo():       " .. metrics.calls_GetItemInfo)
	print("  SetVertexColor():    " .. metrics.calls_SetVertexColor)
	print("  CreateTexture():     " .. metrics.calls_CreateTexture)
	print("  |cff00ff00Cache efficiency:  " .. string.format("%.1f%%", itemLinkEfficiency) .. "|r")
	print(" ")

	-- Quest detection
	print("|cffFFD700Quest Item Detection:|r")
	print("  Quest upgrades:      |cffffcc00" .. metrics.questUpgrades .. "|r |cff888888(white -> yellow)|r")
	print(" ")

	-- Color transitions
	print("|cffFFD700Color Transitions:|r")
	local qualityNames = {
		[0] = "None/Hidden",
		[1] = "|cffffffff White|r",
		[2] = "|cff1eff00Green|r",
		[3] = "|cff0070ddBlue|r",
		[4] = "|cffa335eePurple|r",
		[5] = "|cffff8000Orange|r",
		[99] = "|cffffcc00Quest|r"
	}

	local sortedFrom = {}
	for from in pairs(metrics.transitions) do
		table.insert(sortedFrom, from)
	end
	table.sort(sortedFrom)

	for _, from in ipairs(sortedFrom) do
		local fromName = qualityNames[from] or ("Quality " .. from)
		local sortedTo = {}
		for to in pairs(metrics.transitions[from]) do
			table.insert(sortedTo, to)
		end
		table.sort(sortedTo)

		for _, to in ipairs(sortedTo) do
			local toName = qualityNames[to] or ("Quality " .. to)
			local count = metrics.transitions[from][to]
			print(string.format("  %s -> %s: %d", fromName, toName, count))
		end
	end

end
