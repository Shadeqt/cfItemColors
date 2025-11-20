local addon = cfItemColors

-- Shared dependencies
addon.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

addon.questObjectiveCache = {}
addon.questCacheVersion = 0

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

	if addon.questObjectiveCache[itemName] then
		return true
	end

	return false
end

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

-- Shows colored border on item button, using native IconBorder if available
local function showBorder(button, itemQuality)
	-- Try native IconBorder first
	-- if button.IconBorder then
	-- 	local color = QUALITY_COLORS[itemQuality]
	-- 	button.IconBorder:SetVertexColor(color.r, color.g, color.b, 1)
	-- 	button.IconBorder:Show()
	-- 	return
	-- end

	-- Fallback to custom border
	local customBorder = createBorder(button)
	local color = QUALITY_COLORS[itemQuality]
	customBorder:SetVertexColor(color.r, color.g, color.b, 0.6)
	customBorder:Show()
end

-- Hides border and clears quality state from button
local function hideBorder(button)
	-- Hide native IconBorder if it exists
	if button.IconBorder then
		button.IconBorder:Hide()
	end

	-- Hide custom border if it exists
	if button.customBorder then
		button.customBorder:Hide()
	end
end

-- Applies quest marker overlay to container item buttons
local function applyQuestMarker(button, bagId, bagItemButtonId)
	if button.beginsQuest == false then return end

	if not bagId or not bagItemButtonId then
		if button.questMarker then
			button.questMarker:Hide()
		end
		return
	end

	local questInfo = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)

	if not questInfo or not questInfo.questID then
		button.beginsQuest = false
		if button.questMarker then
			button.questMarker:Hide()
		end
		return
	end

	if not button.questMarker then
		button.questMarker = button:CreateTexture(nil, "OVERLAY")
		button.questMarker:SetSize(16, 16)
		button.questMarker:SetPoint("BOTTOMRIGHT", -2, 4)
		button.questMarker:Hide()
	end

	if questInfo.isActive then
		button.questMarker:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
	else
		button.questMarker:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
	end

	button.beginsQuest = true
	button.questMarker:Show()
end

-- Applies quality-based border color to button or hides border for common items
function addon.applyQualityColor(button, itemIdOrLink, bagId, bagItemButtonId)
	if not itemIdOrLink then
		hideBorder(button)
		button.itemIdOrLink = nil
		if button.questMarker then
			button.questMarker:Hide()
		end
		return
	end

	if button.itemIdOrLink == itemIdOrLink and button.questCacheVersion == addon.questCacheVersion then
		-- Item hasn't changed, but border may have been hidden when bag was closed
		-- Re-show the border if quality is high enough (use cachedQuality since itemQuality may be nil)
		if button.cachedQuality and button.cachedQuality >= 2 then
			showBorder(button, button.cachedQuality)
		end
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then return end

	button.itemIdOrLink = itemIdOrLink
	button.questCacheVersion = addon.questCacheVersion
	button.beginsQuest = nil

	-- Upgrade quest items to special quality (99 = custom quest quality)
	if itemQuality <= 1 and isQuestItem(itemType, itemClassId, itemName) then
		itemQuality = 99
	end

	-- Cache the quality separately since button.itemQuality may be reset by WoW's UI
	button.cachedQuality = itemQuality

	-- Apply or hide border based on quality (2+ = uncommon or better)
	if itemQuality >= 2 then
		showBorder(button, itemQuality)
	else
		hideBorder(button)
	end

	-- Apply quest marker if bag context is provided
	if bagId and bagItemButtonId then
		applyQuestMarker(button, bagId, bagItemButtonId)
	end
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
