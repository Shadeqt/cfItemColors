local addon = cfItemColors
local applyQualityColor = addon.ApplyQualityColor

-- Localized API calls
local _G = _G
local GetInventorySlotInfo = GetInventorySlotInfo
local GetInventoryItemLink = GetInventoryItemLink
local C_Timer = C_Timer
local CreateFrame = CreateFrame

-- Equipment slot configuration
local EQUIPMENT_SLOTS = addon.EQUIPMENT_SLOTS

-- Cache slot data (button reference and slot ID)
local inspectSlotCache = {}

-- Initialize cache when Blizzard_InspectUI loads
local function InitializeInspectCache()
	for slotId = 1, #EQUIPMENT_SLOTS do
		local slotName = EQUIPMENT_SLOTS[slotId]
		inspectSlotCache[slotId] = {
			button = _G["Inspect" .. slotName .. "Slot"],
			slotId = GetInventorySlotInfo(slotName .. "Slot")
		}
	end
end

-- Apply quality colors to all inspect equipment slots
local function UpdateAllInspectEquipmentSlots()
	for slotId = 1, #EQUIPMENT_SLOTS do
		local slotData = inspectSlotCache[slotId]
		if slotData and slotData.button and slotData.slotId then
			local targetInventoryItemLink = GetInventoryItemLink("target", slotData.slotId)
			applyQualityColor(slotData.button, targetInventoryItemLink)
		end
	end
end

-- Handle inspect events
local function OnInspectEvent(_, event, unitId)
	if event == "INSPECT_READY" then
		C_Timer.After(0.01, UpdateAllInspectEquipmentSlots)
	elseif event == "UNIT_INVENTORY_CHANGED" and unitId == "target" then
		UpdateAllInspectEquipmentSlots()
	end
end

-- Wait for Blizzard_InspectUI to load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_InspectUI" then
		InitializeInspectCache()
		eventFrame:RegisterEvent("INSPECT_READY")
		eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
		eventFrame:SetScript("OnEvent", OnInspectEvent)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
