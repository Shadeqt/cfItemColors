cfItemColors = {}

-- Performance counters
cfItemColors.counters = {
	applyQualityColor_called = 0,
	applyQualityColor_noItem = 0,
	applyQualityColor_noItem_borderExists = 0,
	applyQualityColor_borderCreated = 0,
	applyQualityColor_itemQualityNil = 0,
	applyQualityColor_questUpgraded = 0,
	applyQualityColor_borderShown = 0,
	applyQualityColor_borderHidden = 0,
	applyQualityColor_borderHidden_borderExists = 0,
	applyQualityColorWithQuestCheck_called = 0,
	applyQualityColorNoQuestCheck_called = 0,
	isQuestItem_called = 0,
	isQuestItem_typeMatch = 0,
	isQuestItem_classMatch = 0,
	isQuestItem_cacheMatch = 0,
	isQuestItem_misclassifiedMatch = 0,
	isQuestItem_noMatch = 0,
	createBorder_called = 0,
}

-- Shared dependencies
cfItemColors.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

cfItemColors.questObjectiveCache = {}

-- Module states
local questObjectiveCache = cfItemColors.questObjectiveCache

local QUALITY_COMMON    = 1 -- White
local QUALITY_UNCOMMON  = 2 -- Green

local QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
local QUALITY_QUEST = 99
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
local function isQuestItem(itemName, itemType, itemClassId)
	cfItemColors.counters.isQuestItem_called = cfItemColors.counters.isQuestItem_called + 1

	if itemType == "Quest" then
		cfItemColors.counters.isQuestItem_typeMatch = cfItemColors.counters.isQuestItem_typeMatch + 1
		return true
	end

	if itemClassId == 12 then
		cfItemColors.counters.isQuestItem_classMatch = cfItemColors.counters.isQuestItem_classMatch + 1
		return true
	end

	if questObjectiveCache[itemName] then
		cfItemColors.counters.isQuestItem_cacheMatch = cfItemColors.counters.isQuestItem_cacheMatch + 1
		return true
	end

	if MISCLASSIFIED_QUEST_ITEMS[itemName] then
		cfItemColors.counters.isQuestItem_misclassifiedMatch = cfItemColors.counters.isQuestItem_misclassifiedMatch + 1
		return true
	end

	cfItemColors.counters.isQuestItem_noMatch = cfItemColors.counters.isQuestItem_noMatch + 1
	return false
end

-- Creates and configures a custom border texture for a button
local function createCustomBorder(button)
	cfItemColors.counters.createBorder_called = cfItemColors.counters.createBorder_called + 1

	local customBorder = button:CreateTexture(nil, "OVERLAY")
	customBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	customBorder:SetTexCoord(0.225, 0.775, 0.225, 0.775)
	customBorder:SetBlendMode("ADD")
	customBorder:SetAlpha(0.8)

	local buttonName = button:GetName()
	local iconTexture = buttonName and _G[buttonName .. "IconTexture"]
	customBorder:SetAllPoints(iconTexture or button)

	customBorder:Hide()
	return customBorder
end

-- Core quality color application logic
local function applyQualityColor(button, itemIdOrLink, checkQuestItems)
	cfItemColors.counters.applyQualityColor_called = cfItemColors.counters.applyQualityColor_called + 1

	if not itemIdOrLink then
		cfItemColors.counters.applyQualityColor_noItem = cfItemColors.counters.applyQualityColor_noItem + 1
		if button.customBorder then
			cfItemColors.counters.applyQualityColor_noItem_borderExists = cfItemColors.counters.applyQualityColor_noItem_borderExists + 1
			button.customBorder:Hide()
		end
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then
		cfItemColors.counters.applyQualityColor_itemQualityNil = cfItemColors.counters.applyQualityColor_itemQualityNil + 1
		return
	end

	-- Upgrade quest items to special quality
	if itemQuality <= QUALITY_COMMON and checkQuestItems and isQuestItem(itemName, itemType, itemClassId) then
		cfItemColors.counters.applyQualityColor_questUpgraded = cfItemColors.counters.applyQualityColor_questUpgraded + 1
		itemQuality = QUALITY_QUEST
	end

	-- Apply or hide border based on quality
	if itemQuality >= QUALITY_UNCOMMON then
		-- Create border only when needed
		if not button.customBorder then
			cfItemColors.counters.applyQualityColor_borderCreated = cfItemColors.counters.applyQualityColor_borderCreated + 1
			button.customBorder = createCustomBorder(button)
		end
		cfItemColors.counters.applyQualityColor_borderShown = cfItemColors.counters.applyQualityColor_borderShown + 1
		local color = QUALITY_COLORS[itemQuality]
		button.customBorder:SetVertexColor(color.r, color.g, color.b)
		button.customBorder:Show()
	else
		cfItemColors.counters.applyQualityColor_borderHidden = cfItemColors.counters.applyQualityColor_borderHidden + 1
		if button.customBorder then
			cfItemColors.counters.applyQualityColor_borderHidden_borderExists = cfItemColors.counters.applyQualityColor_borderHidden_borderExists + 1
			button.customBorder:Hide()
		end
	end
end

-- Applies quality-colored border without quest detection
function cfItemColors.applyQualityColor(button, itemIdOrLink)
	cfItemColors.counters.applyQualityColorNoQuestCheck_called = cfItemColors.counters.applyQualityColorNoQuestCheck_called + 1
	local checkQuestItems = false
	applyQualityColor(button, itemIdOrLink, checkQuestItems)
end

-- Applies quality-colored border with quest item detection
function cfItemColors.applyQualityColorWithQuestCheck(button, itemIdOrLink)
	cfItemColors.counters.applyQualityColorWithQuestCheck_called = cfItemColors.counters.applyQualityColorWithQuestCheck_called + 1
	local checkQuestItems = true
	applyQualityColor(button, itemIdOrLink, checkQuestItems)
end

-- Callback invoked when quest objectives change (cache updated)
cfItemColors.onQuestObjectivesChanged = function() end

-- Slash command to display performance counters
SLASH_CFITEMS1 = "/cfitems"
SlashCmdList["CFITEMS"] = function(msg)
	if msg == "reset" then
		for k in pairs(cfItemColors.counters) do
			cfItemColors.counters[k] = 0
		end
		print("cfItemColors: Counters reset")
		return
	end

	local GREEN = "|cff00ff00"
	local RESET = "|r"

	print("=== cfItemColors Performance Counters ===")
	print(" ")
	print("Public API:")
	print("  With quest check:", cfItemColors.counters.applyQualityColorWithQuestCheck_called)
	print("  No quest check:", cfItemColors.counters.applyQualityColorNoQuestCheck_called)
	print(" ")
	print("applyQualityColor:")
	print("  Total calls:", cfItemColors.counters.applyQualityColor_called)
	print("  No item:", cfItemColors.counters.applyQualityColor_noItem, GREEN .. "[RETURN]" .. RESET)
	print("    (border exists):", cfItemColors.counters.applyQualityColor_noItem_borderExists)
	print("  Border created:", cfItemColors.counters.applyQualityColor_borderCreated)
	print("  ItemQuality nil:", cfItemColors.counters.applyQualityColor_itemQualityNil, GREEN .. "[RETURN]" .. RESET)
	print("  Quest upgraded:", cfItemColors.counters.applyQualityColor_questUpgraded)
	print("  Border shown:", cfItemColors.counters.applyQualityColor_borderShown)
	print("  Border hidden:", cfItemColors.counters.applyQualityColor_borderHidden)
	print("    (border exists):", cfItemColors.counters.applyQualityColor_borderHidden_borderExists)
	print(" ")
	print("isQuestItem:")
	print("  Total calls:", cfItemColors.counters.isQuestItem_called)
	print("  Type match:", cfItemColors.counters.isQuestItem_typeMatch, GREEN .. "[RETURN]" .. RESET)
	print("  Class match:", cfItemColors.counters.isQuestItem_classMatch, GREEN .. "[RETURN]" .. RESET)
	print("  Cache match:", cfItemColors.counters.isQuestItem_cacheMatch, GREEN .. "[RETURN]" .. RESET)
	print("  Misclassified match:", cfItemColors.counters.isQuestItem_misclassifiedMatch, GREEN .. "[RETURN]" .. RESET)
	print("  No match:", cfItemColors.counters.isQuestItem_noMatch, GREEN .. "[RETURN]" .. RESET)
	print(" ")
	print("createBorder:")
	print("  Total calls:", cfItemColors.counters.createBorder_called)
	print(" ")
	print("Use '/cfitems reset' to clear counters")
end
