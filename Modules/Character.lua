-- Shared dependencies
local EQUIPMENT_SLOTS = cfItemColors.EQUIPMENT_SLOTS
local applyQualityColor = cfItemColors.applyQualityColor

-- Module states
local equipmentSlotButtonCache = {}
for i = 1, #EQUIPMENT_SLOTS do
	equipmentSlotButtonCache[i] = _G["Character" .. EQUIPMENT_SLOTS[i] .. "Slot"]
end

local function updateSingleEquipmentSlot(slotId)
	if slotId < 1 or slotId > 19 then return end

	local equipmentButton = equipmentSlotButtonCache[slotId]
	if not equipmentButton then return end

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