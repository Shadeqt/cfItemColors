local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.LOOT].enabled then return end

-- Updates a single loot slot button
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	local lootItemLink = GetLootSlotLink(slotIndex)
	addon.applyQualityColor(lootSlotButton, lootItemLink)
end

hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)  -- Loot button updates
