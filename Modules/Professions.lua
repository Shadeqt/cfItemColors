-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- Module constants
local NUM_REAGENT_SLOTS = 8 -- 8, maximum reagent slots in tradeskill window

-- Module states
local craftedItemButton = nil
local reagentButtonCache = {}
local classTrainerIconButton = nil

-- Lazy-cache tradeskill frames (built when UI loads)
local function initializeTradeSkillCache()
	if craftedItemButton then return end

	craftedItemButton = _G["TradeSkillSkillIcon"]
	for i = 1, NUM_REAGENT_SLOTS do
		reagentButtonCache[i] = _G["TradeSkillReagent" .. i]
	end
end

-- Lazy-cache class trainer frame (built when trainer shows)
local function initializeClassTrainerCache()
	if classTrainerIconButton then return end
	classTrainerIconButton = _G["ClassTrainerSkillIcon"]
end

-- Updates crafted item icon and reagent slots for selected tradeskill recipe
local function updateTradeSkillItems()
	initializeTradeSkillCache()
	local selectedIndex = GetTradeSkillSelectionIndex()

	-- Update crafted item
	local itemLink = GetTradeSkillItemLink(selectedIndex)
	applyQualityColor(craftedItemButton, itemLink)

	-- Update reagents
	local numReagents = GetTradeSkillNumReagents(selectedIndex)
	for i = 1, numReagents do
		local button = reagentButtonCache[i]
		local reagentLink = GetTradeSkillReagentItemLink(selectedIndex, i)
		applyQualityColor(button, reagentLink)
	end
end

local trainerScanTooltip = CreateFrame("GameTooltip", "cfItemColorsTrainerScan", nil, "GameTooltipTemplate")
trainerScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Updates item icon for selected class trainer recipe using tooltip scan
local function updateClassTrainerIcon()
	initializeClassTrainerCache()
	local selectedIndex = GetTrainerSelectionIndex()

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
		-- Unregister immediately to prevent race condition
		self:UnregisterEvent("TRAINER_SHOW")

		-- Delay initialization to ensure frame is fully loaded
		C_Timer.After(0.1, function()
			hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)
		end)
	end
end)