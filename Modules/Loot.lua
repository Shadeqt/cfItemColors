-- Shared dependencies
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	if not lootSlotButton then return end

	local lootItemLink = GetLootSlotLink(slotIndex)
	applyQualityColorWithQuestCheck(lootSlotButton, lootItemLink)
end

-- Hook loot button updates
hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)
