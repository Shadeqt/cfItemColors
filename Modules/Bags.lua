-- Module enable check
local enabled = cfItemColors.GetModuleState(cfItemColors.MODULES.BAGS)
if not enabled then return end

-- WoW constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS 		-- 4, player bag slots (excludes backpack slot 0)
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS 	-- 7, bank bag slots (bags 5-11)

-- Module constants
local NUM_BAG_BANK_SLOTS = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS -- 11, combined total bag slots (4 player + 7 bank)

-- Updates all slots in a single bag with quality colors
local function updateSingleBagColors(bagId)
	local frameId = IsBagOpen(bagId)
	if not frameId then return end

	local numSlots = C_Container.GetContainerNumSlots(bagId)
	for i = 1, numSlots do
		local bagItemButton = _G["ContainerFrame" .. frameId .. "Item" .. i]
		if bagItemButton then
			local bagItemButtonId = bagItemButton:GetID()
			local containerItemId = C_Container.GetContainerItemID(bagId, bagItemButtonId)
			cfItemColors.applyQualityColor(bagItemButton, containerItemId)
		end
	end
end

-- Updates all bags with quality colors
local function updateAllBagColors()
	for i = 0, NUM_BAG_BANK_SLOTS do
		updateSingleBagColors(i)
	end
end

-- Update colors on bag changes and system events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")  -- Bag content changes
eventFrame:SetScript("OnEvent", updateAllBagColors)

hooksecurefunc("ToggleBag", updateSingleBagColors)  -- User clicks bag icons or B keybind
hooksecurefunc("OpenBag", updateSingleBagColors)  	-- System-opened bags (vendor, mail, bank)

-- Register for quest cache change notifications
cfItemColors.registerQuestChangeListener(updateAllBagColors)
