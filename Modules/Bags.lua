-- Early exit if bag addon detected
local isActive, addonName = cfItemColors.IsBagAddonActive()
if isActive then
	print("cfItemColors: Bag addon detected (" .. addonName .. "), bag module disabled")
	return
end

-- Main coloring function from parent module
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized WoW API calls for performance
local _IsBagOpen = IsBagOpen
local _GetContainerItemID = C_Container.GetContainerItemID
local _CreateFrame = CreateFrame
local _hooksecurefunc = hooksecurefunc
local _G = _G

-- WoW constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS  -- 4 (regular bag slots 1-4)
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS  -- 6 (bank bag slots 5-10)

-- Constants
local NUM_BAG_BANK_SLOTS = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS

-- Updates all item buttons in a single bag with quality colors
local function updateSingleBagColors(bagId)
	if bagId < 0 or bagId > NUM_BAG_BANK_SLOTS then return end
	
	local frameId = _IsBagOpen(bagId)
	if not frameId then return end

	local containerFrame = _G["ContainerFrame" .. frameId]
	if not containerFrame then return end

	local containerFrameName = containerFrame:GetName()
	for i = 1, containerFrame.size do
		local bagItemButton = _G[containerFrameName .. "Item" .. i]
		if bagItemButton then
			local bagItemButtonId = bagItemButton:GetID()
			local containerItemId = _GetContainerItemID(bagId, bagItemButtonId)
			applyQualityColorWithQuestCheck(bagItemButton, containerItemId)
		end
	end
end

-- Updates all currently open bags with quality colors
local function updateAllOpenBagColors()
	for bagId = 0, NUM_BAG_BANK_SLOTS do
		if _IsBagOpen(bagId) then
			updateSingleBagColors(bagId)
		end
	end
end

-- Only 2 events needed for complete coverage
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")  -- Bag content changes (bags 0-10)
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Login initialization

-- Processes bag changes and login
eventFrame:SetScript("OnEvent", function(_, event, bagId)
	if event == "BAG_UPDATE_DELAYED" then
		-- Specific bag operations (moves, new items) provide exact bagId
		if bagId and bagId >= 0 and bagId <= NUM_BAG_BANK_SLOTS and _IsBagOpen(bagId) then
			updateSingleBagColors(bagId)
		-- Stack operations (splits, deletions) provide nil bagId
		elseif bagId == nil then
			updateAllOpenBagColors()
		end
		
	elseif event == "PLAYER_ENTERING_WORLD" then
		updateAllOpenBagColors()
	end
end)

-- Handles user clicks on bag icons and B keybind
_hooksecurefunc("ToggleBag", function(bagId)
	-- Only process valid bag IDs (0-4) that are currently open
	if bagId >= 0 and bagId <= NUM_BAG_BANK_SLOTS and _IsBagOpen(bagId) then
		updateSingleBagColors(bagId)
	end
end)

-- Handles system-opened bags (vendor, mail, bank interactions)
_hooksecurefunc("OpenBag", function(bagId)
	-- Only process bags 1-11 (regular bags + bank bags, excludes backpack since ToggleBag handles it)
	if bagId >= 1 and bagId <= NUM_BAG_BANK_SLOTS and _IsBagOpen(bagId) then
		updateSingleBagColors(bagId)
	end
end)