local isActive, addonName = cfItemColors.IsBagAddonActive()
if isActive then
	print("cfItemColors: Bag addon detected (" .. addonName .. "), bag module disabled")
	return
end

-- Shared dependencies
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- WoW constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS -- 4, player bag slots (excludes backpack slot 0)
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS -- 7, bank bag slots (bags 5-11)

-- Module constants
local NUM_BAG_BANK_SLOTS = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS -- 11, combined total bag slots (4 player + 7 bank)

local function updateSingleBagColors(bagId)
	if bagId < 0 or bagId > NUM_BAG_BANK_SLOTS then return end

	local frameId = IsBagOpen(bagId)
	if not frameId then return end

	local containerFrame = _G["ContainerFrame" .. frameId]
	if not containerFrame then return end

	local containerFrameName = containerFrame:GetName()
	for i = 1, containerFrame.size do
		local bagItemButton = _G[containerFrameName .. "Item" .. i]
		if bagItemButton then
			local bagItemButtonId = bagItemButton:GetID()
			local containerItemId = C_Container.GetContainerItemId(bagId, bagItemButtonId)
			applyQualityColorWithQuestCheck(bagItemButton, containerItemId)
		end
	end
end

-- Updates all currently open bags with quality colors
local function updateAllOpenBagColors()
	for i = 0, NUM_BAG_BANK_SLOTS do
		if IsBagOpen(i) then
			updateSingleBagColors(i)
		end
	end
end

-- Only 2 events needed for complete coverage
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")  -- Bag content changes (bags 0-10)
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Login initialization

-- Processes bag changes and login
eventFrame:SetScript("OnEvent", function(_, event, bagId)
	if event == "BAG_UPDATE_DELAYED" then
		-- Specific bag operations (moves, new items) provide exact bagId
		if bagId and bagId >= 0 and bagId <= NUM_BAG_BANK_SLOTS and IsBagOpen(bagId) then
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
hooksecurefunc("ToggleBag", function(bagId)
	-- Only process valid bag Ids (0-4) that are currently open
	if bagId >= 0 and bagId <= NUM_BAG_BANK_SLOTS and IsBagOpen(bagId) then
		updateSingleBagColors(bagId)
	end
end)

-- Handles system-opened bags (vendor, mail, bank interactions)
hooksecurefunc("OpenBag", function(bagId)
	-- Only process bags 1-11 (regular bags + bank bags, excludes backpack since ToggleBag handles it)
	if bagId >= 1 and bagId <= NUM_BAG_BANK_SLOTS and IsBagOpen(bagId) then
		updateSingleBagColors(bagId)
	end
end)