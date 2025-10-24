local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized API calls
local _GetLootSlotLink = GetLootSlotLink

-- Apply quality color to a single loot slot button
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	if not lootSlotButton then return end

	local lootItemLink = _GetLootSlotLink(slotIndex)
	applyQualityColorWithQuestCheck(lootSlotButton, lootItemLink)
end

-- Hook loot button updates
hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)
