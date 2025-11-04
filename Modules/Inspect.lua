-- Shared dependencies
local EQUIPMENT_SLOTS = cfItemColors.EQUIPMENT_SLOTS
local applyQualityColor = cfItemColors.applyQualityColor

-- Updates a single inspect equipment slot with quality color
local function updateSingleInspectSlot(slotId)
	local equipmentSlot = EQUIPMENT_SLOTS[slotId]
	local inspectButton = _G["Inspect" .. equipmentSlot .. "Slot"]
	local inventoryItemLink = GetInventoryItemLink("target", slotId)
	applyQualityColor(inspectButton, inventoryItemLink)
end

-- Update all inspect equipment slots
local function updateAllInspectSlots()
	for i = 1, #EQUIPMENT_SLOTS do
		updateSingleInspectSlot(i)
	end
end

-- Handle inspect events
local function onInspectEvent(_, event)
	if event == "INSPECT_READY" then
		C_Timer.After(0.1, updateAllInspectSlots)
	end
end

-- Wait for Blizzard_InspectUI to load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_InspectUI" then
		eventFrame:RegisterEvent("INSPECT_READY")
		eventFrame:SetScript("OnEvent", onInspectEvent)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)