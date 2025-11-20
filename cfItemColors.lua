local addon = cfItemColors

-- Shared dependencies
addon.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

addon.questObjectiveCache = {}

-- Event bus for quest cache changes
local questChangeListeners = {}

-- Quality constants
local QUALITY_COMMON = 1
local QUALITY_UNCOMMON = 2
local QUEST_QUALITY = 99 -- Custom quest item quality

-- Blizzard's global table containing RGB color values for each item quality tier
local QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
QUALITY_COLORS[QUEST_QUALITY] = {r = 1.0, g = 0.82, b = 0.0} -- Custom gold color for quest items

-- Creates or returns existing colored border texture overlay for an item button
local function createBorder(button)
	if button.customBorder then
		return button.customBorder
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

	button.customBorder = border
	return border
end

-- Updates border visibility and color based on item quality
local function updateBorder(button, itemQuality)
	if itemQuality and itemQuality >= QUALITY_UNCOMMON then
		local border = createBorder(button)
		local color = QUALITY_COLORS[itemQuality]
		border:SetVertexColor(color.r, color.g, color.b, 0.6)
		border:Show()
	elseif button.customBorder then
		button.customBorder:Hide()
	end
end

-- Hides quest marker on button
local function hideQuestMarker(button)
	if button.questMarker then
		button.questMarker:Hide()
	end
end

-- Applies quest marker overlay to container item buttons
local function applyQuestMarker(button, bagId, bagItemButtonId)
	if button.beginsQuest == false or not bagId or not bagItemButtonId then
		hideQuestMarker(button)
		return
	end

	local questInfo = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)

	if not questInfo or not questInfo.questID then
		button.beginsQuest = false
		hideQuestMarker(button)
		return
	end

	if not button.questMarker then
		button.questMarker = button:CreateTexture(nil, "OVERLAY")
		button.questMarker:SetSize(16, 16)
		button.questMarker:SetPoint("BOTTOMRIGHT", -2, 4)
	end

	local texture = questInfo.isActive and "Interface\\GossipFrame\\ActiveQuestIcon" or "Interface\\GossipFrame\\AvailableQuestIcon"
	button.questMarker:SetTexture(texture)
	button.beginsQuest = true
	button.questMarker:Show()
end

-- Applies quality-based border color to button or hides border for common items
function addon.applyQualityColor(button, itemIdOrLink, bagId, bagItemButtonId)
	if not itemIdOrLink then
		updateBorder(button, nil)
		applyQuestMarker(button, nil, nil)
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then return end

	-- Upgrade quest items to special quality
	local isQuestRelated = itemType == "Quest" or itemClassId == 12 or addon.questObjectiveCache[itemName]
	if itemQuality <= QUALITY_COMMON and isQuestRelated then
		itemQuality = QUEST_QUALITY
	end

	button.beginsQuest = nil
	updateBorder(button, itemQuality)
	applyQuestMarker(button, bagId, bagItemButtonId)
end

-- Registers callback to be notified when quest objectives change
addon.registerQuestChangeListener = function(callback)
	table.insert(questChangeListeners, callback)
end

-- Notifies all registered listeners that quest objectives have changed
addon.onQuestObjectivesChanged = function()
	for _, listener in ipairs(questChangeListeners) do
		listener()
	end
end
