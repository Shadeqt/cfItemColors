-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE -- 10, items displayed per merchant page

-- Module states
local merchantButtonCache = {}
local buybackPreviewButton = nil

-- Pre-cache merchant frames at module load
for i = 1, MERCHANT_ITEMS_PER_PAGE do
	merchantButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end
buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]

-- Updates merchant item buttons and buyback preview for current page
local function updateMerchantItems()
	local currentPage = MerchantFrame.page
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE
	local numMerchantItems = GetMerchantNumItems()

	-- Calculate actual items on current page
	local itemsOnPage = math.min(MERCHANT_ITEMS_PER_PAGE, numMerchantItems - pageOffset)

	for i = 1, itemsOnPage do
		local button = merchantButtonCache[i]
		local itemIndex = pageOffset + i
		local itemLink = GetMerchantItemLink(itemIndex)
		applyQualityColor(button, itemLink)
	end

	-- Update buyback preview button
	local numBuybackItems = GetNumBuybackItems()
	local buybackLink = GetBuybackItemLink(numBuybackItems)
	applyQualityColor(buybackPreviewButton, buybackLink)
end

-- Updates buyback tab item buttons
local function updateBuybackItems()
	local numBuybackItems = GetNumBuybackItems()

	for i = 1, numBuybackItems do
		local button = merchantButtonCache[i]
		local itemLink = GetBuybackItemLink(i)
		applyQualityColor(button, itemLink)
	end
end

-- Hook merchant updates
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateBuybackItems)
