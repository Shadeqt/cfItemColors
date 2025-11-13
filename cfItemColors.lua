cfItemColors = {}

-- Shared dependencies
cfItemColors.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

cfItemColors.questObjectiveCache = {}
cfItemColors.questCacheVersion = 0

-- Event bus for quest cache changes
local questChangeListeners = {}

-- Blizzard's global table containing RGB color values for each item quality tier
local QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
QUALITY_COLORS[99] = {r = 1.0, g = 0.82, b = 0.0} -- Custom gold color for quest items

-- Determines if an item is quest-related based on type, class, or cache
local function isQuestItem(itemType, itemClassId, itemName)
	if itemType == "Quest" or itemClassId == 12 then
		return true
	end

	if cfItemColors.questObjectiveCache[itemName] then
		return true
	end

	return false
end

-- Creates or returns existing colored border texture overlay for an item button
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

-- Shows colored border on item button based on quality
local function showBorder(button, itemQuality)
	if button.itemQuality == itemQuality then
		return
	end

	button.border = createBorder(button)

	local color = QUALITY_COLORS[itemQuality]
	button.border:SetVertexColor(color.r, color.g, color.b)
	button.border:Show()

	button.itemQuality = itemQuality
end

-- Hides border and clears quality state from button
local function hideBorder(button)
	if button.border then
		button.border:Hide()
	end

	button.itemQuality = nil
end

-- Applies quality-based border color to button or hides border for common items
function cfItemColors.applyQualityColor(button, itemIdOrLink)
	if not itemIdOrLink then
		hideBorder(button)
		button.itemIdOrLink = nil
		return
	end

	if button.itemIdOrLink == itemIdOrLink and button.questCacheVersion == cfItemColors.questCacheVersion then
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then
		return
	end

	button.itemIdOrLink = itemIdOrLink
	button.questCacheVersion = cfItemColors.questCacheVersion

	-- Upgrade quest items to special quality (99 = custom quest quality)
	if itemQuality <= 1 and isQuestItem(itemType, itemClassId, itemName) then
		itemQuality = 99
	end

	-- Apply or hide border based on quality (2+ = uncommon or better)
	if itemQuality >= 2 then
		showBorder(button, itemQuality)
	else
		hideBorder(button)
	end
end

-- Registers callback to be notified when quest objectives change
cfItemColors.registerQuestChangeListener = function(callback)
	table.insert(questChangeListeners, callback)
end

-- Notifies all registered listeners that quest objectives have changed
cfItemColors.onQuestObjectivesChanged = function()
	for _, listener in ipairs(questChangeListeners) do
		listener()
	end
end
