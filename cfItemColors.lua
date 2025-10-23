cfItemColors = {}
local addon = cfItemColors

-- Localized API calls
local _G = _G
local GetItemInfo = GetItemInfo

-- Quality color configuration
local QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
QUALITY_COLORS[99] = {r = 1.0, g = 0.82, b = 0.0}

-- Equipment slot names
addon.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard", "Ammo"
}

-- Create custom border texture for button
local function CreateCustomBorder(button)
	local customBorder = button:CreateTexture(nil, "OVERLAY")
	customBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	customBorder:SetTexCoord(0.25, 0.75, 0.25, 0.75)
	customBorder:SetBlendMode("ADD")
	customBorder:SetAlpha(0.8)

	local buttonName = button:GetName()
	local iconTexture = buttonName and _G[buttonName .. "IconTexture"]
	customBorder:SetAllPoints(iconTexture or button)

	customBorder:Hide()
	return customBorder
end

-- Clear button border and cache
local function ClearButtonBorder(button)
	button.customBorder:Hide()
	button.cachedItemLink = nil
	button.cachedQuality = nil
end

-- Core quality color application logic
local function ApplyQualityColorInternal(button, itemIdOrLink, checkQuestObjectives)
	-- Early exit if item hasn't changed
	if button.cachedItemLink == itemIdOrLink then return end

	-- Create border if needed
	if not button.customBorder then
		button.customBorder = CreateCustomBorder(button)
	end

	-- Clear border if no item
	if not itemIdOrLink then
		ClearButtonBorder(button)
		return
	end

	-- Get item info
	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
	if not itemQuality then return end

	-- Early exit if quality unchanged
	if button.cachedQuality == itemQuality then
		button.cachedItemLink = itemIdOrLink
		return
	end

	-- Determine quality level (with quest check if needed)
	local qualityLevel = itemQuality
	if checkQuestObjectives then
		local isQuestItem = itemQuality <= 1 and (itemType == "Quest" or itemClassId == 12 or addon.IsQuestObjective(itemName))
		qualityLevel = isQuestItem and 99 or itemQuality
	end

	-- Apply border color for quality 2+ items
	if qualityLevel >= 2 then
		local qualityColor = QUALITY_COLORS[qualityLevel]
		button.customBorder:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b)
		button.customBorder:Show()
	else
		button.customBorder:Hide()
	end

	-- Cache the item link and quality
	button.cachedItemLink = itemIdOrLink
	button.cachedQuality = itemQuality
end

-- Apply quality-colored border (no quest detection)
function addon.ApplyQualityColor(button, itemIdOrLink)
	ApplyQualityColorInternal(button, itemIdOrLink, false)
end

-- Apply quality-colored border with quest objective detection
function addon.ApplyQualityColorWithQuestCheck(button, itemIdOrLink)
	ApplyQualityColorInternal(button, itemIdOrLink, true)
end
