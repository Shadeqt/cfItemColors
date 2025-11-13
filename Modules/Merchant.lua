local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.MERCHANT].enabled then return end

-- WoW constants
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE -- 10, items displayed per merchant page

-- Updates merchant items and buyback preview for current page
local function updateMerchantItems()
	local currentPage = MerchantFrame.page
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE
	local numMerchantItems = GetMerchantNumItems()

	-- Calculate actual items on current page
	local itemsOnPage = math.min(MERCHANT_ITEMS_PER_PAGE, numMerchantItems - pageOffset)

	for i = 1, itemsOnPage do
		local button = _G["MerchantItem" .. i .. "ItemButton"]
		local itemIndex = pageOffset + i
		local itemLink = GetMerchantItemLink(itemIndex)
		addon.applyQualityColor(button, itemLink)
	end

	-- Update buyback preview button
	local buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]
	local numBuybackItems = GetNumBuybackItems()
	local buybackLink = GetBuybackItemLink(numBuybackItems)
	addon.applyQualityColor(buybackPreviewButton, buybackLink)
end

-- Updates buyback tab item buttons
local function updateBuybackItems()
	local numBuybackItems = GetNumBuybackItems()

	for i = 1, numBuybackItems do
		local button = _G["MerchantItem" .. i .. "ItemButton"]
		local itemLink = GetBuybackItemLink(i)
		addon.applyQualityColor(button, itemLink)
	end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems) -- Merchant tab updates
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateBuybackItems)	-- Buyback tab updates
