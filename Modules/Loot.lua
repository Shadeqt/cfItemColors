local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized API calls
local _G = _G
local GetLootSlotLink = GetLootSlotLink
local hooksecurefunc = hooksecurefunc

-- Apply quality color to a single loot slot button
local function UpdateLootSlotButton(slotIndex)
	local lootSlotButton = _G["LootButton" .. slotIndex]
	if not lootSlotButton then return end

	local lootItemLink = GetLootSlotLink(slotIndex)
	applyQualityColorWithQuestCheck(lootSlotButton, lootItemLink)
end

-- Hook loot button updates
hooksecurefunc("LootFrame_UpdateButton", UpdateLootSlotButton)
