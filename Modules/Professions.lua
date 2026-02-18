local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.PROFESSIONS].enabled then return end

-- Module constants
local NUM_REAGENT_SLOTS = 8 -- 8, maximum reagent slots in tradeskill window

-- Updates crafted item and reagent slots for selected tradeskill recipe
local function updateTradeSkillItems()
	local selectedIndex = GetTradeSkillSelectionIndex()

	-- Update crafted item
	local craftedItemButton = _G["TradeSkillSkillIcon"]
	local itemLink = GetTradeSkillItemLink(selectedIndex)
	addon.applyQualityColor(craftedItemButton, itemLink)

	-- Update reagents
	local numReagents = GetTradeSkillNumReagents(selectedIndex)
	for i = 1, numReagents do
		local button = _G["TradeSkillReagent" .. i]
		local reagentLink = GetTradeSkillReagentItemLink(selectedIndex, i)
		addon.applyQualityColor(button, reagentLink)
	end
end

-- Hidden tooltip for extracting trainer item links (created on demand)
local trainerScanTooltip

-- Updates class trainer item icon using tooltip scan
local function updateClassTrainerIcon()
	local selectedIndex = GetTrainerSelectionIndex()
	local classTrainerIconButton = _G["ClassTrainerSkillIcon"]

	if not trainerScanTooltip then
		trainerScanTooltip = CreateFrame("GameTooltip", "cfItemColorsTrainerScan", UIParent, "GameTooltipTemplate")
	end
	trainerScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	trainerScanTooltip:SetTrainerService(selectedIndex)
	local _, itemLink = trainerScanTooltip:GetItem()
	addon.applyQualityColor(classTrainerIconButton, itemLink)
end

-- Initialize profession UI hooks when their addons load
local eventFrame = CreateFrame("Frame")

local function onAddonLoaded(_, _, addonName)
	if addonName == "Blizzard_TradeSkillUI" then
		hooksecurefunc("TradeSkillFrame_SetSelection", updateTradeSkillItems)
	elseif addonName == "Blizzard_TrainerUI" then
		hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)
	end
end

-- Check if already loaded (e.g. after /reload), otherwise wait
if C_AddOns.IsAddOnLoaded("Blizzard_TradeSkillUI") then
	hooksecurefunc("TradeSkillFrame_SetSelection", updateTradeSkillItems)
end
if C_AddOns.IsAddOnLoaded("Blizzard_TrainerUI") then
	hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", onAddonLoaded)
