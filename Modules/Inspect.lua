local addon = cfItemColors
local applyQualityColor = addon.applyQualityColor

-- Cache API calls
local _GetInventorySlotInfo = GetInventorySlotInfo
local _GetInventoryItemLink = GetInventoryItemLink
local _CreateFrame = CreateFrame
local _C_Timer = C_Timer
local _G = _G

local EQUIPMENT_SLOTS = addon.EQUIPMENT_SLOTS

-- Cache slot data
local inspectSlotCache = {}

-- Initialize cache
local function initializeCache()
	for slotId = 1, #EQUIPMENT_SLOTS do
		local slotName = EQUIPMENT_SLOTS[slotId]
		inspectSlotCache[slotId] = {
			button = _G["Inspect" .. slotName .. "Slot"],
			inventorySlotId = _GetInventorySlotInfo(slotName .. "Slot")
		}
	end
end

-- Update all inspect equipment slots
local function updateAllInspectSlots()
	for slotId = 1, #EQUIPMENT_SLOTS do
		local slotData = inspectSlotCache[slotId]
		if slotData and slotData.button then
			local itemLink = _GetInventoryItemLink("target", slotData.inventorySlotId)
			applyQualityColor(slotData.button, itemLink)
		end
	end
end

-- Handle inspect events
local function onInspectEvent(_, event)
	if event == "INSPECT_READY" then
		_C_Timer.After(0.1, updateAllInspectSlots)
	end
end

-- Wait for Blizzard_InspectUI to load
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, addonName)
	if addonName == "Blizzard_InspectUI" then
		initializeCache()
		eventFrame:RegisterEvent("INSPECT_READY")
		eventFrame:SetScript("OnEvent", onInspectEvent)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)