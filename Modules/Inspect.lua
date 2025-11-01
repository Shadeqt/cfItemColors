local EQUIPMENT_SLOTS = cfItemColors.EQUIPMENT_SLOTS

-- Cache slot data
local inspectSlotCache = {}

-- Initialize cache
local function initializeCache()
	for i = 1, #EQUIPMENT_SLOTS do
		local slotName = EQUIPMENT_SLOTS[i]
		inspectSlotCache[i] = {
			button = _G["Inspect" .. slotName .. "Slot"],
			inventorySlotId = GetInventorySlotInfo(slotName .. "Slot")
		}
	end
end

-- Update all inspect equipment slots
local function updateAllInspectSlots()
	for i = 1, #EQUIPMENT_SLOTS do
		local slotData = inspectSlotCache[i]
		if slotData and slotData.button then
			local itemLink = GetInventoryItemLink("target", slotData.inventorySlotId)
			cfItemColors.applyQualityColor(slotData.button, itemLink)
		end
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
		initializeCache()
		eventFrame:RegisterEvent("INSPECT_READY")
		eventFrame:SetScript("OnEvent", onInspectEvent)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)