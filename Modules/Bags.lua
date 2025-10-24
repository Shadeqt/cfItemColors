local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized API calls
local IsBagOpen = IsBagOpen
local _G = _G
local C_Container = C_Container
local C_Timer = C_Timer
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

-- Bank bag slot range
local NUM_FIRST_BANK_BAG_SLOT = NUM_BAG_SLOTS + 1
local NUM_LAST_BANK_BAG_SLOT = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS

-- Apply quality colors to all item buttons in a single bag
local function UpdateSingleBagColors(bagId)
	local frameId = IsBagOpen(bagId)
	if not frameId then return end

	local containerFrame = _G["ContainerFrame" .. frameId]
	if not containerFrame then return end

	local containerFrameName = containerFrame:GetName()
	for i = 1, containerFrame.size do
		local bagItemButton = _G[containerFrameName .. "Item" .. i]
		if bagItemButton then
			local containerItemId = C_Container.GetContainerItemID(bagId, bagItemButton:GetID())
			applyQualityColorWithQuestCheck(bagItemButton, containerItemId)
		end
	end
end

-- Apply quality colors to all bags when opening all at once
local function UpdateAllBagColors()
	local containerFrame = _G["ContainerFrame1"]
	if not containerFrame then return end
	if not containerFrame.allBags then return end

	-- Delay needed to let WoW create bag frames before coloring
	C_Timer.After(0.01, function()
		-- Update player bags (0-4)
		for bagId = 0, NUM_BAG_SLOTS do
			UpdateSingleBagColors(bagId)
		end

		-- Also update bank bags if bank is open
		local bankFrame = _G["BankFrame"]
		if bankFrame and bankFrame:IsShown() then
			for bagId = NUM_FIRST_BANK_BAG_SLOT, NUM_LAST_BANK_BAG_SLOT do
				UpdateSingleBagColors(bagId)
			end
		end
	end)
end

-- Hook bag open/close events
hooksecurefunc("ToggleBag", UpdateSingleBagColors)
hooksecurefunc("ToggleBackpack", UpdateAllBagColors)

-- Listen for bag content changes (item added/removed/moved)
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:SetScript("OnEvent", function(_, _, bagId)
	if IsBagOpen(bagId) then
		UpdateSingleBagColors(bagId)
	end
end)
