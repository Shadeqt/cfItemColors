local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized API calls
local _IsBagOpen = IsBagOpen
local _C_Container = C_Container
local _C_Timer = C_Timer
local _CreateFrame = CreateFrame

-- Constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS

-- Bank bag slot range
local NUM_FIRST_BANK_BAG_SLOT = NUM_BAG_SLOTS + 1
local NUM_LAST_BANK_BAG_SLOT = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS

-- Apply quality colors to all item buttons in a single bag
local function updateSingleBagColors(bagId)
	local frameId = _IsBagOpen(bagId)
	if not frameId then return end

	local containerFrame = _G["ContainerFrame" .. frameId]
	if not containerFrame then return end

	local containerFrameName = containerFrame:GetName()
	for i = 1, containerFrame.size do
		local bagItemButton = _G[containerFrameName .. "Item" .. i]
		if bagItemButton then
			local containerItemId = _C_Container.GetContainerItemID(bagId, bagItemButton:GetID())
			applyQualityColorWithQuestCheck(bagItemButton, containerItemId)
		end
	end
end

-- Apply quality colors to all bags when opening all at once
local function updateAllBagColors()
	local containerFrame = _G["ContainerFrame1"]
	if not containerFrame then return end
	if not containerFrame.allBags then return end

	-- Delay needed to let WoW create bag frames before coloring
	_C_Timer.After(0.01, function()
		-- Update player bags (0-4)
		for bagId = 0, NUM_BAG_SLOTS do
			updateSingleBagColors(bagId)
		end

		-- Also update bank bags if bank is open
		local bankFrame = _G["BankFrame"]
		if bankFrame and bankFrame:IsShown() then
			for bagId = NUM_FIRST_BANK_BAG_SLOT, NUM_LAST_BANK_BAG_SLOT do
				updateSingleBagColors(bagId)
			end
		end
	end)
end

-- Hook bag open/close events
hooksecurefunc("ToggleBag", updateSingleBagColors)
hooksecurefunc("ToggleBackpack", updateAllBagColors)

-- Listen for bag content changes (item added/removed/moved)
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:SetScript("OnEvent", function(_, _, bagId)
	if _IsBagOpen(bagId) then
		updateSingleBagColors(bagId)
	end
end)
