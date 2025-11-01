-- WoW API Constants
local MAX_TRADE_ITEMS = MAX_TRADE_ITEMS -- 6 (trade slots per player)

-- Cache button references for both players
local playerTradeButtons = {}
local targetTradeButtons = {}

-- Initialize button caches
for i = 1, MAX_TRADE_ITEMS do
	playerTradeButtons[i] = _G["TradePlayerItem" .. i .. "ItemButton"]
	targetTradeButtons[i] = _G["TradeRecipientItem" .. i .. "ItemButton"]
end

-- Update player's trade slot colors
local function updatePlayerTradeSlot(slotIndex)
	local button = playerTradeButtons[slotIndex]
	if button then
		local itemLink = GetTradePlayerItemLink(slotIndex)
		cfItemColors.applyQualityColor(button, itemLink)
	end
end

-- Update target's trade slot colors
local function updateTargetTradeSlot(slotIndex)
	local button = targetTradeButtons[slotIndex]
	if button then
		local itemLink = GetTradeTargetItemLink(slotIndex)
		cfItemColors.applyQualityColor(button, itemLink)
	end
end

-- Update all trade slots for both players
local function updateAllTradeSlots()
	for i = 1, MAX_TRADE_ITEMS do
		updatePlayerTradeSlot(i)
		updateTargetTradeSlot(i)
	end
end

-- Clear all trade slot colors
local function clearAllTradeSlots()
	for i = 1, MAX_TRADE_ITEMS do
		local playerButton = playerTradeButtons[i]
		local targetButton = targetTradeButtons[i]

		if playerButton then
			cfItemColors.applyQualityColor(playerButton, nil)
		end
		if targetButton then
			cfItemColors.applyQualityColor(targetButton, nil)
		end
	end
end

-- Event frame for trade window monitoring
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRADE_SHOW")
eventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
eventFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")


-- Handle trade events
eventFrame:SetScript("OnEvent", function(_, event, slotIndex)
	if event == "TRADE_SHOW" then
		-- Trade window opened - update all slots
		updateAllTradeSlots()
		
	elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
		-- Player's item changed in specific slot
		if slotIndex and slotIndex >= 1 and slotIndex <= MAX_TRADE_ITEMS then
			updatePlayerTradeSlot(slotIndex)
		end

	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		-- Target's item changed in specific slot
		if slotIndex and slotIndex >= 1 and slotIndex <= MAX_TRADE_ITEMS then
			updateTargetTradeSlot(slotIndex)
		end
		
	-- TRADE_CLOSED event removed - no need to clear colors since we recolor on open
	end
end)