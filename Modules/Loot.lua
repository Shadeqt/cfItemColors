-- Module enable check
local enabled = cfItemColors.GetModuleState(cfItemColors.MODULES.LOOT)
if not enabled then return end

-- Updates a single loot slot button
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	local lootItemLink = GetLootSlotLink(slotIndex)
	cfItemColors.applyQualityColor(lootSlotButton, lootItemLink)
end

hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)  -- Loot button updates
