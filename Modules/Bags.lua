-- Module enable check
if not cfItemColorsDB.enableBags then return end

local isConflict, conflictingAddon = cfItemColors.Compatibility.IsBagAddonActive()
if isConflict then
	print(conflictingAddon .. " has been detected. CfItemColors disabled bag module.")
	return
end

-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS -- 4, player bag slots (excludes backpack slot 0)
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS -- 7, bank bag slots (bags 5-11)

-- Module constants
local NUM_BAG_BANK_SLOTS = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS -- 11, combined total bag slots (4 player + 7 bank)

-- Updates a single bag with quality colors for all its slots
local function updateSingleBagColors(bagId)
	local frameId = IsBagOpen(bagId)
	if not frameId then return end

	local numSlots = C_Container.GetContainerNumSlots(bagId)
	for i = 1, numSlots do
		local bagItemButton = _G["ContainerFrame" .. frameId .. "Item" .. i]
		if bagItemButton then
			local bagItemButtonId = bagItemButton:GetID()
			local containerItemId = C_Container.GetContainerItemID(bagId, bagItemButtonId)
			applyQualityColor(bagItemButton, containerItemId)
		end
	end
end

-- Updates all bags with quality colors (no checks for open state)
local function updateAllBagColors()
	for i = 0, NUM_BAG_BANK_SLOTS do
		updateSingleBagColors(i)
	end
end

-- Event registration for bag coloring
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")  -- Bag content changes (bags 0-10)
eventFrame:SetScript("OnEvent", updateAllBagColors)

-- Hook: user clicks on bag icons and B keybind
hooksecurefunc("ToggleBag", function(bagId)
	updateSingleBagColors(bagId)
end)

-- Hook: system-opened bags (vendor, mail, bank interactions)
hooksecurefunc("OpenBag", function(bagId)
	updateSingleBagColors(bagId)
end)

-- Register for quest cache change notifications
cfItemColors.registerQuestChangeListener(updateAllBagColors)
