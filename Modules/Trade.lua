-- Module enable check
local enabled = cfItemColors.GetModuleState(cfItemColors.MODULES.TRADE)
if not enabled then return end

-- WoW constants
local MAX_TRADE_ITEMS = MAX_TRADE_ITEMS -- 7, trade slots per player

-- Updates a single player trade slot
local function updatePlayerTradeSlot(slotIndex)
	local button = _G["TradePlayerItem" .. slotIndex .. "ItemButton"]
	local itemLink = GetTradePlayerItemLink(slotIndex)
	cfItemColors.applyQualityColor(button, itemLink)
end

-- Updates a single target trade slot
local function updateTargetTradeSlot(slotIndex)
	local button = _G["TradeRecipientItem" .. slotIndex .. "ItemButton"]
	local itemLink = GetTradeTargetItemLink(slotIndex)
	cfItemColors.applyQualityColor(button, itemLink)
end

-- Updates all trade slots for both players
local function updateAllTradeSlots()
	for i = 1, MAX_TRADE_ITEMS do
		updatePlayerTradeSlot(i)
		updateTargetTradeSlot(i)
	end
end

-- Update trade slot colors on window open and item changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRADE_SHOW")  				-- Trade window opened
eventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")  	-- Player item changed
eventFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")  	-- Target item changed
eventFrame:SetScript("OnEvent", function(_, event, slotIndex)
	if event == "TRADE_SHOW" then
		updateAllTradeSlots()
	elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
		updatePlayerTradeSlot(slotIndex)
	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		updateTargetTradeSlot(slotIndex)
	end
end)
