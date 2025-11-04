-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- Module constants
local NUM_REAGENT_SLOTS = 8 -- 8, maximum reagent slots in tradeskill window

-- Update tradeskill items
local function updateTradeSkillItems()
	local selectedIndex = GetTradeSkillSelectionIndex()

	-- Update crafted item
	local craftedItemButton = _G["TradeSkillSkillIcon"]
	local itemLink = GetTradeSkillItemLink(selectedIndex)
	applyQualityColor(craftedItemButton, itemLink)

	-- Update reagents
	for i = 1, NUM_REAGENT_SLOTS do
		local button = _G["TradeSkillReagent" .. i]
		local reagentLink = GetTradeSkillReagentItemLink(selectedIndex, i)
		applyQualityColor(button, reagentLink)
	end
end

local trainerScanTooltip = CreateFrame("GameTooltip", "cfItemColorsTrainerScan", nil, "GameTooltipTemplate")

local function updateClassTrainerIcon()
	local selectedIndex = GetTrainerSelectionIndex()
	local classTrainerIconButton = _G["ClassTrainerSkillIcon"]

	trainerScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	trainerScanTooltip:SetTrainerService(selectedIndex)
	local _, itemLink = trainerScanTooltip:GetItem()
	applyQualityColor(classTrainerIconButton, itemLink)
end

-- Wait for Blizzard_TradeSkillUI to load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("TRAINER_SHOW")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillItems)
	elseif event == "TRAINER_SHOW" then
		-- Delay initialization to ensure frame is fully loaded
		C_Timer.After(0.1, function()
			hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)
			updateClassTrainerIcon()
		end)
		-- Unregister after first trainer show to avoid re-hooking
		self:UnregisterEvent("TRAINER_SHOW")
	end
end)