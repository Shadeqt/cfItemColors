local _, addon = ...

-- Updates a single loot slot button
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	local lootItemLink = GetLootSlotLink(slotIndex)
	addon.applyQualityColor(lootSlotButton, lootItemLink)
end

hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)  -- Loot button updates
