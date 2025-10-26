local addon = cfItemColors
local applyQualityColorWithQuestCheck = addon.applyQualityColorWithQuestCheck

-- Cache API calls for performance
local _GetNumAuctionItems = GetNumAuctionItems
local _GetAuctionItemLink = GetAuctionItemLink
local _GetAuctionSellItemInfo = GetAuctionSellItemInfo
local _CreateFrame = CreateFrame
local _G = _G

-- Constants
local NUM_BROWSE_TO_DISPLAY = NUM_BROWSE_TO_DISPLAY or 8
local NUM_BIDS_TO_DISPLAY = NUM_BIDS_TO_DISPLAY or 8
local NUM_AUCTIONS_TO_DISPLAY = NUM_AUCTIONS_TO_DISPLAY or 8

-- Cache button references for all three tabs
local browseButtonCache = {}
local bidButtonCache = {}
local auctionButtonCache = {}
local sellItemButton = nil

-- Initialize button caches
for i = 1, NUM_BROWSE_TO_DISPLAY do
	browseButtonCache[i] = _G["BrowseButton" .. i]
end

for i = 1, NUM_BIDS_TO_DISPLAY do
	bidButtonCache[i] = _G["BidButton" .. i]
end

for i = 1, NUM_AUCTIONS_TO_DISPLAY do
	auctionButtonCache[i] = _G["AuctionsButton" .. i]
end

-- Sell item button (on Auctions tab)
sellItemButton = _G["AuctionsItemButton"]

-- Update browse tab item colors
local function updateBrowseItems()
	local numItems = _GetNumAuctionItems("list")
	
	for i = 1, NUM_BROWSE_TO_DISPLAY do
		local button = browseButtonCache[i]
		if button then
			if i <= numItems then
				local itemLink = _GetAuctionItemLink("list", i)
				applyQualityColorWithQuestCheck(button, itemLink)
			else
				applyQualityColorWithQuestCheck(button, nil)
			end
		end
	end
end

-- Update bids tab item colors
local function updateBidItems()
	local numItems = _GetNumAuctionItems("bidder")
	
	for i = 1, NUM_BIDS_TO_DISPLAY do
		local button = bidButtonCache[i]
		if button then
			if i <= numItems then
				local itemLink = _GetAuctionItemLink("bidder", i)
				applyQualityColorWithQuestCheck(button, itemLink)
			else
				applyQualityColorWithQuestCheck(button, nil)
			end
		end
	end
end

-- Update auctions tab item colors
local function updateAuctionItems()
	local numItems = _GetNumAuctionItems("owner")
	
	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
		local button = auctionButtonCache[i]
		if button then
			if i <= numItems then
				local itemLink = _GetAuctionItemLink("owner", i)
				applyQualityColorWithQuestCheck(button, itemLink)
			else
				applyQualityColorWithQuestCheck(button, nil)
			end
		end
	end
end

-- Update sell item slot color
local function updateSellItem()
	if sellItemButton then
		local name, texture, count, quality, canUse, price = _GetAuctionSellItemInfo()
		if name and quality then
			-- Create a simple item reference using the name for the color system
			-- The applyQualityColorWithQuestCheck function can handle item names
			applyQualityColorWithQuestCheck(sellItemButton, name)
		else
			applyQualityColorWithQuestCheck(sellItemButton, nil)
		end
	end
end

-- Clear all auction house colors
local function clearAllAuctionHouseColors()
	-- Clear browse items
	for i = 1, NUM_BROWSE_TO_DISPLAY do
		local button = browseButtonCache[i]
		if button then
			applyQualityColorWithQuestCheck(button, nil)
		end
	end
	
	-- Clear bid items
	for i = 1, NUM_BIDS_TO_DISPLAY do
		local button = bidButtonCache[i]
		if button then
			applyQualityColorWithQuestCheck(button, nil)
		end
	end
	
	-- Clear auction items
	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
		local button = auctionButtonCache[i]
		if button then
			applyQualityColorWithQuestCheck(button, nil)
		end
	end
	
	-- Clear sell item
	if sellItemButton then
		applyQualityColorWithQuestCheck(sellItemButton, nil)
	end
end

-- Event frame for auction house monitoring
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
eventFrame:RegisterEvent("AUCTION_BIDDER_LIST_UPDATE")
eventFrame:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
eventFrame:RegisterEvent("NEW_AUCTION_UPDATE")


-- Debounce timer for AUCTION_ITEM_LIST_UPDATE spam
local lastListUpdate = 0
local DEBOUNCE_DELAY = 0.5

-- Handle auction house events
eventFrame:SetScript("OnEvent", function(_, event)
	if event == "AUCTION_HOUSE_SHOW" then
		-- Auction house opened - update all tabs
		updateBrowseItems()
		updateBidItems()
		updateAuctionItems()
		updateSellItem()
		
	elseif event == "AUCTION_ITEM_LIST_UPDATE" then
		-- Browse list updated - debounce spam (fires 1-8x per search)
		local now = GetTime()
		if now - lastListUpdate >= DEBOUNCE_DELAY then
			lastListUpdate = now
			updateBrowseItems()
		end
		
	elseif event == "AUCTION_BIDDER_LIST_UPDATE" then
		-- Bids list updated
		updateBidItems()
		
	elseif event == "AUCTION_OWNED_LIST_UPDATE" then
		-- Auctions list updated
		updateAuctionItems()
		
	elseif event == "NEW_AUCTION_UPDATE" then
		-- Sell item updated
		updateSellItem()
		
	-- AUCTION_HOUSE_CLOSED event removed - no need to clear colors since we recolor on open
	end
end)