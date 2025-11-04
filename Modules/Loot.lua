-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local LOOTFRAME_NUMBUTTONS = LOOTFRAME_NUMBUTTONS -- 20, maximum loot slots

-- Module states
local lootButtonCache = {}

-- Pre-cache loot frames at module load
for i = 1, LOOTFRAME_NUMBUTTONS do
	lootButtonCache[i] = _G["LootButton" .. i]
end

-- Updates a single loot slot button with quality color
local function updateLootSlotButton(slotIndex)
	local lootSlotButton = lootButtonCache[slotIndex]
	local lootItemLink = GetLootSlotLink(slotIndex)
	applyQualityColor(lootSlotButton, lootItemLink)
end

-- Hook loot button updates
hooksecurefunc("LootFrame_UpdateButton", updateLootSlotButton)
