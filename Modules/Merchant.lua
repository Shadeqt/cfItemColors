local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized API calls
local _G = _G
local MerchantFrame = MerchantFrame
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE
local GetMerchantItemLink = GetMerchantItemLink
local GetBuybackItemLink = GetBuybackItemLink
local GetNumBuybackItems = GetNumBuybackItems
local hooksecurefunc = hooksecurefunc

-- Constants
local NUM_BUYBACK_SLOTS = 12

-- Cache merchant button references
local merchantButtonCache = {}
local buybackPreviewButton = _G["MerchantBuyBackItemItemButton"]

for i = 1, MERCHANT_ITEMS_PER_PAGE do
	merchantButtonCache[i] = _G["MerchantItem" .. i .. "ItemButton"]
end

-- Apply quality colors to merchant tab items
local function UpdateMerchantTabItems()
	local currentPage = MerchantFrame.page or 1
	local pageOffset = (currentPage - 1) * MERCHANT_ITEMS_PER_PAGE

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local merchantItemButton = merchantButtonCache[i]
		if merchantItemButton then
			local itemIndex = pageOffset + i
			local merchantItemLink = GetMerchantItemLink(itemIndex)
			applyQualityColorWithQuestCheck(merchantItemButton, merchantItemLink)
		end
	end

	if not buybackPreviewButton then return end

	local mostRecentBuybackLink = GetBuybackItemLink(GetNumBuybackItems())
	applyQualityColorWithQuestCheck(buybackPreviewButton, mostRecentBuybackLink)
end

-- Apply quality colors to buyback tab items
local function UpdateBuybackTabItems()
	for i = 1, NUM_BUYBACK_SLOTS do
		local buybackItemButton = merchantButtonCache[i]
		if buybackItemButton then
			local buybackItemLink = GetBuybackItemLink(i)
			applyQualityColorWithQuestCheck(buybackItemButton, buybackItemLink)
		end
	end
end

-- Hook merchant tab update
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	if MerchantFrame.selectedTab == 1 then
		UpdateMerchantTabItems()
	end
end)

-- Hook buyback tab update
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	if MerchantFrame.selectedTab == 2 then
		UpdateBuybackTabItems()
	end
end)
