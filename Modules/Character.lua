local addon = cfItemColors
local applyQualityColor = addon.ApplyQualityColor

-- Localized API calls
local _G = _G
local GetInventoryItemLink = GetInventoryItemLink
local CreateFrame = CreateFrame

-- Equipment slot configuration
local EQUIPMENT_SLOTS = addon.EQUIPMENT_SLOTS

-- Cache slot button references
local slotButtonCache = {}
for slotId = 1, #EQUIPMENT_SLOTS do
	local slotName = EQUIPMENT_SLOTS[slotId]
	slotButtonCache[slotId] = _G["Character" .. slotName .. "Slot"]
end

-- Apply quality color to a single equipment slot
local function UpdateSingleEquipmentSlot(slotId)
	local equipmentButton = slotButtonCache[slotId]
	if not equipmentButton then return end

	local inventoryItemLink = GetInventoryItemLink("player", slotId)
	applyQualityColor(equipmentButton, inventoryItemLink)
end

-- Apply quality colors to all equipment slots
local function UpdateAllEquipmentSlots()
	for slotId = 1, #EQUIPMENT_SLOTS do
		UpdateSingleEquipmentSlot(slotId)
	end
end

-- Listen for equipment changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "PLAYER_ENTERING_WORLD" then
		UpdateAllEquipmentSlots()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		UpdateSingleEquipmentSlot(slotId)
	end
end)
