-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- Module constants
local NUM_REAGENT_SLOTS = 8 -- 8, maximum reagent slots in tradeskill window

-- Module states
local craftedItemButton = nil
local reagentButtonCache = {}
local classTrainerIconButton = nil

local function initializeCache()
	craftedItemButton = _G["TradeSkillSkillIcon"]
	for i = 1, NUM_REAGENT_SLOTS do
		reagentButtonCache[i] = _G["TradeSkillReagent" .. i]
	end
end

local function initializeClassTrainerCache()
	classTrainerIconButton = _G["ClassTrainerSkillIcon"]
end

-- Update tradeskill items
local function updateTradeSkillItems()
	local selectedIndex = GetTradeSkillSelectionIndex()

	-- Update crafted item
	if craftedItemButton then
		local itemLink = GetTradeSkillItemLink(selectedIndex)
		applyQualityColor(craftedItemButton, itemLink)
	end

	-- Update reagents
	for i = 1, NUM_REAGENT_SLOTS do
		local button = reagentButtonCache[i]
		if button then
			local reagentLink = GetTradeSkillReagentItemLink(selectedIndex, i)
			applyQualityColor(button, reagentLink)
		end
	end
end

local function updateClassTrainerIcon()
	local selectedIndex = GetTrainerSelectionIndex()

	if classTrainerIconButton and selectedIndex and selectedIndex > 0 then
		-- Get item link via tooltip scanning
		local itemLink = nil

		-- Create fresh tooltip each time to avoid caching issues
		local scanTooltip = CreateFrame("GameTooltip", "cfItemColorsTrainerScan_"..selectedIndex, nil, "GameTooltipTemplate")
		scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

		if scanTooltip.SetTrainerService then
			scanTooltip:SetTrainerService(selectedIndex)
			local _, link = scanTooltip:GetItem()
			itemLink = link
		end

		applyQualityColor(classTrainerIconButton, itemLink)
	end
end

-- Wait for Blizzard_TradeSkillUI to load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("TRAINER_SHOW")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == "Blizzard_TradeSkillUI" then
		initializeCache()
		hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillItems)
	elseif event == "TRAINER_SHOW" then
		-- Delay initialization to ensure frame is fully loaded
		C_Timer.After(0.1, function()
			initializeClassTrainerCache()
			if ClassTrainerFrame_Update then
				hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)
			end
			updateClassTrainerIcon()
		end)
		-- Unregister after first trainer show to avoid re-hooking
		self:UnregisterEvent("TRAINER_SHOW")
	end
end)