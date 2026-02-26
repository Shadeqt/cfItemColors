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

-- Quest objective cache (itemName → true), populated by Quest module
addon.questObjectiveCache = {}
addon.questObjectiveText = ""

-- Checks if an item is quest-related using API checks and quest log cache
local function checkQuestItem(itemName, itemClassId, itemType, bagId, bagItemButtonId)
	if addon.questObjectiveCache[itemName] then return true end
	if bagId and bagItemButtonId then
		local info = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)
		if info and (info.questID or info.isQuestItem) then return true end
	end
	-- Fallback: items classified as quest items by the game
	if itemClassId == Enum.ItemClass.Questitem or itemType == "Quest" then
		return true
	end
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
	if not itemIdOrLink then
		updateBorder(button, nil)
		applyQuestMarker(button, nil, nil)
		return
	end

	local itemName, _, itemQuality, _, _, itemType, _, _, _, _, _, itemClassId = GetItemInfo(itemIdOrLink)
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
	if itemQuality <= QUALITY_COMMON and checkQuestItem(itemName, itemClassId, itemType, bagId, bagItemButtonId) then
		itemQuality = QUEST_QUALITY
	end

	button.beginsQuest = nil
	updateBorder(button, itemQuality)
	applyQuestMarker(button, bagId, bagItemButtonId)
end
