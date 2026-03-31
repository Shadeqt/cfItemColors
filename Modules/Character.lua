local addon = cfItemColors

-- Module enable check
if not cfItemColorsDB[addon.MODULES.CHARACTER].enabled then return end

-- Updates a single character equipment slot
local function updateSingleEquipmentSlot(slotId)
	local equipmentSlot = addon.EQUIPMENT_SLOTS[slotId]
	local equipmentButton = _G["Character" .. equipmentSlot .. "Slot"]
	local inventoryItemLink = GetInventoryItemLink("player", slotId)
	addon.applyQualityColor(equipmentButton, inventoryItemLink)
end

-- Updates all character equipment slots
local function updateAllEquipmentSlots()
	for i = 1, #addon.EQUIPMENT_SLOTS do
		updateSingleEquipmentSlot(i)
	end
end

-- Update colors on equipment changes and when frame is shown
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, _, slotId)
	updateSingleEquipmentSlot(slotId)
end)

CharacterFrame:HookScript("OnShow", function()
	eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	updateAllEquipmentSlots()
end)
CharacterFrame:HookScript("OnHide", function()
	eventFrame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end)
