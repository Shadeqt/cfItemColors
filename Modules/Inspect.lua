local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.INSPECT].enabled then return end

-- Clears retry counters and borders for all inspect slots
local function clearAllInspectSlots()
	for i = 1, #addon.EQUIPMENT_SLOTS do
		local equipmentSlot = addon.EQUIPMENT_SLOTS[i]
		local inspectButton = _G["Inspect" .. equipmentSlot .. "Slot"]
		if inspectButton then
			inspectButton.cfRetryCount = nil
			addon.applyQualityColor(inspectButton, nil)
		end
	end
end

-- Updates a single inspect equipment slot
local function updateSingleInspectSlot(slotId)
	local equipmentSlot = addon.EQUIPMENT_SLOTS[slotId]
	local inspectButton = _G["Inspect" .. equipmentSlot .. "Slot"]

	addon.retryWithDelay(
		inspectButton,
		function()
			return GetInventoryItemLink(InspectFrame.unit, slotId)
		end,
		function(inventoryItemLink)
			addon.applyQualityColor(inspectButton, inventoryItemLink)
		end
	)
end

-- Updates all inspect equipment slots
local function updateAllInspectSlots()
	for i = 1, #addon.EQUIPMENT_SLOTS do
		updateSingleInspectSlot(i)
	end
end

-- Handles inspect ready event
local function onInspectEvent(_, event)
	if event == "INSPECT_READY" then
		updateAllInspectSlots()
	end
end

local eventFrame = CreateFrame("Frame")

-- Initialize inspect UI hooks
local function initInspectHooks()
	eventFrame:RegisterEvent("INSPECT_READY")
	eventFrame:SetScript("OnEvent", onInspectEvent)
	InspectFrame:HookScript("OnHide", clearAllInspectSlots)
end

-- Check if Blizzard_InspectUI is already loaded
if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
	initInspectHooks()
else
	eventFrame:RegisterEvent("ADDON_LOADED")
	eventFrame:SetScript("OnEvent", function(self, _, addonName)
		if addonName == "Blizzard_InspectUI" then
			self:UnregisterEvent("ADDON_LOADED")
			initInspectHooks()
		end
	end)
end
