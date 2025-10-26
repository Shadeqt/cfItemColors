local addon = cfItemColors
local applyQualityColorWithQuestCheck = addon.applyQualityColorWithQuestCheck

-- Cache API calls
local _GetMerchantItemLink = GetMerchantItemLink
local _GetBuybackItemLink = GetBuybackItemLink
local _GetNumBuybackItems = GetNumBuybackItems
local _hooksecurefunc = hooksecurefunc
local _MerchantFrame = MerchantFrame
local _G = _G

-- Constants
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE
local NUM_BUYBACK_SLOTS = 12

-- Cache button references
local merchantButtonCache = {}
local buybackButtonCache = {}
local buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]

-- Initialize button caches
for i = 1, MERCHANT_ITEMS_PER_PAGE do
	merchantButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end

for i = 1, NUM_BUYBACK_SLOTS do
	buybackButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end

-- Update merchant tab items
local function updateMerchantItems()
	local currentPage = _MerchantFrame.page or 1
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE
	
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local button = merchantButtonCache[i]
		if button then
			local itemIndex = pageOffset + i
			local itemLink = _GetMerchantItemLink(itemIndex)
			applyQualityColorWithQuestCheck(button, itemLink)
		end
	end
	
	-- Update buyback preview button
	if buybackPreviewButton then
		local buybackLink = _GetBuybackItemLink(_GetNumBuybackItems())
		applyQualityColorWithQuestCheck(buybackPreviewButton, buybackLink)
	end
end

-- Update buyback tab items
local function updateBuybackItems()
	for i = 1, NUM_BUYBACK_SLOTS do
		local button = buybackButtonCache[i]
		if button then
			local itemLink = _GetBuybackItemLink(i)
			applyQualityColorWithQuestCheck(button, itemLink)
		end
	end
end

-- Hook merchant updates
_hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)
_hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateBuybackItems)