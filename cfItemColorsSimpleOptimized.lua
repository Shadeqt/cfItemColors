cfItemColors = {}

-- Shared dependencies
cfItemColors.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

cfItemColors.questObjectiveCache = {}

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
		return button.border 
	end

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

local function showBorder(button, color)
	button.border = createBorder(button)
	button.border:SetVertexColor(color.r, color.g, color.b)
	button.border:Show()
end

local function hideBorder(button)
	if button.border then
		button.border:Hide()
	end
end

-- Core quality color application logic
local function applyQualityColor(button, itemIdOrLink, checkQuestItems)
	if not itemIdOrLink then
		hideBorder(button)
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then return end

	-- Upgrade quest items to special quality
	if itemQuality <= QUALITY_COMMON and checkQuestItems and isQuestItem(itemType, itemClassId, itemName) then
		itemQuality = QUALITY_QUEST
	end

	-- Apply or hide border based on quality
	if itemQuality >= QUALITY_UNCOMMON then
		local color = QUALITY_COLORS[itemQuality]
		showBorder(button, color)
	else
		hideBorder(button)
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
