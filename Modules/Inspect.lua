local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor

-- Localized API calls
local _GetInventorySlotInfo = GetInventorySlotInfo
local _GetInventoryItemLink = GetInventoryItemLink
local _C_Timer = C_Timer
local _CreateFrame = CreateFrame

-- Equipment slot configuration
local EQUIPMENT_SLOTS = addon.EQUIPMENT_SLOTS

-- Cache slot data (button reference and slot ID)
local inspectSlotCache = {}

-- Initialize cache when Blizzard_InspectUI loads
local function initializeInspectCache()
	for slotId = 1, #EQUIPMENT_SLOTS do
		local slotName = EQUIPMENT_SLOTS[slotId]
		inspectSlotCache[slotId] = {
			button = _G["Inspect" .. slotName .. "Slot"],
			slotId = _GetInventorySlotInfo(slotName .. "Slot")
		}
	end
end

-- Apply quality colors to all inspect equipment slots
local function updateAllInspectEquipmentSlots()
	for slotId = 1, #EQUIPMENT_SLOTS do
		local slotData = inspectSlotCache[slotId]
		if slotData and slotData.button and slotData.slotId then
			local targetInventoryItemLink = _GetInventoryItemLink("target", slotData.slotId)
			applyQualityColor(slotData.button, targetInventoryItemLink)
		end
	end
end

-- Handle inspect events
local function onInspectEvent(_, event, unitId)
	if event == "INSPECT_READY" then
		_C_Timer.After(0.01, updateAllInspectEquipmentSlots)
	elseif event == "UNIT_INVENTORY_CHANGED" and unitId == "target" then
		updateAllInspectEquipmentSlots()
	end
end

-- Wait for Blizzard_InspectUI to load
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_InspectUI" then
		initializeInspectCache()
		eventFrame:RegisterEvent("INSPECT_READY")
		eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
		eventFrame:SetScript("OnEvent", onInspectEvent)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
