-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- Updates a single loot slot button with quality color
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	local lootItemLink = GetLootSlotLink(slotIndex)
	applyQualityColor(lootSlotButton, lootItemLink)
end

-- Hook loot button updates
hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)
