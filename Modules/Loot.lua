local _, addon = ...

-- Updates a single loot slot button. The loot window exposes Blizzard's quest-item
-- flag per slot (GetLootSlotInfo's 7th return), so quest items light up gold here
-- without needing a copy in the bags — bag coords stay nil.
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	local lootItemLink = GetLootSlotLink(slotIndex)
	local isQuestItem = select(7, GetLootSlotInfo(slotIndex))
	addon.applyQualityColor(lootSlotButton, lootItemLink, isQuestItem == true)
end

hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)  -- Loot button updates
