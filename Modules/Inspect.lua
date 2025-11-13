-- Module enable check
local enabled = cfItemColors.GetModuleState(cfItemColors.MODULES.INSPECT)
if not enabled then return end

-- Updates a single inspect equipment slot
local function updateSingleInspectSlot(slotId)
	local equipmentSlot = cfItemColors.EQUIPMENT_SLOTS[slotId]
	local inspectButton = _G["Inspect" .. equipmentSlot .. "Slot"]
	local inventoryItemLink = GetInventoryItemLink("target", slotId)
	cfItemColors.applyQualityColor(inspectButton, inventoryItemLink)
end

-- Updates all inspect equipment slots
local function updateAllInspectSlots()
	for i = 1, #cfItemColors.EQUIPMENT_SLOTS do
		updateSingleInspectSlot(i)
	end
end

-- Handles inspect ready event with delay for data loading
local function onInspectEvent(_, event)
	if event == "INSPECT_READY" then
		C_Timer.After(0.1, updateAllInspectSlots)
	end
end

-- Initialize inspect UI when addon loads and handle inspect events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")  -- Wait for Blizzard_InspectUI
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_InspectUI" then
		eventFrame:RegisterEvent("INSPECT_READY")  -- Inspect data ready
		eventFrame:SetScript("OnEvent", onInspectEvent)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
