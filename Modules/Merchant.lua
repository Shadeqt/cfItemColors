-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE -- 10, items displayed per merchant page

-- Module constants
local NUM_BUYBACK_SLOTS = 12 -- 12, maximum buyback history slots at vendors

local function updateMerchantItems()
	local currentPage = MerchantFrame.page or 1
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local button = _G["MerchantItem" .. i .. "ItemButton"]
		local itemIndex = pageOffset + i
		local itemLink = GetMerchantItemLink(itemIndex)
		applyQualityColor(button, itemLink)
	end

	-- Update buyback preview button
	local buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]
	local buybackLink = GetBuybackItemLink(GetNumBuybackItems())
	applyQualityColor(buybackPreviewButton, buybackLink)
end

-- Update buyback tab items
local function updateBuybackItems()
	for i = 1, NUM_BUYBACK_SLOTS do
		local button = _G["MerchantItem" .. i .. "ItemButton"]
		local itemLink = GetBuybackItemLink(i)
		applyQualityColor(button, itemLink)
	end
end

-- Hook merchant updates
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateBuybackItems)
