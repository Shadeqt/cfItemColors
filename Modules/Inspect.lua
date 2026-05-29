local _, addon = ...

local function clearAllInspectSlots()
    for _, slot in ipairs(addon.EQUIPMENT_SLOTS) do
        local button = _G["Inspect" .. slot .. "Slot"]
        if button then addon.applyQualityColor(button, nil) end
    end
end

local function updateAllInspectSlots()
    if not InspectFrame or not InspectFrame:IsShown() then return end
    local unit = InspectFrame.unit
    for i, slot in ipairs(addon.EQUIPMENT_SLOTS) do
        local button = _G["Inspect" .. slot .. "Slot"]
        if button then
            local link = GetInventoryItemLink(unit, i)
            addon.applyQualityColor(button, link or GetInventoryItemID(unit, i))
        end
    end
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI", function()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("INSPECT_READY")
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "INSPECT_READY" or (event == "UNIT_INVENTORY_CHANGED" and InspectFrame.unit == unit) then
            updateAllInspectSlots()
        end
    end)

    InspectFrame:HookScript("OnShow", function()
        eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    end)
    InspectFrame:HookScript("OnHide", function()
        eventFrame:UnregisterEvent("UNIT_INVENTORY_CHANGED")
        clearAllInspectSlots()
    end)
end)
