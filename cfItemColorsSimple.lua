cfItemColors = {}

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
	if itemType == "Quest" then
		return true
	end

	if itemClassId == 12 then
		return true
	end

	if questObjectiveCache[itemName] then
		return true
	end

	if MISCLASSIFIED_QUEST_ITEMS[itemName] then
		return true
	end

	return false
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

-- Core quality color application logic
local function applyQualityColor(button, itemIdOrLink, checkQuestItems)
	if not itemIdOrLink then
		if button.customBorder then
			button.customBorder:Hide()
		end
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then
		return
	end

	-- Upgrade quest items to special quality
	if itemQuality <= QUALITY_COMMON and checkQuestItems and isQuestItem(itemName, itemType, itemClassId) then
		itemQuality = QUALITY_QUEST
	end

	-- Apply or hide border based on quality
	if itemQuality >= QUALITY_UNCOMMON then
		-- Create border only when needed
		if not button.customBorder then
			button.customBorder = createCustomBorder(button)
		end
		local color = QUALITY_COLORS[itemQuality]
		button.customBorder:SetVertexColor(color.r, color.g, color.b)
		button.customBorder:Show()
	else
		if button.customBorder then
			button.customBorder:Hide()
		end
	end
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
