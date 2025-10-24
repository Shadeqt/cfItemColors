local applyQualityColor = cfItemColors.applyQualityColor

-- Localized API calls
local _GetTradeSkillSelectionIndex = GetTradeSkillSelectionIndex
local _GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
local _GetTradeSkillItemLink = GetTradeSkillItemLink
local _CreateFrame = CreateFrame

-- Constants
local NUM_REAGENT_SLOTS = 8

-- Cache tradeskill button references
local reagentButtonCache = {}
local craftedItemButton = nil

-- Initialize tradeskill button cache
local function initializeTradeSkillCache()
	craftedItemButton = _G["TradeSkillSkillIcon"]
	for i = 1, NUM_REAGENT_SLOTS do
		reagentButtonCache[i] = _G["TradeSkillReagent" .. i]
	end
end

-- Apply quality colors to crafted item and reagents
local function updateTradeSkillItems()
	local selectedRecipeIndex = _GetTradeSkillSelectionIndex()

	if craftedItemButton then
		local craftedItemLink = _GetTradeSkillItemLink(selectedRecipeIndex)
		applyQualityColor(craftedItemButton, craftedItemLink)
	end

	for i = 1, NUM_REAGENT_SLOTS do
		local reagentButton = reagentButtonCache[i]
		if reagentButton then
			local reagentItemLink = _GetTradeSkillReagentItemLink(selectedRecipeIndex, i)
			applyQualityColor(reagentButton, reagentItemLink)
		end
	end
end

-- Wait for Blizzard_TradeSkillUI to load
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_TradeSkillUI" then
		initializeTradeSkillCache()
		hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillItems)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
