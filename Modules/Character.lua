-- Module enable check
local enabled = cfItemColors.Init.GetModuleState(cfItemColors.Init.MODULES.CHARACTER)
if not enabled then return end

-- Shared dependencies
local EQUIPMENT_SLOTS = cfItemColors.EQUIPMENT_SLOTS
local applyQualityColor = cfItemColors.applyQualityColor

-- Updates a single character equipment slot with quality color
local function updateSingleEquipmentSlot(slotId)
	local equipmentSlot = EQUIPMENT_SLOTS[slotId]
	local equipmentButton = _G["Character" .. equipmentSlot .. "Slot"]
	local inventoryItemLink = GetInventoryItemLink("player", slotId)
	applyQualityColor(equipmentButton, inventoryItemLink)
end

-- Updates all equipment slots with quality colors
local function updateAllEquipmentSlots()
	for i = 1, #EQUIPMENT_SLOTS do
		updateSingleEquipmentSlot(i)
	end
end

-- Only 2 events needed for complete coverage
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")  -- Perfect 1:1 ratio, zero spam
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")     -- Login initialization

-- Processes equipment changes and login
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		updateSingleEquipmentSlot(slotId)
	elseif event == "PLAYER_ENTERING_WORLD" then
		updateAllEquipmentSlots()
	end
end)

-- Register for quest cache change notifications
cfItemColors.registerQuestChangeListener(updateAllEquipmentSlots)
