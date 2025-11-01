-- Shared dependencies
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- WoW constants
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE -- 10, items displayed per merchant page

-- Module constants
local NUM_BUYBACK_SLOTS = 12 -- 12, maximum buyback history slots at vendors

-- Module states
local merchantButtonCache = {}
local buybackButtonCache = {}
local buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]

for i = 1, MERCHANT_ITEMS_PER_PAGE do
	merchantButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end

for i = 1, NUM_BUYBACK_SLOTS do
	buybackButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end

local function updateMerchantItems()
	local currentPage = MerchantFrame.page or 1
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local button = merchantButtonCache[i]
		if button then
			local itemIndex = pageOffset + i
			local itemLink = GetMerchantItemLink(itemIndex)
			applyQualityColorWithQuestCheck(button, itemLink)
		end
	end

	-- Update buyback preview button
	if buybackPreviewButton then
		local buybackLink = GetBuybackItemLink(GetNumBuybackItems())
		applyQualityColorWithQuestCheck(buybackPreviewButton, buybackLink)
	end
end

-- Update buyback tab items
local function updateBuybackItems()
	for i = 1, NUM_BUYBACK_SLOTS do
		local button = buybackButtonCache[i]
		if button then
			local itemLink = GetBuybackItemLink(i)
			applyQualityColorWithQuestCheck(button, itemLink)
		end
	end
end

-- Hook merchant updates
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateBuybackItems)