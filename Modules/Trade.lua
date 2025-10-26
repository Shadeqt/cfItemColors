local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor

-- Cache API calls for performance
local _GetTradePlayerItemLink = GetTradePlayerItemLink
local _GetTradeTargetItemLink = GetTradeTargetItemLink
local _CreateFrame = CreateFrame
local _G = _G

-- WoW Constants
local TRADE_SLOTS_PER_PLAYER = MAX_TRADE_ITEMS -- Max trade slots per player (7)

-- Cache button references for both players
local playerTradeButtons = {}
local targetTradeButtons = {}

-- Initialize button caches
for i = 1, TRADE_SLOTS_PER_PLAYER do
	playerTradeButtons[i] = _G["TradePlayerItem" .. i .. "ItemButton"]
	targetTradeButtons[i] = _G["TradeRecipientItem" .. i .. "ItemButton"]
end

-- Update player's trade slot colors
local function updatePlayerTradeSlot(slotIndex)
	local button = playerTradeButtons[slotIndex]
	if button then
		local itemLink = _GetTradePlayerItemLink(slotIndex)
		applyQualityColor(button, itemLink)
	end
end

-- Update target's trade slot colors
local function updateTargetTradeSlot(slotIndex)
	local button = targetTradeButtons[slotIndex]
	if button then
		local itemLink = _GetTradeTargetItemLink(slotIndex)
		applyQualityColor(button, itemLink)
	end
end

-- Update all trade slots for both players
local function updateAllTradeSlots()
	for i = 1, TRADE_SLOTS_PER_PLAYER do
		updatePlayerTradeSlot(i)
		updateTargetTradeSlot(i)
	end
end

-- Clear all trade slot colors
local function clearAllTradeSlots()
	for i = 1, TRADE_SLOTS_PER_PLAYER do
		local playerButton = playerTradeButtons[i]
		local targetButton = targetTradeButtons[i]
		
		if playerButton then
			applyQualityColor(playerButton, nil)
		end
		if targetButton then
			applyQualityColor(targetButton, nil)
		end
	end
end

-- Event frame for trade window monitoring
local eventFrame = _CreateFrame("Frame")
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
		if slotIndex and slotIndex >= 1 and slotIndex <= TRADE_SLOTS_PER_PLAYER then
			updatePlayerTradeSlot(slotIndex)
		end
		
	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		-- Target's item changed in specific slot
		if slotIndex and slotIndex >= 1 and slotIndex <= TRADE_SLOTS_PER_PLAYER then
			updateTargetTradeSlot(slotIndex)
		end
		
	-- TRADE_CLOSED event removed - no need to clear colors since we recolor on open
	end
end)