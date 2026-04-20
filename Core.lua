local addon = cfItemColors

-- Shared dependencies
addon.EQUIPMENT_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
	"Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard"
}

-- Quality constants
local QUALITY_COMMON = 1
local QUALITY_UNCOMMON = 2
local QUEST_QUALITY = 99 -- Custom quest item quality

-- Quality color table using official API with lazy caching
local QUALITY_COLORS = {
	[QUEST_QUALITY] = {r = 1.0, g = 0.82, b = 0.0} -- Custom gold color for quest items
}
setmetatable(QUALITY_COLORS, {
	__index = function(self, quality)
		local r, g, b = C_Item.GetItemQualityColor(quality)
		if r then
			self[quality] = {r = r, g = g, b = b}
			return self[quality]
		end
	end
})

-- Quest item cache (itemID → boolean), lazily populated on bag scan
addon.questItemCache = {}

-- Checks if an item is quest-related using native Blizzard APIs
-- Questie_QuestItems.lua overrides this to add Questie integration
function addon.checkQuestItem(itemID, itemClassId, bagId, bagItemButtonId)
	local cached = addon.questItemCache[itemID]
	if cached ~= nil then return cached end

	-- activeQuestOnly requires Questie override; native check can't fulfill it
	if cfItemColorsDB.activeQuestOnly.enabled then return false end

	local isQuest = false

	if itemClassId == Enum.ItemClass.Questitem then
		isQuest = true
	end

	if not isQuest and bagId and bagItemButtonId then
		local info = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)
		if info and (info.isQuestItem or info.questID) then
			isQuest = true
		end
	end

	addon.questItemCache[itemID] = isQuest
	return isQuest
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
		or button.Icon or button.icon
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
	local questId = questInfo and questInfo.questID
	local isCompleted = questId and C_QuestLog.IsQuestFlaggedCompleted(questId)

	if not questId or isCompleted then
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
	if not button then return end

	if not itemIdOrLink then
		updateBorder(button, nil)
		applyQuestMarker(button, nil, nil)
		return
	end

	-- Fast path: GetItemInfoInstant is synchronous and gives us itemID + classID without async loading
	local itemID, _, _, _, _, itemClassId = C_Item.GetItemInfoInstant(itemIdOrLink)
	if not itemID then return end

	local itemQuality = C_Item.GetItemQualityByID(itemIdOrLink)
	if not itemQuality then
		-- Item data not cached yet - wait for it to load, then retry
		local item = type(itemIdOrLink) == "number"
			and Item:CreateFromItemID(itemIdOrLink)
			or Item:CreateFromItemLink(itemIdOrLink)
		if item and not item:IsItemEmpty() then
			item:ContinueOnItemLoad(function()
				C_Timer.After(0, function()
					addon.applyQualityColor(button, itemIdOrLink, bagId, bagItemButtonId)
				end)
			end)
		end
		return
	end

	-- Upgrade quest items to special quality
	if itemQuality <= QUALITY_COMMON and addon.checkQuestItem(itemID, itemClassId, bagId, bagItemButtonId) then
		itemQuality = QUEST_QUALITY
	end

	button.beginsQuest = nil
	updateBorder(button, itemQuality)
	applyQuestMarker(button, bagId, bagItemButtonId)
end
