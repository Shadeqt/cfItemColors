local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized API calls
local _GetMerchantItemLink = GetMerchantItemLink
local _GetBuybackItemLink = GetBuybackItemLink
local _GetNumBuybackItems = GetNumBuybackItems

-- Constants
local MerchantFrame = MerchantFrame
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE
local NUM_BUYBACK_SLOTS = 12

-- Cache merchant button references
local merchantButtonCache = {}
local buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]

for i = 1, MERCHANT_ITEMS_PER_PAGE do
	merchantButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end

-- Apply quality colors to merchant tab items
local function updateMerchantTabItems()
	local currentPage = MerchantFrame.page or 1
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local merchantItemButton = merchantButtonCache[i]
		if merchantItemButton then
			local itemIndex = pageOffset + i
			local merchantItemLink = _GetMerchantItemLink(itemIndex)
			applyQualityColorWithQuestCheck(merchantItemButton, merchantItemLink)
		end
	end

	if not buybackPreviewButton then return end

	local mostRecentBuybackLink = _GetBuybackItemLink(_GetNumBuybackItems())
	applyQualityColorWithQuestCheck(buybackPreviewButton, mostRecentBuybackLink)
end

-- Apply quality colors to buyback tab items
local function updateBuybackTabItems()
	for i = 1, NUM_BUYBACK_SLOTS do
		local buybackItemButton = merchantButtonCache[i]
		if buybackItemButton then
			local buybackItemLink = _GetBuybackItemLink(i)
			applyQualityColorWithQuestCheck(buybackItemButton, buybackItemLink)
		end
	end
end

-- Hook merchant tab update
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	if MerchantFrame.selectedTab == 1 then
		updateMerchantTabItems()
	end
end)

-- Hook buyback tab update
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	if MerchantFrame.selectedTab == 2 then
		updateBuybackTabItems()
	end
end)
