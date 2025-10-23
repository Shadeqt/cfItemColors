local applyQualityColor = cfItemColors.ApplyQualityColor

-- Localized API calls
local _G = _G
local GetTradeSkillSelectionIndex = GetTradeSkillSelectionIndex
local GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
local GetTradeSkillItemLink = GetTradeSkillItemLink
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

-- Constants
local NUM_REAGENT_SLOTS = 8

-- Cache tradeskill button references
local reagentButtonCache = {}
local craftedItemButton = nil

-- Initialize tradeskill button cache
local function InitializeTradeSkillCache()
	craftedItemButton = _G["TradeSkillSkillIcon"]
	for i = 1, NUM_REAGENT_SLOTS do
		reagentButtonCache[i] = _G["TradeSkillReagent" .. i]
	end
end

-- Apply quality colors to crafted item and reagents
local function UpdateTradeSkillItems()
	local selectedRecipeIndex = GetTradeSkillSelectionIndex()

	if craftedItemButton then
		local craftedItemLink = GetTradeSkillItemLink(selectedRecipeIndex)
		applyQualityColor(craftedItemButton, craftedItemLink)
	end

	for i = 1, NUM_REAGENT_SLOTS do
		local reagentButton = reagentButtonCache[i]
		if reagentButton then
			local reagentItemLink = GetTradeSkillReagentItemLink(selectedRecipeIndex, i)
			applyQualityColor(reagentButton, reagentItemLink)
		end
	end
end

-- Wait for Blizzard_TradeSkillUI to load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_TradeSkillUI" then
		InitializeTradeSkillCache()
		hooksecurefunc("TradeSkillFrame_Update", UpdateTradeSkillItems)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
