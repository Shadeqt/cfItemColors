-- Module enable check
local enabled = cfItemColors.GetModuleState(cfItemColors.MODULES.PROFESSIONS)
if not enabled then return end

-- Module constants
local NUM_REAGENT_SLOTS = 8 -- 8, maximum reagent slots in tradeskill window

-- Updates crafted item and reagent slots for selected tradeskill recipe
local function updateTradeSkillItems()
	local selectedIndex = GetTradeSkillSelectionIndex()

	-- Update crafted item
	local craftedItemButton = _G["TradeSkillSkillIcon"]
	local itemLink = GetTradeSkillItemLink(selectedIndex)
	cfItemColors.applyQualityColor(craftedItemButton, itemLink)

	-- Update reagents
	local numReagents = GetTradeSkillNumReagents(selectedIndex)
	for i = 1, numReagents do
		local button = _G["TradeSkillReagent" .. i]
		local reagentLink = GetTradeSkillReagentItemLink(selectedIndex, i)
		cfItemColors.applyQualityColor(button, reagentLink)
	end
end

local trainerScanTooltip = CreateFrame("GameTooltip", "cfItemColorsTrainerScan", nil, "GameTooltipTemplate")
trainerScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Updates class trainer item icon using tooltip scan
local function updateClassTrainerIcon()
	local selectedIndex = GetTrainerSelectionIndex()
	local classTrainerIconButton = _G["ClassTrainerSkillIcon"]

	trainerScanTooltip:SetTrainerService(selectedIndex)
	local _, itemLink = trainerScanTooltip:GetItem()
	cfItemColors.applyQualityColor(classTrainerIconButton, itemLink)
end

-- Initialize profession UI hooks and handle class trainer events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")  -- Wait for Blizzard_TradeSkillUI
eventFrame:RegisterEvent("TRAINER_SHOW")  -- Trainer window opened

eventFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillItems)  -- Tradeskill selection changes
	elseif event == "TRAINER_SHOW" then
		self:UnregisterEvent("TRAINER_SHOW")
		C_Timer.After(0.1, function()
			hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)  -- Trainer selection changes
		end)
	end
end)
