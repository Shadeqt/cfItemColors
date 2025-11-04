-- Shared dependencies
local EQUIPMENT_SLOTS = cfItemColors.EQUIPMENT_SLOTS
local applyQualityColor = cfItemColors.applyQualityColor

-- Module states
local equipmentButtonCache = {}

-- Pre-cache character equipment slot frames at module load
for i = 1, #EQUIPMENT_SLOTS do
	equipmentButtonCache[i] = _G["Character" .. EQUIPMENT_SLOTS[i] .. "Slot"]
end

-- Updates a single character equipment slot with quality color
local function updateSingleEquipmentSlot(slotId)
	local equipmentButton = equipmentButtonCache[slotId]
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