-- Module enable check
local enabled = cfItemColors.GetModuleState(cfItemColors.MODULES.CHARACTER)
if not enabled then return end

-- Updates a single character equipment slot
local function updateSingleEquipmentSlot(slotId)
	local equipmentSlot = cfItemColors.EQUIPMENT_SLOTS[slotId]
	local equipmentButton = _G["Character" .. equipmentSlot .. "Slot"]
	local inventoryItemLink = GetInventoryItemLink("player", slotId)
	cfItemColors.applyQualityColor(equipmentButton, inventoryItemLink)
end

-- Updates all character equipment slots
local function updateAllEquipmentSlots()
	for i = 1, #cfItemColors.EQUIPMENT_SLOTS do
		updateSingleEquipmentSlot(i)
	end
end

-- Update colors on equipment changes and login
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")  	-- Equipment slot changed
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  		-- Login initialization
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		updateSingleEquipmentSlot(slotId)
	elseif event == "PLAYER_ENTERING_WORLD" then
		updateAllEquipmentSlots()
	end
end)

-- Register for quest cache change notifications
cfItemColors.registerQuestChangeListener(updateAllEquipmentSlots)
