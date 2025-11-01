-- Constants
local NUM_REAGENT_SLOTS = 8

-- Cache button references
local craftedItemButton = nil
local reagentButtonCache = {}

-- Initialize button cache
local function initializeCache()
	craftedItemButton = _G["TradeSkillSkillIcon"]
	for i = 1, NUM_REAGENT_SLOTS do
		reagentButtonCache[i] = _G["TradeSkillReagent" .. i]
	end
end

-- Update tradeskill items
local function updateTradeSkillItems()
	local selectedIndex = GetTradeSkillSelectionIndex()

	-- Update crafted item
	if craftedItemButton then
		local itemLink = GetTradeSkillItemLink(selectedIndex)
		cfItemColors.applyQualityColor(craftedItemButton, itemLink)
	end

	-- Update reagents
	for i = 1, NUM_REAGENT_SLOTS do
		local button = reagentButtonCache[i]
		if button then
			local reagentLink = GetTradeSkillReagentItemLink(selectedIndex, i)
			cfItemColors.applyQualityColor(button, reagentLink)
		end
	end
end

-- Wait for Blizzard_TradeSkillUI to load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_TradeSkillUI" then
		initializeCache()
		hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillItems)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)