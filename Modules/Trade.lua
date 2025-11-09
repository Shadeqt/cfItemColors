-- Module enable check
local enabled = cfItemColors.Compatibility.ShouldModuleLoad("Trade")
if not enabled then return end

-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local MAX_TRADE_ITEMS = MAX_TRADE_ITEMS -- 7, trade slots per player

local function updatePlayerTradeSlot(slotIndex)
	local button = _G["TradePlayerItem" .. slotIndex .. "ItemButton"]
	local itemLink = GetTradePlayerItemLink(slotIndex)
	applyQualityColor(button, itemLink)
end

-- Update target's trade slot colors
local function updateTargetTradeSlot(slotIndex)
	local button = _G["TradeRecipientItem" .. slotIndex .. "ItemButton"]
	local itemLink = GetTradeTargetItemLink(slotIndex)
	applyQualityColor(button, itemLink)
end

-- Update all trade slots for both players
local function updateAllTradeSlots()
	for i = 1, MAX_TRADE_ITEMS do
		updatePlayerTradeSlot(i)
		updateTargetTradeSlot(i)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRADE_SHOW")
eventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
eventFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, slotIndex)
	if event == "TRADE_SHOW" then
		updateAllTradeSlots()
	elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
		updatePlayerTradeSlot(slotIndex)
	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		updateTargetTradeSlot(slotIndex)
	end
end)
