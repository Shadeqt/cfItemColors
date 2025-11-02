cfItemColors = {}

-- Shared dependencies
cfItemColors.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard", "Ammo"
}

cfItemColors.questObjectiveCache = {}

-- Module states
local questObjectiveCache = cfItemColors.questObjectiveCache

local QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
QUALITY_COLORS[99] = {r = 1.0, g = 0.82, b = 0.0}

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

-- Creates and configures a custom border texture for a button
local function createCustomBorder(button)
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

-- Hides border and clears cached item data
local function clearButtonBorder(button)
	button.customBorder:Hide()
	button.cachedItemLink = nil
	button.cachedQuality = nil
end

-- Determines if an item is quest-related based on type, class, or cache
local function isQuestItem(itemName, itemType, itemClassId)
	return 	itemType == "Quest" or
			itemClassId == 12 or
			questObjectiveCache[itemName] or
			MISCLASSIFIED_QUEST_ITEMS[itemName]
end

-- Core quality color application logic
local function applyQualityColor(button, itemIdOrLink, checkQuestItems)
	-- Early exit if item hasn't changed and cache is valid
	if button.cachedItemLink == itemIdOrLink and button.cachedQuality then return end

	-- Create border if needed
	if not button.customBorder then
		button.customBorder = createCustomBorder(button)
	end

	-- Clear border if no item
	if not itemIdOrLink then
		clearButtonBorder(button)
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then return end

	-- Upgrade quest items to special quality
	local qualityLevel = itemQuality
	if checkQuestItems and itemQuality <= 1 and isQuestItem(itemName, itemType, itemClassId) then
		qualityLevel = 99
	end

	-- Early exit if effective quality unchanged
	if button.cachedQuality == qualityLevel then
		button.cachedItemLink = itemIdOrLink
		return
	end

	-- Apply or hide border based on quality
	if qualityLevel >= 2 then
		local color = QUALITY_COLORS[qualityLevel]
		button.customBorder:SetVertexColor(color.r, color.g, color.b)
		button.customBorder:Show()
	else
		button.customBorder:Hide()
	end

	-- Cache results
	button.cachedItemLink = itemIdOrLink
	button.cachedQuality = qualityLevel
end

-- Applies quality-colored border without quest detection
function cfItemColors.applyQualityColor(button, itemIdOrLink)
	local checkQuestItems = false
	applyQualityColor(button, itemIdOrLink, checkQuestItems)
end

-- Applies quality-colored border with quest item detection
function cfItemColors.applyQualityColorWithQuestCheck(button, itemIdOrLink)
	local checkQuestItems = true
	applyQualityColor(button, itemIdOrLink, checkQuestItems)
end

-- Callback invoked when quest objectives change (cache updated)
cfItemColors.onQuestObjectivesChanged = function() end
