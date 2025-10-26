-- Main coloring function from parent module
local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor

local EQUIPMENT_SLOTS = addon.EQUIPMENT_SLOTS

-- Localized WoW API calls for performance
local _GetInventoryItemLink = GetInventoryItemLink
local _CreateFrame = CreateFrame
local _G = _G

-- Cache equipment slot button references to avoid repeated _G lookups
local equipmentSlotButtonCache = {}
for slotId = 1, #EQUIPMENT_SLOTS do
	equipmentSlotButtonCache[slotId] = _G["Character" .. EQUIPMENT_SLOTS[slotId] .. "Slot"]
end

-- Updates a single equipment slot with quality color
local function updateSingleEquipmentSlot(slotId)
	if slotId < 1 or slotId > 19 then return end
	
	local equipmentButton = equipmentSlotButtonCache[slotId]
	if not equipmentButton then return end

	local inventoryItemLink = _GetInventoryItemLink("player", slotId)
	applyQualityColor(equipmentButton, inventoryItemLink)
end

-- Updates all equipment slots with quality colors
local function updateAllEquipmentSlots()
	for slotId = 1, #EQUIPMENT_SLOTS do
		updateSingleEquipmentSlot(slotId)
	end
end

-- Only 2 events needed for complete coverage
local eventFrame = _CreateFrame("Frame")
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