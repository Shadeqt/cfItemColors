local addon = cfItemColors

-- Module enable check
if not cfItemColorsDB[addon.MODULES.INSPECT].enabled then return end

-- Clears borders for all inspect slots
local function clearAllInspectSlots()
	for i = 1, #addon.EQUIPMENT_SLOTS do
		local inspectButton = _G["Inspect" .. addon.EQUIPMENT_SLOTS[i] .. "Slot"]
		if inspectButton then
			addon.applyQualityColor(inspectButton, nil)
		end
	end
end

-- Updates a single inspect slot (applyQualityColor handles async item loading)
local function updateInspectSlot(slotId)
	if not InspectFrame or not InspectFrame:IsShown() then return end
	local unit = InspectFrame.unit
	local inspectButton = _G["Inspect" .. addon.EQUIPMENT_SLOTS[slotId] .. "Slot"]
	if not inspectButton then return end

	local itemLink = GetInventoryItemLink(unit, slotId)
	addon.applyQualityColor(inspectButton, itemLink or GetInventoryItemID(unit, slotId))
end

-- Updates all inspect equipment slots
local function updateAllInspectSlots()
	if not InspectFrame or not InspectFrame:IsShown() then return end
	for i = 1, #addon.EQUIPMENT_SLOTS do
		updateInspectSlot(i)
	end
end

local eventFrame = CreateFrame("Frame")

local function onEvent(_, event, ...)
	if event == "INSPECT_READY" then
		updateAllInspectSlots()
	elseif event == "UNIT_INVENTORY_CHANGED" then
		local unit = ...
		if InspectFrame and InspectFrame:IsShown() and InspectFrame.unit == unit then
			updateAllInspectSlots()
		end
	end
end

-- Initialize inspect UI hooks
local function initInspectHooks()
	eventFrame:RegisterEvent("INSPECT_READY")
	eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	eventFrame:SetScript("OnEvent", onEvent)
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
