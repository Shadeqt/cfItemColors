cfItemColors = {}

-- SavedVariables initialization
if not cfItemColorsDB then
	cfItemColorsDB = {
		enableBags = true,
		enableBank = true,
		enableCharacter = true,
		enableInspect = true,
		enableLoot = true,
		enableMailbox = true,
		enableMerchant = true,
		enableProfessions = true,
		enableQuest = true,
		enableQuestObjective = true,
		enableTrade = true,
	}
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

-- Determines if an item is quest-related based on type, class, or cache
local function isQuestItem(itemType, itemClassId, itemName)
	if itemType == "Quest" or itemClassId == 12 then
		return true
	end

	if questObjectiveCache[itemName] then
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

local function hideBorder(button)
	if button.border then
		button.border:Hide()
	end

	button.itemQuality = nil
end

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

	-- Upgrade quest items to special quality
	if itemQuality <= QUALITY_COMMON and isQuestItem(itemType, itemClassId, itemName) then
		itemQuality = QUALITY_QUEST
	end

	-- Apply or hide border based on quality
	if itemQuality >= QUALITY_UNCOMMON then
		showBorder(button, itemQuality)
	else
		hideBorder(button)
	end
end

-- Event bus for quest cache changes
local questChangeListeners = {}

cfItemColors.registerQuestChangeListener = function(callback)
	table.insert(questChangeListeners, callback)
end

cfItemColors.onQuestObjectivesChanged = function()
	for _, listener in ipairs(questChangeListeners) do
		listener()
	end
end
