-- WoW API Constants
local NUM_BROWSE_TO_DISPLAY = NUM_BROWSE_TO_DISPLAY -- 8 (browse tab items per page)
local NUM_BIDS_TO_DISPLAY = NUM_BIDS_TO_DISPLAY -- 8 (bids tab items per page)
local NUM_AUCTIONS_TO_DISPLAY = NUM_AUCTIONS_TO_DISPLAY -- 8 (auctions tab items per page)

-- Cache button references for all three tabs
local browseButtonCache = {}
local bidButtonCache = {}
local auctionButtonCache = {}
local sellItemButton = nil

-- Initialize button caches
for i = 1, (NUM_BROWSE_TO_DISPLAY or 8) do
	browseButtonCache[i] = _G["BrowseButton" .. i]
end

for i = 1, (NUM_BIDS_TO_DISPLAY or 8) do
	bidButtonCache[i] = _G["BidButton" .. i]
end

for i = 1, (NUM_AUCTIONS_TO_DISPLAY or 8) do
	auctionButtonCache[i] = _G["AuctionsButton" .. i]
end

-- Sell item button (on Auctions tab)
sellItemButton = _G["AuctionsItemButton"]

-- Update browse tab item colors
local function updateBrowseItems()
	local numItems = GetNumAuctionItems("list")

	for i = 1, (NUM_BROWSE_TO_DISPLAY or 8) do
		local button = browseButtonCache[i]
		if button then
			if i <= numItems then
				local itemLink = GetAuctionItemLink("list", i)
				cfItemColors.applyQualityColor(button, itemLink)
			else
				cfItemColors.applyQualityColor(button, nil)
			end
		end
	end
end

-- Update bids tab item colors
local function updateBidItems()
	local numItems = GetNumAuctionItems("bidder")

	for i = 1, (NUM_BIDS_TO_DISPLAY or 8) do
		local button = bidButtonCache[i]
		if button then
			if i <= numItems then
				local itemLink = GetAuctionItemLink("bidder", i)
				cfItemColors.applyQualityColor(button, itemLink)
			else
				cfItemColors.applyQualityColor(button, nil)
			end
		end
	end
end

-- Update auctions tab item colors
local function updateAuctionItems()
	local numItems = GetNumAuctionItems("owner")

	for i = 1, (NUM_AUCTIONS_TO_DISPLAY or 8) do
		local button = auctionButtonCache[i]
		if button then
			if i <= numItems then
				local itemLink = GetAuctionItemLink("owner", i)
				cfItemColors.applyQualityColor(button, itemLink)
			else
				cfItemColors.applyQualityColor(button, nil)
			end
		end
	end
end

-- Update sell item slot color
local function updateSellItem()
	if sellItemButton then
		local name, texture, count, quality, canUse, price = GetAuctionSellItemInfo()
		if name and quality then
			-- Create a simple item reference using the name for the color system
			cfItemColors.applyQualityColor(sellItemButton, name)
		else
			cfItemColors.applyQualityColor(sellItemButton, nil)
		end
	end
end

-- Clear all auction house colors
local function clearAllAuctionHouseColors()
	-- Clear browse items
	for i = 1, (NUM_BROWSE_TO_DISPLAY or 8) do
		local button = browseButtonCache[i]
		if button then
			cfItemColors.applyQualityColor(button, nil)
		end
	end

	-- Clear bid items
	for i = 1, (NUM_BIDS_TO_DISPLAY or 8) do
		local button = bidButtonCache[i]
		if button then
			cfItemColors.applyQualityColor(button, nil)
		end
	end

	-- Clear auction items
	for i = 1, (NUM_AUCTIONS_TO_DISPLAY or 8) do
		local button = auctionButtonCache[i]
		if button then
			cfItemColors.applyQualityColor(button, nil)
		end
	end

	-- Clear sell item
	if sellItemButton then
		cfItemColors.applyQualityColor(sellItemButton, nil)
	end
end

-- Event frame for auction house monitoring
local eventFrame = CreateFrame("Frame")
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